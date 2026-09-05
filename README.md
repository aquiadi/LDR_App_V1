# LDR — Emotional Sync

A daily check-in ritual for couples in different time zones. One partner records
how their day actually went; the other sees it the moment it lands. The product
bet is that a small, consistent, low-effort signal sustains a relationship better
than an occasional long call.

Flutter client, Supabase backend (Postgres + Auth + Realtime + Edge Functions).

---

## What it does

| Surface | Behaviour |
| --- | --- |
| **Pairing** | One partner creates a shared space and gets an 8-character invite code; the other redeems it. A space works solo while it waits for the second partner. |
| **Daily check-in** | Mood, energy (1–10), and an optional note. One check-in per person per UTC day, editable until the day rolls over. |
| **Dashboard** | Partner's latest mood, presence, streak, next milestone, and a "thinking of you" nudge with a 60-second cooldown. |
| **Journey** | The couple's shared timeline, day by day, with a per-day sync score derived from how closely the pair's energy matched. |
| **Insights** | A weekly summary from an Edge Function, optionally routed through an LLM. |

---

## Architecture

Feature-first, with a deliberately thin layer cake. Each feature owns its
screens and its providers; anything shared lives in `core/` or `shared/`.

```
main.dart              Supabase init from --dart-define, ProviderScope
core/
  navigation/          GoRouter + the redirect that gates on auth/pairing state
  network/             Supabase client provider
  theme/               Colours, typography (fonts bundled, see below)
models/                Freezed + json_serializable domain models
services/              Supabase reads/writes; the only layer that knows SQL-ish detail
shared/                Mood catalog, reusable widgets
features/<name>/
  providers/           Riverpod (codegen); async + realtime state
  screens/             Widgets, minimal logic
supabase/
  migrations/          One consolidated schema migration
  functions/           Edge Functions (Deno)
  tests/               SQL smoke test exercising RLS end to end
```

**State** is Riverpod 2 with `@riverpod` codegen throughout. Providers compose
rather than fan out from a store: `currentUser` → `currentCouple` → `partner` →
`partnerCheckin`, each one invalidating downstream automatically.

**Routing** is a single `GoRouter` whose `redirect` is the app's real state
machine — unauthenticated to `/login`, authenticated but unpaired to `/invite`,
paired to `/dashboard`. Screens never make routing decisions themselves. The
router is built once and refreshed by a `Listenable`; the redirect deliberately
`read`s rather than `watch`es so it does not rebuild the router mid-navigation.

**Realtime** rides Supabase's Postgres change streams for the couple row, the
partner's profile, and check-ins, plus a Presence channel for the online dot,
with a `last_seen` column as the coarse fallback when the socket is not live.
Tables that back a `.stream()` must be in the `supabase_realtime` publication
and set to `REPLICA IDENTITY FULL`; the migration does both, and a table missing
from that publication produces a stream that silently never emits.

---

## Data model

Nine tables. `couples` is the tenancy boundary: almost every policy resolves
"can this user see this row?" to "are they `partner_1_id` or `partner_2_id` of
the owning couple?".

```
auth.users ──1:1──> users ──┐
                            ├──> daily_checkins ──> (trigger) streaks
                  couples ──┤
                            ├──> relationship_pings
                            ├──> daily_prompt_answers
                            ├──> countdown_events
                            └──> ai_insights
users ──1:1──> subscriptions
```

Three invariants are enforced in the database rather than in Dart, because the
client is not a trustworthy place to enforce them:

- **One check-in per person per UTC day** — a unique index on
  `(user_id, date(timezone('utc', created_at)))`.
- **Scores are 1–10** — `CHECK` constraints. The client clamps to the same
  bounds so a UI change can never silently start producing rejected writes.
- **Pairing is atomic** — `join_couple()` is `SECURITY DEFINER` and takes a row
  lock, because the joiner cannot see or update the couple row under RLS until
  the moment they become a member of it.

RLS membership checks go through a `SECURITY DEFINER` helper
(`is_couple_member`) that reads `couples`. A policy on `users` that resolves
pairing by selecting from `users` recurses, and Postgres aborts the query with
`infinite recursion detected in policy` — worth knowing before writing a
policy that looks obviously correct.

---

## Running it

**Prerequisites:** Flutter 3.44+ (the project was created on 3.44.0) and a
Supabase project.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Apply the schema — either `supabase db push`, or paste
`supabase/migrations/20240622000000_init_schema.sql` into the SQL editor.

Credentials are compile-time `--dart-define`s, not a bundled `.env`, so nothing
secret lands in the repo:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Launched without them, the app boots to a screen that says exactly which keys
are missing rather than crashing on a null client.

**Optional — AI insights.** Deploy the Edge Function and set an API key; without
one it returns a deterministic summary computed from check-in data, and the app
falls back to neutral values if the function is not deployed at all.

```bash
supabase functions deploy generate_insights
supabase secrets set OPENAI_API_KEY=<key>
```

### Verifying

```bash
flutter analyze          # clean
flutter test             # 21 tests
flutter build web --release --no-web-resources-cdn --dart-define=...
```

`supabase/tests/schema_smoke_test.sql` drives the whole product flow through
Postgres with RLS on, including the negative cases. See
`supabase/tests/README.md`.

---

## Notes on some decisions

**Fonts are bundled, not fetched.** `google_fonts` downloads font files at
runtime by default. On a cold start without network that means the UI paints
with no text at all — not a fallback face, nothing. Sora and Inter ship in
`assets/google_fonts/` and runtime fetching is disabled in `main()`. Costs
~1.5 MB; buys a deterministic first paint and one less third-party request.

**Mood ids are tokens, not emoji.** `daily_checkins.mood_emoji` stores
`self_improvement`, not 🧘. The icon set can then change without rewriting
history, and `moodIconFor()` falls back rather than throwing on an id written by
an older build. The name of the column is now a small lie; renaming it is a
migration nobody has needed badly enough yet.

**Streaks are computed twice, on purpose.** A trigger maintains
`streaks.current_streak` for server-side consumers; the client recomputes from
the check-ins it already has so the number updates instantly without a round
trip. `calculateStreak` is a pure function and is the most heavily tested code
in the repo.

**Timezones.** Streaks and the one-per-day rule use UTC calendar days, so a
couple spanning UTC-8 and UTC+5 shares one definition of "today" rather than two
that disagree. The display layer renders in local time. Date adjacency is
computed by constructing calendar dates rather than subtracting `DateTime`s —
across a daylight-saving boundary adjacent days are 23 or 25 hours apart and
`Duration.inDays` gives the wrong answer.

---

## Known gaps

Honest list of what is not done:

- **No Android or iOS platform directories.** Only `macos/` and `web/` are
  checked in, so a mobile build needs `flutter create --platforms=android,ios .`
  first. The app is designed for phones; this is the largest gap.
- **`subscriptions` and `ai_insights` are schema-only.** No Stripe integration,
  no premium gating, and the Edge Function does not persist its output to
  `ai_insights` yet — it computes and returns.
- **`daily_prompt_answers` is unused.** The daily prompt rotates client-side off
  the date and answers land in the check-in's journal note instead.
- **Settings toggles are in-memory.** Push and haptics reset on restart;
  `shared_preferences` is a dependency but is not wired up. There is no push
  delivery, so `users.fcm_token` is never populated.
- **No unpair or delete-account flow**, despite the schema supporting it.
- **History is capped** at the most recent 180 check-ins; no pagination.
- **Widget and integration tests are thin.** Coverage is on pure logic and model
  parsing; the screens themselves are only smoke-tested.
