# Constraints, risks, and unknowns

## Important constraints

- The Flutter app must work across mobile and web/desktop, but QR scanning is meaningful only where the mobile scanner plugin is available.
- Turso runtime DDL is executed at application startup, so schema changes must be backward-compatible and tolerate existing databases.
- Existing data contains both legacy and newer notification/check-in columns; removing columns without migration would break compatibility code.
- The FCM service-account credential is injected through `FCM_SERVICE_ACCOUNT_B64`/`FCM_SERVICE_ACCOUNT_JSON` or an asset and must not be committed.

## Risks observed in code

- `main.dart` contains a default Turso URL and a default auth token fallback. Shipping real credentials as source defaults is a security risk; production should require runtime secrets.
- `FCMService`/`FcmPushService` mix client application code with server-side service-account OAuth and direct FCM HTTP v1 calls. Credential expiry, clock skew, and token lifecycle can prevent pushes.
- Two schema definitions diverge: PostgreSQL-oriented `schema.sql` and SQLite/Turso runtime schema. Column names and relationships differ (`student_id` vs `user_id` in notifications, feedback shape, document shape).
- `applications.checkins` is a JSON blob rather than a normalized attendance relation, which complicates reporting, concurrency, deduplication, and partial failures.
- Student progress is derived from check-in dates in the student repository, while admin/company exports and alerts still read the legacy `applications.progress` column.
- Several screens have unauthenticated mock data and placeholder controls, which can be mistaken for real persistence.
- The default widget test is still the Flutter counter smoke test and does not exercise Aaroha flows.
- Debug QR verification bypasses signature mismatches, so debug behavior is not a faithful security test.
- Frequent notification polling (4 seconds) and internship polling (30 seconds) can create unnecessary database traffic.
- Source files contain widespread mojibake characters, indicating an encoding/normalization issue.

## Unknowns to resolve before major changes

- Which SQL schema is the canonical deployment source for production Turso and whether `schema.sql` is still used for a separate PostgreSQL environment.
- Whether every admin/company write path is intended to use Turso directly or only through the compatibility facade.
- Whether server-side push sending should remain in the client or move to a trusted backend/Cloud Function.
- Whether application uniqueness is enforced in the deployed Turso database; `schema_sqlite.sql` does not define a unique `(student_id, internship_id)` constraint.
- The intended semantics of posting `INTERVIEWING` versus application `Under Review`/`Accepted` and the authoritative transition owner (company or admin).
