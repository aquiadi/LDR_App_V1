-- =====================================================================
-- join_couple() fixes and a profile backfill
-- =====================================================================
-- Safe to run more than once.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. join_couple() — let someone who already made a space join instead
-- ---------------------------------------------------------------------
-- If both partners tapped "create a space", each owned a half-empty couple
-- and neither could redeem the other's code: the app hid the code field
-- once you had a space, and joining would have left your own space behind
-- as an orphan. Now a joiner's own space is removed as part of the join, as
-- long as it is still waiting for a partner and has never been used.
--
-- It also refuses to move someone out of a couple that is already complete;
-- previously a paired user could redeem a third person's code and silently
-- leave their partner.
--
-- 20240622000000_init_schema.sql carries the same definition, so a fresh
-- project and an upgraded one end up identical.
create or replace function public.join_couple(invite_code_input text)
returns public.couples
language plpgsql
security definer
set search_path = public
as $$
declare
    found_couple public.couples;
begin
    if auth.uid() is null then
        raise exception 'Not authenticated';
    end if;

    select * into found_couple
      from public.couples
     where upper(invite_code) = upper(invite_code_input)
     for update;

    if found_couple.id is null then
        raise exception 'Invalid invite code';
    end if;

    if found_couple.partner_1_id = auth.uid()
       or found_couple.partner_2_id = auth.uid() then
        raise exception 'You are already in this couple.';
    end if;

    if found_couple.partner_2_id is not null then
        raise exception 'This couple is already full.';
    end if;

    if exists (
        select 1 from public.couples c
         where (c.partner_1_id = auth.uid() or c.partner_2_id = auth.uid())
           and c.partner_1_id is not null
           and c.partner_2_id is not null
    ) then
        raise exception 'You are already paired.';
    end if;

    update public.couples
       set partner_2_id = auth.uid()
     where id = found_couple.id
    returning * into found_couple;

    update public.users
       set couple_id = found_couple.id,
           updated_at = now()
     where id = auth.uid();

    -- Only the caller's own space that is waiting for a partner and was
    -- never used. A couple whose partner's account was deleted also has
    -- partner_2_id = null but still holds the pair's history; that one is
    -- left alone.
    delete from public.couples c
     where c.partner_1_id = auth.uid()
       and c.partner_2_id is null
       and c.id <> found_couple.id
       and not exists (select 1 from public.daily_checkins       x where x.couple_id = c.id)
       and not exists (select 1 from public.relationship_pings   x where x.couple_id = c.id)
       and not exists (select 1 from public.daily_prompt_answers x where x.couple_id = c.id)
       and not exists (select 1 from public.countdown_events     x where x.couple_id = c.id)
       and not exists (select 1 from public.ai_insights          x where x.couple_id = c.id);

    return found_couple;
end;
$$;

grant execute on function public.join_couple(text) to authenticated;

-- ---------------------------------------------------------------------
-- 2. Backfill missing profile rows
-- ---------------------------------------------------------------------
-- public.users is filled by the on_auth_user_created trigger, which only
-- fires for new sign-ups. Accounts that existed before the schema was
-- (re)built have no profile row, and the app cannot create one itself
-- (there is no insert policy on users), so those users could sign in but
-- never create or join a space.
insert into public.users (id, email, display_name)
select u.id,
       u.email,
       coalesce(u.raw_user_meta_data->>'display_name', split_part(u.email, '@', 1))
  from auth.users u
 where u.email is not null
on conflict (id) do nothing;
