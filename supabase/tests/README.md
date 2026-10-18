# Schema smoke test

`schema_smoke_test.sql` walks the full product flow against a real Postgres
instance with RLS enforced as the `authenticated` role: sign-up trigger →
couple creation → invite redemption → both partners checking in → editing a
check-in → streak maintenance → cross-couple isolation. Then it runs the
negative cases: out-of-range scores, a duplicate daily check-in, invalid and
already-full invite codes, forged check-ins, two people who both created a
space pairing anyway, and a paired user trying to redeem someone else's code.

It relies on the Supabase-managed objects that the migrations assume but don't
create (`auth.users`, `auth.uid()`, the `authenticated` role and the
`supabase_realtime` publication), so I run it either against a local Supabase
stack or against a bare Postgres with stubs.

## Running it locally

With the Supabase CLI:

```bash
supabase start
supabase db reset                    # applies supabase/migrations
psql "$(supabase status -o env | grep '^DB_URL=' | cut -d= -f2- | tr -d '"')" \
     -f supabase/tests/schema_smoke_test.sql
```

The `tr -d '"'` matters: `supabase status -o env` prints the URL in quotes, and
psql treats a quoted string as a database name instead of a connection URL.

The test leaves its rows behind, so run `supabase db reset` again afterwards
if you want a clean database (for example before signing up in the app with
the same email addresses).

Against a bare Postgres, create the stubs first:

```sql
create schema auth;
create table auth.users (
    id uuid primary key default gen_random_uuid(),
    email text,
    raw_user_meta_data jsonb default '{}'::jsonb,
    created_at timestamptz default now()
);
create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
create role authenticated nologin;
create role anon nologin;
grant usage on schema auth to authenticated, anon;
create publication supabase_realtime;
```

Then apply the files in `supabase/migrations/` in filename order and run the
test. Every `NOTICE` in the negative section should read `REJECTED` or name the
expected error.
