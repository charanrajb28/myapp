# Repository patterns

## State and UI

- Stateful Flutter screens own loading/error state locally and call `setState` after async operations.
- Riverpod `NotifierProvider.autoDispose` is used for student internship and notification state.
- Tab shells use `PageController`, `NavigationBar`, and explicit refresh hooks.
- Material 3 widgets, Figtree (`google_fonts`), and a dark navy/indigo/green visual language are common.

## Data access

- SQL uses positional `?` parameters through Turso; values are serialized by `_formatArg`.
- JSON/text fields are parsed opportunistically in `TursoDatabaseService._parseCell` and again in feature repositories when needed.
- Existing Supabase-shaped code is intentionally kept behind `supabase_compat.dart` to avoid rewriting screens.
- Most write operations use generated string IDs such as `app_<milliseconds>` and `doc_<milliseconds>`.

## Validation/error handling

- Screens show `SnackBar` or inline loading/error states and log details with `debugPrint`.
- Network failures are often caught and converted to a user-facing message; session monitor deliberately ignores transient network errors to avoid false logout.
- QR payloads use HMAC-SHA256, but debug builds explicitly bypass signature mismatch for testing.

## Refresh/notification behavior

- Student internships poll every 30 seconds.
- Student notifications poll every 4 seconds and also attempt a Supabase-compatible realtime subscription.
- FCM token registration occurs on auth-state login; push delivery requires a valid service-account credential and valid Firebase token.

## Mock/compatibility pattern

Many screens return realistic hard-coded “Dev Mode” data when no Firebase user exists. This keeps UI previewable but can mask missing backend data in local testing. There is also legacy naming/encoding compatibility (for example, multiple notification column names and text-encoded JSON arrays).
