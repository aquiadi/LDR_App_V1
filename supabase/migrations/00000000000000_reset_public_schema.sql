-- Rebuild a project that is still on an OLD version of the schema.
--
-- Earlier versions of this app created the same tables with different
-- names, columns and policies: check_ins instead of daily_checkins,
-- partner_a_id / user_a_id instead of partner_1_id, couples without the
-- onboarding columns, users without couple_id or last_seen, a mood_emoji
-- column too short for the mood ids. The init migration uses
-- CREATE TABLE IF NOT EXISTS, so it cannot reshape those tables. It skips
-- them, and the app then fails on the first query that names a missing
-- column.
--
-- This runs before the init migration. It compares what is in `public`
-- with every column the current schema defines, and drops the app objects
-- ONLY if an app table exists without all of them (or an old-only table is
-- still around). On a fresh project, or one already on the current schema,
-- it does nothing. Dropping loses the old check-ins and couples; auth
-- accounts survive, and the 20261017000000 migration recreates their
-- profile rows.
--
-- It used to drop unconditionally, which meant `supabase db push` could
-- wipe a correctly migrated database (for example one whose schema had
-- been pasted into the SQL editor) the first time it ran.
--
-- Uses pg_attribute rather than information_schema, which only lists
-- columns the current role has privileges on.

do $$
declare
    old_shape boolean;
begin
    with expected(tbl, cols) as (
        values
        ('couples',              'id created_at invite_code partner_1_id partner_2_id is_active space_name anniversary_date welcome_message cover_photo_url'),
        ('users',                'id created_at updated_at email display_name avatar_url couple_id fcm_token timezone premium_tier last_seen'),
        ('daily_checkins',       'id created_at user_id couple_id mood_emoji mood_label affection_score stress_score energy_score journal_note shared_at'),
        ('streaks',              'id couple_id current_streak longest_streak last_checkin_date created_at updated_at'),
        ('ai_insights',          'id couple_id created_at start_date end_date summary relationship_trends connection_prompts'),
        ('subscriptions',        'id user_id stripe_customer_id stripe_subscription_id status price_id current_period_start current_period_end cancel_at_period_end created_at updated_at'),
        ('relationship_pings',   'id couple_id sender_id receiver_id created_at'),
        ('daily_prompt_answers', 'id couple_id user_id prompt_date prompt_text answer_text created_at updated_at'),
        ('countdown_events',     'id couple_id creator_id title description target_date created_at')
    ),
    wanted as (
        select to_regclass('public.' || tbl) as rel, unnest(string_to_array(cols, ' ')) as col
          from expected
    )
    select
        -- tables that only ever existed in the old schema
        to_regclass('public.check_ins') is not null
        or to_regclass('public.couple_streaks') is not null
        or to_regclass('public.user_streaks') is not null
        -- an app table that is missing a column the app needs
        or exists (
            select 1 from wanted w
             where w.rel is not null
               and not exists (
                   select 1 from pg_attribute a
                    where a.attrelid = w.rel
                      and a.attname = w.col
                      and a.attnum > 0
                      and not a.attisdropped
               )
        )
        -- mood ids like 'sentiment_very_satisfied' need varchar(40)
        or exists (
            select 1 from pg_attribute a
             where a.attrelid = to_regclass('public.daily_checkins')
               and a.attname = 'mood_emoji'
               and a.atttypmod between 0 and 43
        )
      into old_shape;

    if not old_shape then
        raise notice 'reset_public_schema: no old-shape tables found, nothing to do';
        return;
    end if;

    raise notice 'reset_public_schema: old schema detected, dropping app objects';

    drop trigger if exists on_auth_user_created on auth.users;

    drop table if exists
        public.daily_prompt_answers,
        public.relationship_pings,
        public.countdown_events,
        public.ai_insights,
        public.subscriptions,
        public.streaks,
        public.daily_checkins,
        public.check_ins,
        public.couple_streaks,
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
end $$;
