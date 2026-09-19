# Architecture map

## Entry and authentication flow

`lib/main.dart` initializes Flutter, Firebase, Turso configuration, the runtime schema, and a default admin account. `MyApp` starts FCM and listens to Firebase auth changes. `AuthGate` reads `users.role` from Turso and replaces the login route with `AdminShell`, `CompanyShell`, or `StudentShell`.

Login and signup are implemented in `lib/main.dart`, `screens/auth/student_signup_screen.dart`, and `screens/auth/student_onboarding_screen.dart`. Firebase Auth creates/validates credentials; account/profile rows are then inserted into Turso. Device sessions are recorded in `user_device_sessions` and monitored by `utils/device_session_helper.dart`.

## Portal boundaries

### Student

`StudentShell` provides five tabs: dashboard, internships, QR check-in, notifications, and profile. Riverpod providers (`student_internships_provider.dart`, `student_notifications_provider.dart`) load and refresh data. `StudentPortalRepository` owns most student SQL and normalizes Turso JSON values.

Representative flow: `CheckinsScreen` validates a signed QR payload with `QrPayloadSecurity`, calls `StudentPortalRepository.recordApplicationCheckin`, which reads `applications.checkins`, updates today's JSON object (`check_in_at` then `check_out_at`), and writes the whole JSON array back to the application row. The student repository calculates progress as distinct check-in dates divided by inclusive internship start/end days.

### Company

`CompanyShell` provides dashboard, postings, and profile tabs. `CompanyDashboardScreen` aggregates company/application counts. `ManagePostingsScreen` lists and transitions posting status. `PostingDetailsScreen` loads a posting and applicants, performs candidate decisions, generates QR payloads, sends broadcast alerts, and issues certificates. Candidate screens provide applicant filtering and detailed actions.

### Admin

`AdminShell` provides overview, students, companies, alerts, and a “More” control center. The admin area includes posting review (`admin_internships_screen.dart` and `role_detail_screen.dart`), student/company management, feedback/form tools, reports, check-in overview, consent letters, certificates, semester promotion, exports, and sub-admin management.

## Persistence and integration seams

- Direct SQL: `TursoDatabaseService.query/querySingle/execute/batch`.
- Supabase-shaped access: `Supabase.instance.client.from(...).select/insert/update/delete`, translated by `supabase_compat.dart`.
- Auth: `AuthService` wraps FirebaseAuth and synchronizes `users`, `students`, and `companies` rows.
- Push: `FcmPushService` saves FCM tokens and calls the Firebase HTTP v1 API; `FCMService` configures permissions, topics, foreground/background handling, and local notifications.
- Media: `CloudinaryService` and file-picker/file-selector utilities.

## Representative request trace

Company posts a role -> `create_posting_screen.dart` inserts an `internships` row with `UNDER_REVIEW` -> admin review updates it to `INTERVIEWING` and creates `student_notifications` rows -> student provider polls/reloads notifications and displays them -> student applies, creating an `applications` row -> company changes application to `Accepted`/`Rejected`, and later posting activation promotes accepted applications to `Active` -> student scans the company QR, repository mutates application JSON check-ins, and dashboard progress is derived from those dates.
