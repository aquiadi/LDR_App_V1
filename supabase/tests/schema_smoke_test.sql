\set ON_ERROR_STOP on
-- Supabase grants these automatically via default privileges; replicate here.
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

\echo '=== 1. Sign up two users (handle_new_user trigger should mirror them) ==='
insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'ada@example.com',  '{"display_name":"Ada"}'),
  ('22222222-2222-2222-2222-222222222222', 'grace@example.com','{"display_name":"Grace"}');
select id, email, display_name, timezone, premium_tier from public.users order by email;

\echo '=== 2. Ada creates a couple (RLS enforced as authenticated) ==='
set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
insert into public.couples (invite_code, partner_1_id, space_name)
  values ('ABCD1234', auth.uid(), 'Our Corner');
update public.users set couple_id = (select id from public.couples where invite_code='ABCD1234')
  where id = auth.uid();
select invite_code, space_name, is_active, partner_2_id is null as awaiting_partner
  from public.couples;
\echo '-- streak row auto-created by on_couple_created:'
reset role; select current_streak, longest_streak, last_checkin_date from public.streaks;

\echo '=== 3. Grace redeems the invite code via join_couple() ==='
set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select (public.join_couple('abcd1234')).invite_code as joined_lowercase_ok;
select display_name, couple_id is not null as paired from public.users order by display_name;

\echo '=== 4. Both partners check in ==='
insert into public.daily_checkins (user_id, couple_id, mood_emoji, mood_label, affection_score, stress_score, energy_score, journal_note)
  values (auth.uid(), (select couple_id from public.users where id=auth.uid()), 'self_improvement','Calm',7,3,8,'Long day, thinking of you.');
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
insert into public.daily_checkins (user_id, couple_id, mood_emoji, mood_label, affection_score, stress_score, energy_score)
  values (auth.uid(), (select couple_id from public.users where id=auth.uid()), 'favorite','Loved',9,2,6);

\echo '-- Ada sees BOTH check-ins (partner sync works):'
select mood_label, energy_score, journal_note from public.daily_checkins order by mood_label;
\echo '-- streak after both partners check in on the same day (should be 1, not 2):'
reset role; select current_streak, longest_streak from public.streaks;

\echo '=== 5. Ada edits her existing check-in (needs checkins_update policy) ==='
set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
update public.daily_checkins set energy_score = 10, mood_label='Electric'
  where user_id = auth.uid() returning mood_label, energy_score;

\echo '=== 6. Ada can read Grace profile, but a stranger cannot read either ==='
select display_name from public.users order by display_name;
reset role;
insert into auth.users (id,email,raw_user_meta_data) values ('33333333-3333-3333-3333-333333333333','eve@example.com','{"display_name":"Eve"}');
set role authenticated;
set request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
\echo '-- Eve (unpaired outsider) sees only herself, and zero check-ins:'
select display_name from public.users;
select count(*) as checkins_visible_to_eve from public.daily_checkins;
select count(*) as couples_visible_to_eve from public.couples;
reset role;
set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
\echo '=== A. energy_score = 0 (what the UI slider can currently send) ==='
do $$ begin
  insert into public.daily_checkins (user_id, couple_id, mood_emoji, mood_label, affection_score, stress_score, energy_score)
  values (auth.uid(), (select couple_id from public.users where id=auth.uid()), 'cloud','Gloomy',5,5,0);
  raise notice 'ACCEPTED (unexpected)';
exception when check_violation then raise notice 'REJECTED by CHECK constraint -> slider min must be 1';
end $$;

\echo '=== B. second check-in for the same user on the same day ==='
do $$ begin
  insert into public.daily_checkins (user_id, couple_id, mood_emoji, mood_label, affection_score, stress_score, energy_score)
  values (auth.uid(), (select couple_id from public.users where id=auth.uid()), 'cloud','Gloomy',5,5,5);
  raise notice 'ACCEPTED (unexpected)';
exception when unique_violation then raise notice 'REJECTED by idx_unique_daily_checkin -> one per UTC day enforced';
end $$;

\echo '=== C. join_couple() error paths ==='
do $$ begin perform public.join_couple('NOPE9999');
exception when others then raise notice 'bad code    -> %', SQLERRM; end $$;
do $$ begin perform public.join_couple('ABCD1234');
exception when others then raise notice 'already in  -> %', SQLERRM; end $$;
set request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
do $$ begin perform public.join_couple('ABCD1234');
exception when others then raise notice 'couple full -> %', SQLERRM; end $$;

\echo '=== D. Eve cannot forge a check-in into someone else couple ==='
do $$ begin
  insert into public.daily_checkins (user_id, couple_id, mood_emoji, mood_label, affection_score, stress_score, energy_score)
  values (auth.uid(), (select id from public.couples limit 1), 'favorite','Loved',5,5,5);
  raise notice 'ACCEPTED (unexpected)';
exception when others then raise notice 'REJECTED -> %', SQLERRM; end $$;
reset role;

\echo '=== E. Both partners created a space: joining removes the joiner''s own empty space ==='
insert into auth.users (id,email,raw_user_meta_data) values
  ('44444444-4444-4444-4444-444444444444','frank@example.com','{"display_name":"Frank"}');
set role authenticated;
set request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
insert into public.couples (invite_code, partner_1_id) values ('EVE00001', auth.uid());
update public.users set couple_id = (select id from public.couples where invite_code='EVE00001') where id = auth.uid();
set request.jwt.claim.sub = '44444444-4444-4444-4444-444444444444';
insert into public.couples (invite_code, partner_1_id) values ('FRNK0001', auth.uid());
update public.users set couple_id = (select id from public.couples where invite_code='FRNK0001') where id = auth.uid();
select (public.join_couple('EVE00001')).invite_code as frank_joined;
reset role;
select count(*) as franks_empty_space_left from public.couples where invite_code = 'FRNK0001';
select u.display_name, c.invite_code from public.users u join public.couples c on c.id = u.couple_id
 where u.display_name in ('Eve','Frank') order by u.display_name;

\echo '=== F. A paired user cannot leave their partner by redeeming another code ==='
insert into auth.users (id,email,raw_user_meta_data) values
  ('55555555-5555-5555-5555-555555555555','gus@example.com','{"display_name":"Gus"}');
set role authenticated;
set request.jwt.claim.sub = '55555555-5555-5555-5555-555555555555';
insert into public.couples (invite_code, partner_1_id) values ('GUS00001', auth.uid());
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
do $$ begin perform public.join_couple('GUS00001');
  raise notice 'ACCEPTED (unexpected)';
exception when others then raise notice 'REJECTED -> %', SQLERRM; end $$;
reset role;
