# LearnTrack — Interview Cheat Sheet (one page)

Full reference: `PROJECT_OVERVIEW.md`. This is the quick-glance version — read this
right before you walk in.

## 30-second pitch
"LearnTrack is a study app. You type a topic, AI builds you a structured course
for it — modules, lessons, real resource links — and the app tracks your
progress, a daily streak, and gives you a Pomodoro timer. Flutter frontend,
Flask backend, deployed for free on Firebase + Render."

## Stack in one breath
Flutter (Dart) app → Flask (Python) API → SQLite/MySQL. Gemini API called
directly from the app to generate the actual course content. Hosted free:
Firebase Hosting (frontend) + Render (backend).

## Your 3 best bug stories (pick 2, know them cold)

1. **Wrong person logged in after refresh.** The "is this token valid" check
   on the server didn't actually check the token — it just returned whoever
   was first in the database. Reload the page, get logged in as a stranger.
   *Fix: look the user up by their actual token, not just "return someone."*

2. **The UI lied to me.** Marking a day complete showed a success message,
   but the data never actually reached the server — confirmed in the network
   tab. Two pieces of server config for cross-origin requests were fighting
   each other, so the browser silently blocked the real request after a
   security pre-check passed. *Fix: delete the conflicting config, keep one.*

3. **AI feature just stopped working.** Learning-path generation went from
   "working" to "does nothing" with no error shown. Turned out Google
   discontinued the specific AI model version the app was pinned to. Found
   it by testing the API directly outside the app instead of guessing.
   *Fix: switch to Google's "always current" model alias, and make errors
   actually show up on screen instead of failing silently.*

## The AI-usage answer (say this, in your own words)
"I used Claude as a fast implementer, not as a source of truth. I'd give it
a symptom — 'the bar isn't full even at 100%,' 'this fails silently' — and
it would go find the actual cause and propose a fix. I decided what to build,
tested every change myself against the running app before accepting it, and
made every real decision — what to host where, what to name things, when to
actually deploy. Nothing shipped without me seeing it work first."

## If asked to explain something you're less sure of

**"What's CORS and why was that bug tricky?"**
Browsers won't let a website on one address talk to a server on a different
address unless the server explicitly says "yes, I allow requests from you."
My app's frontend and backend live at different addresses, so the server has
to send that permission back on every request. Two different pieces of code
were both trying to send that permission — and they disagreed with each
other, so the browser refused the request. It *looked* like the feature
worked because the app was designed to fail gracefully (show local data
instead of crashing), which is exactly what made it hard to notice.

**"How does login/sessions work?"**
When you log in, the server hands your app a random string (a "token") and
remembers which user it belongs to. Your app stores that string on your
device and shows it on every future request as proof of who you are — like
a coat-check ticket. The bug was that the coat check wasn't actually reading
the ticket number; it just handed back whatever coat was hanging up front.

**"What's this Provider/theme thing in the Flutter code?"**
Think of it as a shared notice board that any screen in the app can read
from or write to. When you flip the dark-mode switch in Settings, it posts
"theme changed" to that board, and every screen — because they're all
reading colors from the same board instead of hardcoding their own — updates
at once. That's why adding dark mode didn't mean redesigning every screen
individually.

## Deployment one-liner
"Free tier both sides — Render for the API, Firebase for the web app. Only
real caveat: the free backend goes to sleep after 15 minutes idle, so the
very first request after a while takes ~30-50 seconds to wake up."

## If you freeze
Fall back to: *"Let me open the code and just walk through it live"* — you
have the app running, the repo, and comments in the code explaining the
trickier parts. That's a completely legitimate move and shows real
familiarity better than reciting from memory.
