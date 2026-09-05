-- OPTIONAL, DESTRUCTIVE: drop every app object before re-applying the schema.
--
-- Run this ONLY when an earlier, partial version of the schema is already in
-- the project and you are willing to lose its data. The init migration uses
-- CREATE TABLE IF NOT EXISTS, so it will not reshape a table that already
-- exists with the wrong columns -- it either silently skips that table or
-- fails partway through, leaving a half-migrated database.
--
-- This deletes all check-ins, couples and profile rows. It does NOT touch
-- auth.users, so accounts survive; the handle_new_user trigger will not
-- re-run for them, so re-create their profile rows with the backfill at the
-- bottom, or simply delete the test users from the Auth dashboard.

begin;

drop trigger if exists on_auth_user_created on auth.users;

drop table if exists
    public.daily_prompt_answers,
    public.relationship_pings,
    public.countdown_events,
    public.ai_insights,
    public.subscriptions,
    public.streaks,
    public.daily_checkins,
    public.check_ins,          -- from an earlier naming of the same table
    public.couple_streaks,     -- ditto
    public.users,
    public.couples
cascade;

drop materialized view if exists public.user_streaks cascade;

drop function if exists public.is_couple_member(uuid)  cascade;
drop function if exists public.handle_new_user()       cascade;
drop function if exists public.handle_new_couple()     cascade;
drop function if exists public.update_couple_streak()  cascade;
drop function if exists public.refresh_user_streaks()  cascade;
drop function if exists public.join_couple(text)       cascade;

commit;

-- Now run 20240622000000_init_schema.sql.
--
-- Afterwards, if you kept existing auth accounts, backfill their profiles:
--
--   insert into public.users (id, email, display_name)
--   select u.id, u.email,
--          coalesce(u.raw_user_meta_data->>'display_name', split_part(u.email,'@',1))
--     from auth.users u
--    where not exists (select 1 from public.users p where p.id = u.id);
