# Running LearnTrack Locally

LearnTrack has two parts that must both be running: a Flask backend (port 8000)
and the Flutter app (web, desktop, or mobile).

## 1. Backend (Flask API)

```bash
cd backend/backend
python3 -m venv venv          # first time only
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt flask-cors
python init_db.py             # creates/migrates the local SQLite schema
python app.py
```

The server starts on `http://0.0.0.0:8000`. Check it with:

```bash
curl http://localhost:8000/healthcheck
```

No MySQL server is required for local/demo use — `database.py` tries MySQL
first and automatically falls back to a local SQLite file
(`backend/backend/learntrack.db`) if MySQL isn't reachable. That's the
expected path on a laptop with no MySQL installed.

A seeded test account is created on first `init_db.py` run:
`test@example.com` / `password`.

## 2. Frontend (Flutter)

```bash
flutter pub get
flutter run -d chrome     # or: flutter run -d macos
```

The app talks to `http://localhost:8000/api` (see `lib/services/*.dart`), so
the backend must already be running.

Optional: the "search for a topic" / learning-path-generation feature calls
the Gemini API and requires your own API key, entered via the in-app dialog
the first time you use it (Settings icon in the search bar → prompted
automatically). Not required for anything else in the app.

## What was broken and what I changed

This branch (`fix/demo-hardening`) fixes issues found by actually running the
app end-to-end (signup, login, session persistence, Pomodoro, streaks,
learning paths) rather than just reading the code.

### 1. Session restore logged in as the wrong user (real bug, high impact)

`GET /api/auth/validate` (`backend/backend/blueprints/auth.py`) never checked
the bearer token — it ran `SELECT * FROM users LIMIT 1` and returned whichever
user happened to be first in the table. In practice this meant: log in as
user B, reload the page (or relaunch the app), and you'd silently be signed in
as user A instead — wrong name, wrong data, no error. Reproduced live: signed
up as "Jane Demo," reloaded, and the dashboard greeted me as "Test User."

Fix:
- Added a `token` column to `users` (with an `ALTER TABLE` migration in
  `init_db.py` for existing local databases).
- `/auth/signup` and `/auth/login` now persist the issued token against the
  user row.
- `/auth/validate` now looks the user up **by token** instead of grabbing the
  first row.

### 2. Courses/paths/streak never actually reached the backend (real bug, high impact)

The Flutter app sends a custom `X-User-ID` header on every courses/paths/streak
request (`lib/services/learning_service.dart`). But `app.py` had **two**
competing CORS configurations: `flask_cors.CORS(app, allow_headers="*")`
(correct) and a manual `after_request` hook that unconditionally set
`Access-Control-Allow-Headers: Content-Type,Authorization` (wrong — no
`X-User-ID`, and it fights with flask_cors's own headers). The browser's CORS
preflight would then reject the follow-up request outright.

Symptom: opening dev tools showed `Failed to fetch` for every courses/paths
request, and completing a Pomodoro streak day *looked* like it worked (the UI
optimistically shows "Day completed!") but silently never made it to the
server — it only lived in the browser's local storage. Confirmed with the
network log: every `/courses`, `/paths`, `/streak` call showed an `OPTIONS`
preflight with no follow-up `GET`/`POST`, while `/auth/validate` and
`/users/<id>` (which don't send `X-User-ID`) worked fine.

Fix: removed the conflicting manual CORS headers in `app.py` and let
`flask_cors` (already configured correctly) own CORS entirely. Verified after
the fix: streak/courses/paths round-trip to the SQLite `user_data` table and
survive a full page reload.

### 3. Backend `venv` was committed to git with a hardcoded interpreter path

The committed `venv` pointed at
`/Users/chaitanyamatrubai/CodingProjects/flaskBackup/backend/venv/bin/python3`
— a path that only exists on the original author's machine. Anyone else
cloning the repo would get `bad interpreter: ... no such file or directory`
the moment they tried to run `pip` or `python` from it.

Fix: removed `venv/` from git tracking and added it (plus `__pycache__` and
the local `.db` file) to `.gitignore`. Each machine now creates its own venv
per the instructions above, which is how it should have worked originally.

### 4. `schema.sql` didn't match the code

`schema.sql` (presumably meant as MySQL setup documentation) declared a
`username` column and no `age`/`token` columns, while every query in the
codebase uses `name`, `age`, etc. Updated it to match what `init_db.py` and
the blueprints actually use, so it's no longer misleading if someone points a
real MySQL instance at it.

### Minor, not fixed

- The "Day completed! 🎉" celebration text shows a missing-glyph box instead
  of the emoji in the Chrome web build used for testing — a local font/rendering
  quirk, not a code issue. Left as-is.
- `flutter analyze` reports ~50 pre-existing style lints (deprecated
  `withOpacity`, missing `mounted` guards after `await`, etc.) unrelated to
  this branch's fixes. Not touched, to keep the diff focused.
- `lib/services/user_service.dart` (`UserService` class) hardcodes port 5000
  and appears unused anywhere in the app (grepped for `UserService(` — no
  callers). Left alone since it's dead code, not something the demo exercises.

## Verified working end-to-end

- Sign up → dashboard → reload → still the correct user (was broken, now fixed)
- Log in with existing account
- Pomodoro timer (Work/Short Break/Long Break, start/pause/reset, countdown)
- Streak "Complete Today" → persists across reload (was broken, now fixed)
- My Paths empty state
- Learning path generation prompts for a Gemini API key when none is set
  (expected — needs your own key, not a bug)
- Log out
