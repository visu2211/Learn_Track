# LearnTrack — Project Overview & Interview Notes

## 1. Elevator Pitch

LearnTrack is a cross-platform learning-tracker app (Flutter frontend + Flask REST API backend)
that helps a user pick a topic, get an AI-generated structured learning path for it (modules →
lessons → curated resources), track their progress lesson-by-lesson, keep a daily study streak,
and run focused study sessions with a built-in Pomodoro timer. The core idea: instead of a static
"course tracker," the app *generates the curriculum itself* using the Gemini API, then treats that
generated curriculum as trackable state (progress bars, streaks, completion gates).

## 2. Tech Stack

**Frontend**
- Flutter (Dart, SDK ^3.5.4), Material 3
- State management: `provider` (ChangeNotifier + MultiProvider + ProxyProvider)
- `google_generative_ai` — direct client-side integration with Google's Gemini API
- `http` for REST calls to the Flask backend
- `shared_preferences` for local/offline persistence
- `google_fonts`, `flutter_svg` for UI polish

**Backend**
- Python Flask, organized with Blueprints (`auth`, `users`)
- `flask-cors` for cross-origin requests (needed since the Flutter web build runs on a
  different origin/port than the API)
- Persistence: MySQL via `PyMySQL`, with an automatic fallback to a local SQLite file
  (`learntrack.db`) if a MySQL server isn't reachable — implemented as a drop-in connection
  wrapper (`SQLiteConnection`/`SQLiteCursor`) that mimics the PyMySQL cursor API so the rest of
  the codebase doesn't need to know which database it's talking to.

**Platforms**: iOS, Android, web, macOS, Windows, Linux (standard Flutter multi-platform targets).

## 3. Architecture

```
Flutter App
 ├─ providers/          ChangeNotifier state (AuthProvider, LearningProvider)
 ├─ services/           HTTP + local-storage + Gemini API integration
 ├─ screens/             UI (auth, dashboard, learning paths, pomodoro)
 └─ widgets/             Reusable components (cards, buttons, streak UI)

Flask API (backend/backend)
 ├─ app.py               App factory, CORS, request/response logging, /healthcheck
 ├─ config.py            DB + secret config
 ├─ database.py          get_connection() → MySQL, falls back to SQLite
 ├─ blueprints/auth.py   /api/auth/signup, /login, /signin, /validate
 └─ blueprints/users.py  /api/users/<id>

Data: SQLite (learntrack.db) or MySQL, schema.sql defines a single `users` table
```

**Auth flow**: signup/login hashes the password (SHA-256) server-side, checks it against the
stored hash, and returns an opaque token (`sha256(email + password_hash + name)`) that the
client stores in `SharedPreferences` and sends as a `Bearer` token on subsequent requests.
`AuthProvider` wraps this in a `ChangeNotifier` so the whole widget tree reactively rebuilds
between the login screen and the dashboard.

**Learning data flow**: `LearningProvider` is wired to `AuthProvider` via a `ChangeNotifierProxyProvider`
so that logging in/out automatically triggers loading/clearing of learning data — no manual
wiring needed in each screen. `LearningService` follows a **network-first, local-cache-fallback**
pattern for every read: try the API → on failure, read the last-known value from
`SharedPreferences` → on total failure, degrade gracefully to safe mock/empty data so the UI
never crashes or shows a blank error state.

## 4. Key Features

- **Email/password auth** with token-based sessions persisted locally.
- **AI-generated learning paths**: user enters a topic, the app calls Gemini
  (`gemini-1.5-pro`) with a structured prompt that requests real modules, lessons, and
  resource links (articles/videos/courses/books/tools) in strict JSON, which is parsed and
  turned into trackable state.
- **Progress tracking**: completing a lesson checks that prior lessons in the module are done
  (sequential gating), rolls up into module completion, and rolls up into path/course progress.
- **Daily streaks**: a weekly streak view (current streak, longest streak, days completed)
  persisted both server-side and locally.
- **Pomodoro timer**: Work/Short Break/Long Break modes with a running countdown, for in-app
  focus sessions tied to the study workflow.

## 5. Design Decisions (and why)

- **Provider over Bloc/Riverpod** — the state graph here is small (auth + one learning
  domain), so a lighter `ChangeNotifier`-based approach kept the code readable without the
  boilerplate of a stricter state-management framework. `ChangeNotifierProxyProvider` was the
  key piece: it let auth state and learning state stay decoupled while still reacting to each
  other.
- **Local-first reads with server sync** — every learning-data read tries the network first
  but always has a `SharedPreferences` fallback, and every write saves locally before it
  attempts to hit the server. The app should never show a blank/broken screen just because the
  Flask server isn't reachable (e.g., dev environment, flaky connection, cold start) — it
  degrades to cached or mock data instead of failing outright.
- **MySQL with automatic SQLite fallback** — rather than forcing every contributor to stand up
  a MySQL instance to run the backend locally, `get_connection()` tries MySQL and transparently
  falls back to a local SQLite file with the same cursor interface. This was a deliberate
  choice to keep local setup to "clone and run" with zero external services required, while
  still supporting a real MySQL deployment target.
- **Flask Blueprints + a versionless `/api` prefix** — auth and user routes are isolated into
  their own blueprints and mounted under a shared `/api` blueprint, so new resource types
  (courses, paths, streaks) can be added as their own blueprint without touching existing
  routes.
- **Client-side Gemini integration instead of proxying through the backend** — the API key is
  stored locally and the Flutter app talks to Gemini directly. This kept the backend focused
  purely on auth/user data and avoided adding an extra network hop and server-side dependency
  for a feature that's inherently a "generate content for this one user" operation. (See
  Section 7 for the tradeoff this introduces.)
- **Migrated off Firebase to a self-built Flask + SQL backend** — the git history shows an
  earlier Firebase/Firestore integration (`Connecting Firebase…`, `chai changes for firestore`)
  that was later removed (`Removed firebase`) in favor of a custom Flask API. This was a
  conscious move to fully own the backend logic and data model instead of being constrained by
  Firestore's document structure, and to be able to talk about a real REST API / SQL schema in
  interviews rather than "I called Firebase SDK methods."

## 6. How AI Was Used to Build This

AI was used in two distinct ways on this project — as a **product feature** and as a
**development tool**:

- **Product feature**: Gemini (`google_generative_ai`) is a first-class part of the app, not a
  gimmick — it's the engine that turns a raw topic string into a structured curriculum
  (modules → lessons → resources) that the rest of the app treats as real, trackable data. The
  prompt was engineered iteratively to force strict JSON output, request real (non-placeholder)
  resource URLs, and attach resources at the lesson level rather than the path level, so the
  generated content is actually usable rather than generic.
- **Development tool**: an AI coding assistant (Claude Code) was used to scaffold boilerplate
  (Flutter widgets, Flask blueprint structure), speed up repetitive Dart/Python code (provider
  wiring, HTTP service methods, SQLite/MySQL cursor shims), and help debug cross-platform issues
  like the Android emulator's `10.0.2.2` loopback address for reaching `localhost` on the host
  machine. Architectural decisions — provider/service split, local-first caching, the MySQL→SQLite
  fallback, moving off Firebase — were product/design calls made deliberately; AI accelerated the
  implementation of those decisions rather than making them.

*(Good interview framing: "I use AI tools the way I'd use a very fast pair programmer — I decide
the architecture and tradeoffs, it helps me write and debug the code faster, and I always read
and understand what it produces before it goes in.")*

## 7. Known Limitations / What I'd Improve Next

Being upfront about these in an interview reads as self-awareness, not a weakness. (The first
two below were the two demo-blocking bugs — they're now fixed on `feature/final-fixes`; kept
here as a talking point on debugging process.)

- ~~**Backend port mismatch**~~ — *Fixed.* `LearningService.baseUrl` was hardcoded to
  `http://localhost:5000/api` while the Flask server actually runs on `8000` (the same port
  `AuthService` already used). Courses/paths/streak calls were silently failing and falling
  back to local storage. `LearningService` now mirrors `AuthService`'s platform-aware base URL
  (including the `10.0.2.2` Android-emulator loopback).
- ~~**Courses/paths/streak endpoints aren't implemented server-side**~~ — *Fixed.* Added a new
  `blueprints/learning.py` (`learning_bp`) exposing `GET/POST /api/users/<id>/courses`,
  `/paths`, and `/streak`, backed by a generic `user_data (user_id, data_type, data JSON)`
  table (SQLite `ON CONFLICT` / MySQL `ON DUPLICATE KEY` upsert). This keeps the data model
  simple — no separate schema per feature — while giving every learning-provider read/write a
  real server round trip instead of silently degrading to local storage. Table is created
  automatically by `init_db.py`.
- **Password hashing is unsalted SHA-256**, not `bcrypt`/`argon2` — fine for a class/portfolio
  project, but a real product would need salted, slow hashing and a real JWT (with expiry)
  instead of a static derived token.
- **Client-side Gemini API key** means the key lives on-device and every user needs their own
  key — a production version would proxy Gemini calls through the backend so the key stays
  server-side and usage can be rate-limited/metered per user.
- **Hardcoded secrets in `config.py`** (`SECRET_KEY`, DB password) — would move to environment
  variables / `.env` + `python-dotenv` before shipping.
- **`venv/` and `learntrack.db` are committed to git** — should be gitignored; local envs
  should be built fresh with `requirements.txt`.

## 8. How to Run It Locally

### Backend (Flask API)

```bash
cd backend/backend
python3 -m venv venv          # skip if you already have one that matches your Python version
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt
python init_db.py             # creates the schema; falls back to SQLite automatically if no MySQL is running
python app.py                 # starts the API on http://0.0.0.0:8000
```

No MySQL setup is required to run locally — `get_connection()` in `database.py` will try MySQL
first, fail, print a message, and transparently fall back to a local `learntrack.db` SQLite
file in the same folder. `init_db.py` also seeds a test account:
`test@example.com` / `password`.

Verify it's up: `curl http://localhost:8000/healthcheck` → `{"status": "ok", ...}`.

### Frontend (Flutter app)

```bash
flutter pub get
flutter run                   # pick a target device/simulator/browser when prompted
```

Notes:
- On the **Android emulator**, the app already points at `10.0.2.2:8000` (the emulator's alias
  for the host machine's `localhost`) — this is handled automatically in `auth_service.dart`.
- On iOS simulator / macOS / web, it talks to `localhost:8000` directly, so just make sure the
  Flask server (above) is already running first.
- Before generating a learning path, you'll be prompted to enter a **Gemini API key**
  (stored locally via `shared_preferences`) — get one from Google AI Studio.

## 9. Likely Interview Questions & Talking Points

- **"Walk me through the architecture."** → Flutter + Provider on the frontend talking to a
  Flask REST API, with a local-first caching layer in between so the UI never blocks on the
  network. (Section 3.)
- **"Why Provider and not Bloc/Redux/Riverpod?"** → Small state graph, wanted minimal
  boilerplate, `ChangeNotifierProxyProvider` cleanly modeled "learning data depends on auth
  state." (Section 5.)
- **"How does the AI-generated content actually become app state?"** → Gemini returns JSON per
  a strict prompt contract; it's parsed, completion flags are added to every module/lesson, and
  it's persisted like any other learning path. (Section 4/6.)
- **"What would you change if you had another week?"** → Straight into Section 7 — the port
  mismatch, missing course/path/streak endpoints, and moving the Gemini key server-side are all
  concrete, credible answers that show you understand the gap between "working demo" and
  "production system."
- **"Why did you move off Firebase?"** → Wanted full ownership of the data model and API
  surface instead of being constrained by Firestore documents, and wanted a real SQL schema/API
  to reason about and extend. (Section 5.)
