# aaroha mail server

This is a separate Node.js service for password-reset and student welcome emails. It keeps Firebase Admin credentials and SMTP credentials outside the Flutter application.

## Local setup

```text
cd server
npm install
copy .env.example .env
```

Fill `.env` with:

- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` copied from the downloaded service-account JSON. The server reconstructs the Firebase credential object from these values.
- Alternatively, use `FIREBASE_SERVICE_ACCOUNT_PATH` for a local JSON file or `FIREBASE_SERVICE_ACCOUNT_JSON` as one deployment secret.
- The SMTP host, username, and app password.
- A long random `SERVER_API_KEY`.
- The deployed Flutter Web URL.

Start it with:

```text
npm start
```

For local Flutter Web testing, keep the server on port `8082` and run Flutter on port `5000` so the reset link can return to the local app:

```text
flutter run -d chrome --web-port 5000 --dart-define=MAIL_SERVER_URL=http://127.0.0.1:8082 --dart-define=MAIL_SERVER_API_KEY=local-dev-key
```

Check it with `GET /health`. Protected mail endpoints require this header:

```text
x-api-key: your-server-api-key
```

Available endpoints:

- `POST /api/send-password-reset` with `{ "email": "student@example.com" }`
- `POST /api/send-student-welcome` with the student profile and credentials fields

Never commit `.env`, service-account JSON, SMTP passwords, or API keys. Configure those as environment variables on the deployment platform.
