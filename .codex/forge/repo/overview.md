# Aaroha repository overview

## Product purpose

Aaroha is a college internship/placement operations platform. It connects students, partner companies, and placement administrators around internship postings, applications, approval workflows, attendance/check-ins, documents, feedback, certificates, alerts, and notifications.

The app is a single Flutter codebase targeting Android, iOS, web, Windows, macOS, and Linux. The runtime selects a portal from the authenticated user's role (`student`, `company`, `admin`, or `sub_admin`).

## Primary user journeys

- Student signs up or signs in, views eligible `INTERVIEWING` internship postings, applies, tracks application/internship status, opens role details, scans company QR codes for separate check-in/check-out events, views attendance history and progress, manages profile/documents, submits feedback, and receives in-app/FCM notifications.
- Company signs in, manages its profile and internship postings, changes posting lifecycle (`UNDER_REVIEW`, `INTERVIEWING`, `ACTIVE`), reviews applicants, accepts/rejects/removes candidates, broadcasts alerts, generates QR payloads, and issues certificates.
- Admin/sub-admin reviews internship postings, manages students and companies, handles red alerts and feedback, reviews applications/role details, creates consent letters/certificates/forms, promotes semesters, manages sub-admins, exports data, and broadcasts student notifications. Some controls are role-gated for super admin.

## Runtime/data architecture

- Firebase Authentication is the identity provider.
- Turso/libSQL over HTTP is the main persistence layer. `TursoDatabaseService` sends SQL through the Turso `/v2/pipeline` endpoint.
- `supabase_compat.dart` is a compatibility/query-builder facade that translates existing Supabase-style calls into Turso SQL and Firebase-auth state. It is not a live Supabase client.
- Firebase Cloud Messaging is used for device tokens and push delivery; local notifications handle foreground display.
- Cloudinary is used for image uploads, and SMTP/mailer supports password-reset/test email flows.
- JSON/text columns store arrays and nested records, especially `applications.checkins`, internship lists/schema, notification metadata, and document references.

## Current confidence and caveats

Observed production paths coexist with mock/dev fallbacks for unauthenticated users. The README is still the default Flutter template and does not describe Aaroha. There are two SQL schema families (`schema.sql` PostgreSQL-style and `schema_sqlite.sql`/runtime DDL for Turso SQLite), so the runtime schema is the authoritative one for the deployed Flutter app.
