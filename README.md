# LearnTrack — Project Overview & Interview Notes

## 1. Elevator Pitch

LearnTrack is a cross-platform learning-tracker app (Flutter frontend + Flask REST API backend)
that helps a user pick a topic, get an AI-generated structured learning path for it (modules →
lessons → curated resources), track their progress lesson-by-lesson, keep a daily study streak,
and run focused study sessions with a built-in Pomodoro timer. The core idea: instead of a static
"course tracker," the app *generates the curriculum itself* using the Gemini API, then treats that
generated curriculum as trackable state (progress bars, streaks, completion gates).

It's deployed and live: frontend on Firebase Hosting, backend on Render — both on free tiers.

## 2. Tech Stack

**Frontend**
- Flutter (Dart, SDK ^3.5.4), Material 3
- State management: `provider` (ChangeNotifier + MultiProvider + ProxyProvider)
- `google_generative_ai` — direct client-side integration with Google's Gemini API
- `http` for REST calls to the Flask backend
- `shared_preferences` for local/offline persistence and user settings (theme mode, Gemini key)
- `google_fonts`, `flutter_svg` for UI polish
- A small custom theme system (`ThemeExtension` + `ThemeProvider`) for light/dark/system mode

**Backend**
- Python Flask, organized with Blueprints (`auth`, `users`, `learning`)
- `flask-cors` for cross-origin requests (needed since the Flutter web build runs on a
  different origin/port than the API)
- `gunicorn` as the production WSGI server (Flask's own dev server is explicitly not meant
  for production and prints a warning to that effect)
- Persistence: MySQL via `PyMySQL`, with an automatic fallback to a local SQLite file
  (`learntrack.db`) if a MySQL server isn't reachable — implemented as a drop-in connection
  wrapper (`SQLiteConnection`/`SQLiteCursor`) that mimics the PyMySQL cursor API so the rest of
  the codebase doesn't need to know which database it's talking to.

**Hosting / infra**
- **Render** (free tier) — hosts the Flask API via `gunicorn`, reading the `$PORT` it assigns
  dynamically. Free tier spins the service down after 15 minutes idle (cold start ~30–50s on
  the next request).
- **Firebase Hosting** (free tier) — serves the compiled Flutter web build (`flutter build web`)
  as a static site, with the backend URL baked in at build time via `--dart-define`.
- **GitHub** — source control; Render redeploys automatically on push to `main`.

**Platforms**: iOS, Android, web, macOS, Windows, Linux (standard Flutter multi-platform targets).

## 3. Architecture

```
Flutter App
 ├─ providers/          ChangeNotifier state (AuthProvider, LearningProvider, ThemeProvider)
 ├─ services/           HTTP + local-storage + Gemini API integration
 ├─ screens/             UI (auth, dashboard, learning paths, pomodoro, settings)
 ├─ widgets/             Reusable components (cards, buttons, streak UI, search bar)
 ├─ theme/               Semantic color system + light/dark ThemeData
 └─ config.dart          Build-time API base URL (--dart-define override for deployment)

Flask API (backend/backend)
 ├─ app.py               App factory, CORS, request/response logging, /healthcheck, DB init
 ├─ config.py            DB + secret config
 ├─ database.py          get_connection() → MySQL, falls back to SQLite
 ├─ blueprints/auth.py   /api/auth/signup, /login, /signin, /validate
 ├─ blueprints/users.py  /api/users/<id>
 ├─ blueprints/learning.py  /api/users/<id>/courses, /paths, /streak
 └─ Procfile             `gunicorn app:app --bind 0.0.0.0:$PORT` (Render's entrypoint)

Data: SQLite (learntrack.db) or MySQL — `users` table + a generic `user_data
(user_id, data_type, data JSON)` table that stores courses/paths/streak per user
```

**Auth flow**: signup/login hashes the password (SHA-256) server-side, checks it against the
stored hash, and generates a token (`sha256(email + password_hash + name + user_id)`) that's
**persisted against that specific user row** and returned to the client. The client stores it in
`SharedPreferences` and sends it as a `Bearer` token on subsequent requests. `/auth/validate`
looks the token up against the `users` table to restore the session on app restart — it checks
the actual token, not just "is any user logged in" (see Section 7 for why this mattered).
`AuthProvider` wraps this in a `ChangeNotifier` so the whole widget tree reactively rebuilds
between the login screen and the dashboard.

**Learning data flow**: `LearningProvider` is wired to `AuthProvider` via a `ChangeNotifierProxyProvider`
so that logging in/out automatically triggers loading/clearing of learning data — no manual
wiring needed in each screen. `LearningService` follows a **network-first, local-cache-fallback**
pattern for every read: try the API → on failure, read the last-known value from
`SharedPreferences` → on total failure, degrade gracefully to safe mock/empty data so the UI
never crashes or shows a blank error state.

**Theme system**: `AppColorsExt` is a Flutter `ThemeExtension` holding every semantic color the
UI needs (background, surface, text tiers, accent, success, error, etc.), defined once for light
and once for dark. `AppTheme` builds a `ThemeData` per mode from it. `ThemeProvider` holds the
user's chosen `ThemeMode` (light/dark/system), persisted via `SharedPreferences`, and
`MaterialApp` reads it directly — so switching themes in Settings updates every screen at once,
because every widget reads colors from `Theme.of(context)` instead of hardcoding hex values.

## 4. Key Features

- **Email/password auth** with token-based sessions persisted locally, correctly scoped per user.
- **AI-generated learning paths**: user enters a topic, the app calls Gemini
  (`gemini-flash-latest`) with a structured prompt that requests real modules, lessons, and
  resource links (articles/videos/courses/books/tools) in strict JSON, which is parsed and
  turned into trackable state.
- **Ambiguity disambiguation**: before generating, a lightweight Gemini call checks whether the
  topic could mean two unrelated things (e.g. "derivatives" — calculus vs. finance). If so, the
  user is shown a dialog to pick the intended meaning before the real (slower) generation call
  runs, instead of silently guessing.
- **Progress tracking**: completing a lesson checks that prior lessons in the module are done
  (sequential gating), rolls up into module completion, and rolls up into path/course progress.
- **Path history & deletion**: Settings shows every path ever generated (title, date, hours,
  modules, progress), and any path can be deleted (with confirmation) from either My Paths or
  Settings.
- **Daily streaks**: a weekly streak view (current streak, longest streak, days completed)
  persisted both server-side and locally.
- **Pomodoro timer**: Work/Short Break/Long Break modes with a running countdown, for in-app
  focus sessions tied to the study workflow.
- **Light / Dark / System theme**, persisted per device.

## 5. Design Decisions (and why)

- **Provider over Bloc/Riverpod** — the state graph here is small (auth + one learning
  domain + theme), so a lighter `ChangeNotifier`-based approach kept the code readable without
  the boilerplate of a stricter state-management framework. `ChangeNotifierProxyProvider` was the
  key piece: it let auth state and learning state stay decoupled while still reacting to each
  other.
- **Local-first reads with server sync** — every learning-data read tries the network first
  but always has a `SharedPreferences` fallback, and every write saves locally before it
  attempts to hit the server. The app should never show a blank/broken screen just because the
  Flask server isn't reachable (e.g., dev environment, flaky connection, Render cold start) —
  it degrades to cached or mock data instead of failing outright.
- **MySQL with automatic SQLite fallback** — rather than forcing every contributor (or the free
  hosting tier) to stand up a MySQL instance, `get_connection()` tries MySQL and transparently
  falls back to a local SQLite file with the same cursor interface. This keeps local setup to
  "clone and run" with zero external services required, while still supporting a real MySQL
  deployment target.
- **Flask Blueprints + a versionless `/api` prefix** — auth, user, and learning routes are
  isolated into their own blueprints and mounted under a shared `/api` blueprint, so new resource
  types can be added without touching existing routes.
- **Client-side Gemini integration instead of proxying through the backend** — the API key is
  stored locally and the Flutter app talks to Gemini directly. This kept the backend focused
  purely on auth/user data and avoided adding an extra network hop and server-side dependency
  for a feature that's inherently a "generate content for this one user" operation. (See
  Section 7 for the tradeoff this introduces.)
- **A `ThemeExtension` instead of scattering `if (isDark)` checks** — every widget asks
  `Theme.of(context)` for its colors rather than branching on brightness itself. Adding dark mode
  to an app that wasn't built with it in mind is usually the painful part; centralizing color
  semantics up front made it a mechanical, low-risk change across ~15 files instead of a
  redesign.
- **Migrated off Firebase to a self-built Flask + SQL backend** — the git history shows an
  earlier Firebase/Firestore integration that was later removed in favor of a custom Flask API.
  This was a conscious move to fully own the backend logic and data model instead of being
  constrained by Firestore's document structure, and to be able to talk about a real REST API /
  SQL schema in interviews rather than "I called Firebase SDK methods."

## 6. How AI Was Used to Build This

AI was used in two distinct ways on this project — as a **product feature** and as a
**development tool**. Being specific about the difference (and about my own role in the second
one) is the important part for an interview.

### As a product feature
Gemini (`google_generative_ai`) is a first-class part of the app, not a gimmick — it's the engine
that turns a raw topic string into a structured curriculum (modules → lessons → resources) that
the rest of the app treats as real, trackable data. The prompt was engineered iteratively to
force strict JSON output, request real (non-placeholder) resource URLs, attach resources at the
lesson level rather than the path level, and — later — to run a cheap pre-check for topic
ambiguity before committing to a full generation call.

### As a development tool
I used an AI coding assistant (Claude Code) the way I'd use a very fast, very literal pair
programmer: I decided what to prioritize and what "done" looked like, tested the running app
myself at every step, and made every infrastructure/product decision. Concretely, my role in each
session was:

- **Directing priorities**: I gave specific, symptom-level bug reports ("I typed geometry, it
  prompts for an API key, then it fails silently and produces nothing," "the progress bar isn't
  full even at 100%," "make the first screen look better") rather than diagnoses — the assistant
  had to reproduce and root-cause each one before touching code.
- **Making the calls that matter**: which free hosting providers to use (Render + Firebase),
  what to name the Firebase project, when to actually push to `main` and redeploy, and which
  Gemini API key/project to use. Nothing shipped or deployed without me explicitly confirming it
  first.
- **Verifying, not just accepting**: every fix was tested against the actual running app —
  logging in, generating a path, reloading the page, checking the network tab — before I
  considered it done. When a "fix" (icon tree-shaking, a caching issue) didn't actually resolve
  what I saw on screen, I said so and we kept digging instead of accepting the first explanation.
- **Reviewing before merging**: changes went in as scoped git commits with descriptive messages
  explaining *why*, not just *what* — I could look at the diff for any single fix (e.g. the CORS
  header fix, or the auth-token fix) and see exactly what changed and why, rather than one giant
  unreviewable commit.

I can point to concrete examples where this collaboration caught real bugs *by testing*, not by
reading code — see Section 7. That's the honest framing: the assistant did a lot of the typing,
log-reading, and first-draft code, but the debugging loop (reproduce → hypothesize → verify
against the real app → accept or reject) was mine to drive, every time.

*(Interview framing: "I treat the AI assistant as a fast implementer, not a source of truth. I
tell it what's broken from the user's perspective, it goes and finds the actual cause, and I
don't consider anything fixed until I've seen it work in the browser myself.")*

## 7. Bugs Found and Fixed (good debugging talking points)

These were all found by actually **running the app** — signing up, reloading, generating paths,
checking the network tab — not just by reading the code, which is itself worth mentioning in an
interview ("static review didn't catch these; exercising the real user flow did").

- **Wrong-user session restore.** `/auth/validate` didn't check the bearer token at all — it ran
  `SELECT * FROM users LIMIT 1` and returned whichever user happened to be first in the table.
  Reproduced live: signed up as one user, reloaded the page, and the dashboard greeted me as a
  *different* user. Fixed by persisting a real token per user row and validating against it.
- **CORS silently blocking real requests.** The app sends a custom `X-User-ID` header on every
  courses/paths/streak request, but the backend had two competing CORS configurations — one
  correct (`flask_cors`), one that hardcoded `Access-Control-Allow-Headers` without `X-User-ID`.
  The browser's preflight check would then reject the real request outright. Symptom: the UI
  *looked* like it worked (optimistic "Day completed!" message) but nothing ever reached the
  server — confirmed via the network tab, where every affected endpoint showed a preflight with
  no follow-up request. Fixed by removing the conflicting manual headers.
- **Deprecated AI model.** The learning-path generator was pinned to `gemini-1.5-pro`, which
  Google has since fully removed from the API — every single generation request failed. Found by
  calling the Gemini API directly with `curl` and reading the actual error, not by guessing.
  Switched to `gemini-flash-latest`, Google's alias for the current default model, specifically
  to be more resilient to future model deprecations.
- **Silent error swallowing.** The search bar only ever showed an error message for the "API key
  missing" case; any other failure (bad key, deprecated model, network) was caught and thrown
  away with zero UI feedback — which is exactly why the deprecated-model bug above looked like
  "nothing happens" instead of a clear error.
- **Duplicate-generation race condition.** Searching an ambiguous topic (e.g. "derivatives")
  could produce *two* saved paths with different interpretations, because the search bar had no
  guard against firing a second generation request while one was already in flight. Fixed with a
  re-entrancy guard, and — since the underlying ambiguity was a real product gap, not just a race
  — added the disambiguation-dialog feature described in Section 4.
- **Progress bar never reaching 100%.** The fill width was computed as a fraction of the *screen*
  width rather than the bar's own container width, so it always undershot. Fixed using
  `FractionallySizedBox`, which sizes relative to its actual parent instead of guessing from
  `MediaQuery`.
- **Icons vanishing in the production web build.** Two icons on the redesigned landing screen
  rendered fine in debug but were blank in the deployed release build. Root cause: Flutter's
  release build tree-shakes the icon font down to only the glyphs it can statically detect are
  used, and missed these two. Fixed by building with `--no-tree-shake-icons` — verified by
  comparing file checksums between a clean local server and the live deployment before
  concluding it was actually fixed (an earlier "fix" attempt looked like it failed, but that was
  a stale browser cache in the testing tool, not the app — worth being precise about which one
  it actually was rather than guessing).
- **A committed `venv/` with a hardcoded path from a different machine.** The backend's Python
  virtual environment was checked into git, pointing at
  `/Users/<someone-else>/.../venv/bin/python3` — the exact reason the backend failed to run at
  all on a fresh checkout. Untracked it, added it to `.gitignore`, documented a clean setup.

## 8. Known Limitations / What I'd Improve Next

Being upfront about these in an interview reads as self-awareness, not a weakness.

- **Password hashing is unsalted SHA-256**, not `bcrypt`/`argon2` — fine for a class/portfolio
  project, but a real product would need salted, slow hashing and a real JWT (with expiry)
  instead of a static derived token.
- **Client-side Gemini API key** means the key lives on-device and every user needs their own
  key — a production version would proxy Gemini calls through the backend so the key stays
  server-side and usage can be rate-limited/metered per user.
- **Hardcoded secrets in `config.py`** (`SECRET_KEY`, DB password) — would move to environment
  variables / `.env` + `python-dotenv` before shipping.
- **SQLite on Render's free tier is ephemeral** — the filesystem resets on redeploy/spin-down, so
  demo data doesn't persist long-term. A production deployment would use a managed
  Postgres/MySQL instance instead.
- **No automated tests** — everything so far has been verified by manually exercising the app
  (which is how all the bugs in Section 7 were actually found). Given more time, the next
  investment would be integration tests for the auth/token flow and the courses/paths/streak
  endpoints specifically, since those are exactly where the real bugs lived.

## 9. Deployment

- **Backend**: https://learn-track.onrender.com — Render web service running
  `gunicorn app:app --bind 0.0.0.0:$PORT`. Auto-deploys on push to `main`. Free tier spins down
  after 15 minutes idle (cold start ~30–50s on the next request).
- **Frontend**: https://learntrack-visu22.web.app — Firebase Hosting serving
  `flutter build web --dart-define=API_BASE_URL=https://learn-track.onrender.com/api`.
  Redeploy with `firebase deploy --only hosting` after rebuilding.

## 10. How to Run It Locally

### Backend (Flask API)

```bash
cd backend/backend
python3 -m venv venv          # skip if you already have one that matches your Python version
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py                 # creates/migrates the DB automatically, starts on http://0.0.0.0:8000
```

No MySQL setup is required to run locally — `get_connection()` in `database.py` will try MySQL
first, fail, print a message, and transparently fall back to a local `learntrack.db` SQLite
file in the same folder. The database is initialized automatically on startup and seeds a test
account: `test@example.com` / `password`.

Verify it's up: `curl http://localhost:8000/healthcheck` → `{"status": "ok", ...}`.

### Frontend (Flutter app)

```bash
flutter pub get
flutter run                   # pick a target device/simulator/browser when prompted
```

Notes:
- On the **Android emulator**, the app already points at `10.0.2.2:8000` (the emulator's alias
  for the host machine's `localhost`) — handled automatically in `lib/config.dart`.
- On iOS simulator / macOS / web, it talks to `localhost:8000` directly, so just make sure the
  Flask server (above) is already running first.
- To point at the deployed backend instead: `flutter run --dart-define=API_BASE_URL=https://learn-track.onrender.com/api`
- Before generating a learning path, you'll be prompted to enter a **Gemini API key**
  (stored locally via `shared_preferences`) — get one from Google AI Studio or Cloud Console.

## 11. Likely Interview Questions & Talking Points

- **"Walk me through the architecture."** → Flutter + Provider on the frontend talking to a
  Flask REST API, with a local-first caching layer in between so the UI never blocks on the
  network, plus a small centralized theme system. (Section 3.)
- **"Why Provider and not Bloc/Redux/Riverpod?"** → Small state graph, wanted minimal
  boilerplate, `ChangeNotifierProxyProvider` cleanly modeled "learning data depends on auth
  state." (Section 5.)
- **"How does the AI-generated content actually become app state?"** → Gemini returns JSON per
  a strict prompt contract; it's parsed, completion flags are added to every module/lesson, and
  it's persisted like any other learning path. A cheaper Gemini call runs first to check for
  ambiguity. (Section 4/6.)
- **"What's the trickiest bug you fixed?"** → The CORS one (Section 7) is a great answer: the UI
  *looked* correct, the bug only showed up in the network tab, and the fix was subtle (removing
  code, not adding it — two conflicting CORS configurations were fighting each other).
- **"How did you use AI in this project, specifically?"** → Section 6, verbatim: symptom reports
  → assistant reproduces and root-causes → I verify against the running app → reviewed, scoped
  git commits. Be ready to open one specific commit and narrate the diff.
- **"What would you change if you had another week?"** → Straight into Section 8 — salted
  password hashing, moving the Gemini key server-side, and adding integration tests are all
  concrete, credible answers that show you understand the gap between "working demo" and
  "production system."
- **"Why did you move off Firebase?"** → Wanted full ownership of the data model and API
  surface instead of being constrained by Firestore documents, and wanted a real SQL schema/API
  to reason about and extend. (Section 5.)
- **"How is this deployed / how much does it cost?"** → Render (backend) + Firebase Hosting
  (frontend), both free tiers, $0/month, with the one real caveat that the backend cold-starts
  after 15 minutes of inactivity. (Section 9.)
