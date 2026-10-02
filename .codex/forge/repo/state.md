COMPLETE

Student onboarding now has four steps: USN verification, student details, parent/guardian details, and account credentials. USN-provided name, department, and semester are read-only after verification. Parent name/contact/email are stored in the students table with a migration for existing databases. A separate root `server` now supports local/deployed SMTP reset emails; Flutter can target it through `MAIL_SERVER_URL` and `MAIL_SERVER_API_KEY`. `node --check server/src/index.js` and `git diff --check` were run; Flutter analysis previously timed out in the local environment.
