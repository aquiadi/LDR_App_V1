-- =====================================================================
-- LDR Emotional-Sync — consolidated initial schema
-- =====================================================================
-- This is the single source of truth for the database. It supersedes the
-- earlier, mutually contradictory migration files (which disagreed on
-- table names -- check_ins vs daily_checkins -- and on partner column
-- names -- user_a_id / partner_a_id / partner_1_id -- and never ran to
-- completion in any case).
--
-- Every table, column and policy below is reachable from the Flutter
-- client; nothing here is speculative.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1. couples — the pairing unit that scopes every other row
-- ---------------------------------------------------------------------
create table if not exists public.couples (
    id              uuid primary key default gen_random_uuid(),
    created_at      timestamptz not null default timezone('utc', now()),
    invite_code     varchar(8) not null unique,
    partner_1_id    uuid references auth.users(id) on delete set null,
    partner_2_id    uuid references auth.users(id) on delete set null,
    is_active       boolean not null default true,
    -- Collected during solo onboarding, before a partner has joined.
    space_name      varchar,
    anniversary_date date,
    welcome_message text,
    cover_photo_url varchar
);

-- ---------------------------------------------------------------------
-- 2. users — profile mirror of auth.users
-- ---------------------------------------------------------------------
create table if not exists public.users (
    id            uuid primary key references auth.users(id) on delete cascade,
    created_at    timestamptz not null default timezone('utc', now()),
    updated_at    timestamptz not null default timezone('utc', now()),
    email         varchar not null,
    display_name  varchar,
    avatar_url    varchar,
    couple_id     uuid references public.couples(id) on delete set null,
    fcm_token     varchar,
    timezone      varchar not null default 'UTC',
    premium_tier  boolean not null default false,
    -- Coarse presence fallback for when the realtime channel is not live.
    last_seen     timestamptz default timezone('utc', now())
);

-- ---------------------------------------------------------------------
-- 3. daily_checkins — the core ritual
-- ---------------------------------------------------------------------
create table if not exists public.daily_checkins (
    id              uuid primary key default gen_random_uuid(),
    created_at      timestamptz not null default timezone('utc', now()),
    user_id         uuid not null references public.users(id) on delete cascade,
    couple_id       uuid not null references public.couples(id) on delete cascade,
    mood_emoji      varchar(40) not null,
    mood_label      varchar(50) not null,
    affection_score integer not null check (affection_score between 1 and 10),
    stress_score    integer not null check (stress_score between 1 and 10),
    energy_score    integer not null check (energy_score between 1 and 10),
    journal_note    text,
    shared_at       timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------
-- 4. streaks — maintained by trigger, one row per couple
-- ---------------------------------------------------------------------
create table if not exists public.streaks (
    id                uuid primary key default gen_random_uuid(),
    couple_id         uuid not null unique references public.couples(id) on delete cascade,
    current_streak    integer not null default 0,
    longest_streak    integer not null default 0,
    last_checkin_date date,
    created_at        timestamptz not null default timezone('utc', now()),
    updated_at        timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------
-- 5. ai_insights — persisted output of the generate_insights function
-- ---------------------------------------------------------------------
create table if not exists public.ai_insights (
    id                  uuid primary key default gen_random_uuid(),
    couple_id           uuid not null references public.couples(id) on delete cascade,
    created_at          timestamptz not null default timezone('utc', now()),
    start_date          date not null,
    end_date            date not null,
    summary             text not null,
    relationship_trends text[] not null default '{}',
    connection_prompts  text[] not null default '{}'
);

-- ---------------------------------------------------------------------
-- 6. subscriptions — Stripe mirror (premium gating; not yet wired up)
-- ---------------------------------------------------------------------
create table if not exists public.subscriptions (
    id                     uuid primary key default gen_random_uuid(),
    user_id                uuid not null unique references public.users(id) on delete cascade,
    stripe_customer_id     varchar,
    stripe_subscription_id varchar,
    status                 varchar(50) not null,
    price_id               varchar,
    current_period_start   timestamptz,
    current_period_end     timestamptz,
    cancel_at_period_end   boolean not null default false,
    created_at             timestamptz not null default timezone('utc', now()),
    updated_at             timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------
-- 7. relationship_pings — the "thinking of you" nudge
-- ---------------------------------------------------------------------
create table if not exists public.relationship_pings (
    id          uuid primary key default gen_random_uuid(),
    couple_id   uuid not null references public.couples(id) on delete cascade,
    sender_id   uuid not null references public.users(id) on delete cascade,
    receiver_id uuid not null references public.users(id) on delete cascade,
    created_at  timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------
-- 8. daily_prompt_answers — answers to the rotating daily question
-- ---------------------------------------------------------------------
create table if not exists public.daily_prompt_answers (
    id          uuid primary key default gen_random_uuid(),
    couple_id   uuid not null references public.couples(id) on delete cascade,
    user_id     uuid not null references public.users(id) on delete cascade,
    prompt_date date not null default current_date,
    prompt_text text not null,
    answer_text text not null,
    created_at  timestamptz not null default timezone('utc', now()),
    updated_at  timestamptz not null default timezone('utc', now()),
    unique (user_id, prompt_date)
);

-- ---------------------------------------------------------------------
-- 9. countdown_events — shared milestones (next visit, anniversary…)
-- ---------------------------------------------------------------------
create table if not exists public.countdown_events (
    id          uuid primary key default gen_random_uuid(),
    couple_id   uuid not null references public.couples(id) on delete cascade,
    creator_id  uuid not null references public.users(id) on delete cascade,
    title       text not null,
    description text,
    target_date timestamptz not null,
    created_at  timestamptz not null default timezone('utc', now())
);

-- =====================================================================
-- Indexes
-- =====================================================================
create index if not exists idx_users_couple_id        on public.users (couple_id);
create index if not exists idx_couples_partners       on public.couples (partner_1_id, partner_2_id);
create index if not exists idx_checkins_couple_created on public.daily_checkins (couple_id, created_at desc);
create index if not exists idx_checkins_user_date     on public.daily_checkins (user_id, created_at desc);
create index if not exists idx_streaks_couple_id      on public.streaks (couple_id);
create index if not exists idx_insights_couple_created on public.ai_insights (couple_id, created_at desc);
create index if not exists idx_pings_couple_created   on public.relationship_pings (couple_id, created_at desc);
create index if not exists idx_pings_receiver         on public.relationship_pings (receiver_id, created_at desc);
create index if not exists idx_prompts_couple_date    on public.daily_prompt_answers (couple_id, prompt_date desc);
create index if not exists idx_countdowns_couple_target on public.countdown_events (couple_id, target_date asc);

-- One check-in per user per UTC calendar day. This is what makes the
-- client's "fetch today's check-in" query safe to treat as single-row.
create unique index if not exists idx_unique_daily_checkin
    on public.daily_checkins (user_id, (date(timezone('utc', created_at))));

-- =====================================================================
-- Row-Level Security
--
-- Note: every policy that needs to answer "are these two users paired?"
-- resolves it through public.couples, never through public.users. A
-- users-policy that selects from public.users recurses and Postgres
-- aborts the query with "infinite recursion detected in policy".
-- =====================================================================
alter table public.users                enable row level security;
alter table public.couples              enable row level security;
alter table public.daily_checkins       enable row level security;
alter table public.streaks              enable row level security;
alter table public.ai_insights          enable row level security;
alter table public.subscriptions        enable row level security;
alter table public.relationship_pings   enable row level security;
alter table public.daily_prompt_answers enable row level security;
alter table public.countdown_events     enable row level security;

-- Reusable membership test. STABLE + SECURITY DEFINER so it can read
-- couples without tripping that table's own policies.
create or replace function public.is_couple_member(target_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.couples c
        where c.id = target_couple_id
          and (c.partner_1_id = auth.uid() or c.partner_2_id = auth.uid())
    );
$$;

-- users -----------------------------------------------------------------
drop policy if exists users_select on public.users;
create policy users_select on public.users for select
    using (
        auth.uid() = id
        or (couple_id is not null and public.is_couple_member(couple_id))
    );

drop policy if exists users_update on public.users;
create policy users_update on public.users for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- couples ---------------------------------------------------------------
drop policy if exists couples_select on public.couples;
create policy couples_select on public.couples for select
    using (auth.uid() = partner_1_id or auth.uid() = partner_2_id);

-- The creator must put themselves in partner_1_id; joining is done via
-- the join_couple() RPC, which is SECURITY DEFINER.
drop policy if exists couples_insert on public.couples;
create policy couples_insert on public.couples for insert
    with check (auth.uid() = partner_1_id);

drop policy if exists couples_update on public.couples;
create policy couples_update on public.couples for update
    using (auth.uid() = partner_1_id or auth.uid() = partner_2_id)
    with check (auth.uid() = partner_1_id or auth.uid() = partner_2_id);

drop policy if exists couples_delete on public.couples;
create policy couples_delete on public.couples for delete
    using (auth.uid() = partner_1_id or auth.uid() = partner_2_id);

-- daily_checkins --------------------------------------------------------
drop policy if exists checkins_select on public.daily_checkins;
create policy checkins_select on public.daily_checkins for select
    using (public.is_couple_member(couple_id));

drop policy if exists checkins_insert on public.daily_checkins;
create policy checkins_insert on public.daily_checkins for insert
    with check (auth.uid() = user_id and public.is_couple_member(couple_id));

-- Required: the client edits an existing check-in rather than inserting a
-- second one for the same day. Without this, the update matches zero rows
-- and the follow-up .select().single() throws.
drop policy if exists checkins_update on public.daily_checkins;
create policy checkins_update on public.daily_checkins for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id and public.is_couple_member(couple_id));

-- streaks / ai_insights (read-only to clients; written by triggers) ------
drop policy if exists streaks_select on public.streaks;
create policy streaks_select on public.streaks for select
    using (public.is_couple_member(couple_id));

drop policy if exists insights_select on public.ai_insights;
create policy insights_select on public.ai_insights for select
    using (public.is_couple_member(couple_id));

-- subscriptions ---------------------------------------------------------
drop policy if exists subscriptions_select on public.subscriptions;
create policy subscriptions_select on public.subscriptions for select
    using (auth.uid() = user_id);

-- relationship_pings ----------------------------------------------------
drop policy if exists pings_select on public.relationship_pings;
create policy pings_select on public.relationship_pings for select
    using (public.is_couple_member(couple_id));

drop policy if exists pings_insert on public.relationship_pings;
create policy pings_insert on public.relationship_pings for insert
    with check (auth.uid() = sender_id and public.is_couple_member(couple_id));

-- daily_prompt_answers --------------------------------------------------
drop policy if exists prompts_select on public.daily_prompt_answers;
create policy prompts_select on public.daily_prompt_answers for select
    using (public.is_couple_member(couple_id));

drop policy if exists prompts_insert on public.daily_prompt_answers;
create policy prompts_insert on public.daily_prompt_answers for insert
    with check (auth.uid() = user_id and public.is_couple_member(couple_id));

drop policy if exists prompts_update on public.daily_prompt_answers;
create policy prompts_update on public.daily_prompt_answers for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- countdown_events ------------------------------------------------------
drop policy if exists countdowns_select on public.countdown_events;
create policy countdowns_select on public.countdown_events for select
    using (public.is_couple_member(couple_id));

drop policy if exists countdowns_insert on public.countdown_events;
create policy countdowns_insert on public.countdown_events for insert
    with check (auth.uid() = creator_id and public.is_couple_member(couple_id));

drop policy if exists countdowns_update on public.countdown_events;
create policy countdowns_update on public.countdown_events for update
    using (public.is_couple_member(couple_id))
    with check (public.is_couple_member(couple_id));

drop policy if exists countdowns_delete on public.countdown_events;
create policy countdowns_delete on public.countdown_events for delete
    using (public.is_couple_member(couple_id));

-- =====================================================================
-- Triggers & functions
-- =====================================================================

-- A. Mirror every new auth user into public.users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.users (id, email, display_name, avatar_url, timezone)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
        new.raw_user_meta_data->>'avatar_url',
        coalesce(new.raw_user_meta_data->>'timezone', 'UTC')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- B. Give every couple a streak row up front, so the streak trigger only
--    ever has to UPDATE.
create or replace function public.handle_new_couple()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.streaks (couple_id) values (new.id)
    on conflict (couple_id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_couple_created on public.couples;
create trigger on_couple_created
    after insert on public.couples
    for each row execute function public.handle_new_couple();

-- C. Maintain the couple streak on each new check-in.
create or replace function public.update_couple_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    today       date := (timezone('utc', now()))::date;
    previous    date;
begin
    select last_checkin_date into previous
      from public.streaks
     where couple_id = new.couple_id
     for update;

    if previous is null then
        update public.streaks
           set current_streak = 1,
               longest_streak = greatest(longest_streak, 1),
               last_checkin_date = today,
               updated_at = now()
         where couple_id = new.couple_id;
    elsif previous = today then
        -- Second partner checking in on the same day: no streak change.
        null;
    elsif previous = today - 1 then
        update public.streaks
           set current_streak = current_streak + 1,
               longest_streak = greatest(longest_streak, current_streak + 1),
               last_checkin_date = today,
               updated_at = now()
         where couple_id = new.couple_id;
    else
        update public.streaks
           set current_streak = 1,
               longest_streak = greatest(longest_streak, 1),
               last_checkin_date = today,
               updated_at = now()
         where couple_id = new.couple_id;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_update_streak on public.daily_checkins;
create trigger trg_update_streak
    after insert on public.daily_checkins
    for each row execute function public.update_couple_streak();

-- D. Redeem an invite code.
--    SECURITY DEFINER because the joiner is not yet a member of the
--    couple and so cannot see or update the row under RLS.
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

    update public.couples
       set partner_2_id = auth.uid()
     where id = found_couple.id
    returning * into found_couple;

    update public.users
       set couple_id = found_couple.id,
           updated_at = now()
     where id = auth.uid();

    return found_couple;
end;
$$;

grant execute on function public.join_couple(text) to authenticated;

-- =====================================================================
-- Realtime
--
-- supabase_flutter's .stream() reads from the supabase_realtime
-- publication; a table missing here produces a stream that silently
-- never emits. REPLICA IDENTITY FULL is what makes row-level filters
-- work on UPDATE and DELETE events.
-- =====================================================================
alter table public.couples              replica identity full;
alter table public.users                replica identity full;
alter table public.daily_checkins       replica identity full;
alter table public.relationship_pings   replica identity full;
alter table public.daily_prompt_answers replica identity full;
alter table public.countdown_events     replica identity full;

do $$
declare
    t text;
begin
    foreach t in array array[
        'couples', 'users', 'daily_checkins',
        'relationship_pings', 'daily_prompt_answers', 'countdown_events'
    ] loop
        if not exists (
            select 1 from pg_publication_tables
            where pubname = 'supabase_realtime'
              and schemaname = 'public'
              and tablename = t
        ) then
            execute format('alter publication supabase_realtime add table public.%I', t);
        end if;
    end loop;
end $$;
