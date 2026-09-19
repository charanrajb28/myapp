# Repository commands and verification

## Manifests and build

- `flutter pub get` — resolve Dart/Flutter dependencies.
- `flutter analyze` — static analysis; may be slow in this workspace.
- `flutter test` — runs the current tests. The existing widget test is a stale counter-template test and is expected to require replacement.
- `flutter build web --release` — web release build; `build.sh` installs Flutter stable, runs `pub get`, and builds web.
- `docker compose up` — starts the optional PostgreSQL 15 service using `schema.sql`; this is separate from the Turso runtime path.

## Useful inspection commands

- `rg --files lib test` — source/test inventory.
- `rg -n "Supabase|Turso|Firebase|FCM|INSERT INTO|UPDATE|SELECT" lib` — integration/data flow search.
- `rg -n "UNDER_REVIEW|INTERVIEWING|ACTIVE|Applied|Accepted|Rejected|Completed|Removed" lib schema_sqlite.sql schema.sql` — lifecycle audit.
- `git diff --check` — whitespace/error check after edits.

## Verification gaps

There are no meaningful repository-level tests for authentication routing, role transitions, QR security, check-in/check-out persistence, notifications, or FCM delivery. End-to-end verification currently requires a configured Firebase project, reachable Turso database, valid FCM credentials, and mobile hardware for live QR scanning.
