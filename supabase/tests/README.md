# Schema smoke test

`schema_smoke_test.sql` walks the full product flow against a real Postgres
instance with RLS enforced as the `authenticated` role: sign-up trigger →
couple creation → invite redemption → both partners checking in → editing a
check-in → streak maintenance → cross-couple isolation, followed by the
negative cases (out-of-range scores, duplicate daily check-in, invalid /
already-full invite codes, forged check-ins).

It needs the Supabase-managed objects that the migration assumes but does not
create (`auth.users`, `auth.uid()`, the `authenticated` role, and the
`supabase_realtime` publication).

## Running it locally

With the Supabase CLI:

```bash
supabase start
supabase db reset                    # applies supabase/migrations
psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" \
     -f supabase/tests/schema_smoke_test.sql
```

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
create publication supabase_realtime;
```

then apply `supabase/migrations/20240622000000_init_schema.sql` and run the test.
Every `NOTICE` in the negative section should read `REJECTED`.
