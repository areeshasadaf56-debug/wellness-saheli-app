# Wellness Saheli — Developer Setup & File Guide

> **Purpose:** Get a new developer from "empty laptop" to "app running" and
> orient them in the codebase — where things live and what each file is
> responsible for.
>
> **Scope note:** This guide documents the files reviewed and built during
> development so far. Files referenced but not yet inspected in detail are
> marked **(not yet reviewed)** — fill those sections in once you open them.

---

## 1. Prerequisites (New PC Setup)

1. **Install Flutter SDK**
   - Follow the official install guide for your OS: https://docs.flutter.dev/get-started/install
   - Run `flutter doctor` and resolve any red ✗ items (Android toolchain, Xcode if on macOS, etc.).
2. **Install an editor** — VS Code (with the Flutter/Dart extensions) or Android Studio.
3. **Install a device/emulator**
   - Android: an emulator via Android Studio's AVD Manager, or a physical device with USB debugging on.
   - iOS (macOS only): a simulator via Xcode.
4. **Get the project**
   ```bash
   git clone <your-repo-url>
   cd wellness_saheli
   ```
5. **Install dependencies**
   ```bash
   flutter pub get
   ```
6. **Run the app**
   ```bash
   flutter run
   ```
   Pick your target device when prompted if more than one is available.

### 1.1 After Pulling Model/Data Changes
Whenever a data model file (e.g. `lib/models/health_profile.dart`) changes
shape — new fields, renamed fields — **do a full restart, not hot reload**:
- In the `flutter run` terminal, press `R` (capital R) for hot **restart**.
- Hot reload (`r`, lowercase) only patches running code and can leave the app
  in a broken state when a `const` class's fields have changed.

### 1.2 Backend Dependencies
This app talks to one FastAPI service over HTTP — it is **not** fully
self-contained. The service is maintained in the sibling `pcos_ml_project`
directory and supplies authentication, profiles, chat, PCOS prediction, and
contraceptive-eligibility endpoints.

| Service | Used for | Base URL |
|---|---|---|
| FastAPI backend | Auth, profile sync, AI chat, PCOS prediction, eligibility | `ApiConfig.baseUrl` / `API_BASE_URL` |

`ApiConfig.baseUrl` defaults to `http://10.0.2.2:8000` for the Android
emulator. Override it at build or run time, for example:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example
```

If the API is down or the URL is unreachable, the screens show an error
message rather than crashing.

---

## 2. Project Folder Structure

```
lib/
├── main.dart                      (not yet reviewed — app entry point,
│                                    presumably sets up Provider and routes
│                                    to Splash/Auth/HomeShell)
├── theme/
│   └── app_theme.dart              (not yet reviewed — AppColors, AppTextStyles
│                                    used by every screen)
├── models/
│   ├── health_profile.dart         ✅ documented below
│   ├── cycle_data.dart             (not yet reviewed — cycle length/period
│                                    dates/phase math)
│   └── daily_log.dart              (not yet reviewed — per-day mood/symptom/
│                                    flow log entry)
├── providers/
│   └── cycle_provider.dart         ✅ documented below
├── services/
│   ├── health_profile_service.dart ✅ documented below
│   ├── pcos_api_service.dart       ✅ documented below — POST /predict
│   ├── eligibility_api_service.dart ✅ documented below — WHO MEC endpoints
│   └── ai_service.dart             ✅ documented below — authenticated POST /chat
├── widgets/
│   ├── month_calendar.dart         (not yet reviewed — calendar used on Home)
│   ├── wellness_check_in_dialog.dart ✅ documented below
│   └── diary_entry_dialog.dart     ✅ documented below
└── screens/
    ├── home_shell.dart             ✅ documented below
    ├── home_screen.dart            ✅ documented below
    ├── ai_checkin_screen.dart      ✅ documented below
    ├── pcos_screen.dart            ✅ documented below
    ├── protection_screen.dart      ✅ documented below
    ├── health_diary_screen.dart    ✅ documented below
    ├── endo_screen.dart            ✅ documented below (Detection tab is a placeholder)
    ├── ovulation_screen.dart       (not yet reviewed)
    ├── learn_screen.dart           (not yet reviewed)
    └── settings_screen.dart        (not yet reviewed — likely owns
                                     data_privacy_screen.dart or similar)
```

> As you open each "(not yet reviewed)" file, add a short entry for it in
> §3 below so this guide stays a complete map of the codebase.

---

## 3. What Each File Does

### `lib/models/health_profile.dart`
The single source of truth for everything the app remembers about a user
over time. Defines `HealthProfile` and its nested pieces:
- `Demographics` — age, weight, height, marital status.
- `Lifestyle` — exercise, diet, fast food, sleep, free-text notes.
- `ReproductiveHistory` + `ContraceptionLogEntry` — cycle regularity/length,
  current contraception method, and a full history of every eligibility
  check or method selection (tagged so the two are distinguishable later).
- `PcosCheckResult` — one entry per PCOS Detection run (date, prediction,
  probability, model used).
- `MentalHealthFlags` — **deliberately non-diagnostic**: a self-reported
  1–5 stress level, free-text notes, last check-in date. Never inferred or
  asserted by the app.
- `ConversationEntry` — one AI chat turn (`role`, `message`, `timestamp`,
  optional `sessionId` to group turns into distinct conversations).
- `DiaryEntry` — a free-text journal entry (separate from AI chat), with
  optional mood, symptom tags, and free-form tags.
- `PrivacySettings` — `aiCanAccessDiary` and `aiMemoryEnabled` toggles.
  These control **permission only**; they do not delete anything.

Every nested class has `toJson()` / `fromJson()` and a `copyWith()`. New
fields default gracefully (`?? []`, `?? const PrivacySettings()`, etc.) so
loading an **older saved profile** that predates a new field never throws.

### `lib/services/health_profile_service.dart`
The read/write layer between screens and `HealthProfile`. Key methods:
- `loadProfile()` — loads (or creates via `HealthProfile.empty`) the
  current user's profile.
- `updateProfile(mutator)` — loads, applies a `HealthProfile → HealthProfile`
  mutator function (usually a `copyWith(...)` call), and saves. This is the
  pattern used everywhere in the app to persist a change.
- `appendConversationEntry(entry, sessionId)` — appends one AI chat turn,
  tagging it with a session ID so multiple conversations don't blur together.

### `lib/providers/cycle_provider.dart`
A `ChangeNotifier` (Provider pattern) that is **separate storage** from
`HealthProfile` — it persists directly to `SharedPreferences`, not through
`HealthProfileService`. Owns:
- Cycle state (`CycleData`: last period start, cycle length, period
  duration) and derived getters (`currentCycleDay`, `currentPhase`,
  `daysUntilNextPeriod`).
- Per-day logs (`Map<String, DailyLog>`, keyed by `"yyyy-M-d"` string) for
  mood, symptoms, flow intensity, and whether a day was a period day.
- **Authentication** — `signUp`, `signIn`, `logout`, and the two-step
  password-reset flow call the FastAPI service through `ApiConfig.baseUrl`.
  The session token is stored locally in `SharedPreferences` for now;
  migrate to platform secure storage before production health-data rollout.

> ⚠️ **Architectural note for new developers:** cycle/mood/symptom data and
> the `HealthProfile` data (PCOS/contraception/diary/mental health) live in
> two independent systems today. This is intentional (not a bug) but means
> any future "AI context" feature that needs both must read from **both**
> `CycleProvider` and `HealthProfileService`.

### `lib/widgets/wellness_check_in_dialog.dart`
A shared, reusable dialog: `showWellnessCheckInDialog(context, current, onSaved)`.
A short, explicitly **self-report-only** check-in — a 1–5 stress slider plus
an optional free-text note. Used from the Diary screen, the PCOS screen
(after a positive result), the Protection screen (after eligibility
results), and the AI Check-in screen (mood suggestion). Saves via
`HealthProfileService.updateProfile` into `mentalHealth`.

### `lib/widgets/diary_entry_dialog.dart`
`showDiaryEntryDialog(context, onSaved)` — a free-text journal entry dialog
with optional mood chip and optional symptom-tag chips. Builds a `DiaryEntry`
and appends it to `HealthProfile.diaryEntries` via `HealthProfileService`.

### `lib/screens/home_shell.dart`
The app's root navigation shell after sign-in. Owns an `IndexedStack` of all
tab screens (so switching tabs never loses state) and a custom bottom nav
bar. Maintains `_tabNameToIndex`, a string→index map (`'home'`, `'checkin'`,
`'pcos'`, `'protection'`, etc.) so other screens can request a tab switch by
name via the `_navigateToTab` callback, without needing to know raw indices.

### `lib/screens/home_screen.dart`
The dashboard tab: greeting, cycle dial, next-period/fertility status cards,
week calendar, quick log buttons (flow/mood/symptoms — writes to
`CycleProvider`), a phase insight card, and a dismissible AI check-in banner.
The banner does **not** open a separate screen — it calls
`onNavigateToTab('checkin')` so the shell switches to the already-alive
`AiCheckinScreen` tab instance.

### `lib/screens/ai_checkin_screen.dart`
The conversational AI check-in screen. It supports English/Urdu replies,
session-based conversation history, voice-to-text input, removable file
attachments, and structured suggestions that can switch to the PCOS or
Protection tab. The backend is the safety and grounding layer: it handles
crisis/medical-emergency short-circuiting, validates attachment content,
and calls Groq when a key is configured.

### `lib/screens/pcos_screen.dart`
Two tabs: **Information** (static educational `PcosCard` accordions covering
what PCOS is, symptoms, diagnosis criteria, hormonal causes, and
management) and **Detection** (a real form — personal details, hormonal/lab
markers, blood pressure, ultrasound findings, symptoms/lifestyle toggles —
that POSTs to `PcosApiService.predict(...)` and renders a result card). If
the result is positive, a wellness check-in prompt appears. Also exports
the reusable `PcosCard`, `PcosLine`, `PcosTag` widgets, which `endo_screen.dart`
reuses for its own Information tab.

### `lib/screens/protection_screen.dart`
The largest screen in the app. Two top-level tabs:
- **Contraception** — a scrollable list of `MethodCard`s (one per
  contraception method) with detailed educational copy.
- **My Plan** — a menu leading to four sub-views:
  - **Eligibility tool** — select an age bracket + medical conditions
    (large nested `_conditionGroups` tree, cross-checked against
    `_apiConditionIds` returned by `EligibilityApiService.fetchConditions()`
    so only backend-supported conditions are selectable) or filter by
    **Preferences** (highly effective, STI prevention, no hormones, etc.).
    Tapping "Check my eligibility" calls
    `EligibilityApiService.checkEligibility(...)` and renders category
    1–4 results, which are also fire-and-forget logged to
    `HealthProfile.reproductiveHistory.contraceptionHistory`.
  - **Methods** — browse the same method list in more detail; "I'm using
    this method" saves it as the current method + a history entry.
  - **Additional info** — Emergency contraception guidance, effectiveness
    comparison chart, and an ARV drug-class glossary.
  - **How to use the tool** — a short onboarding explainer.

### `lib/screens/health_diary_screen.dart`
The unified Timeline + Profile screen. Merges four data sources into one
sorted, month-grouped timeline: PCOS checks, contraception history (split
visually into "Eligibility Check" vs. "Protection Method" via a note-prefix
convention), free-text diary entries, and AI conversation turns. The Profile
tab shows read-only summaries of Demographics/Lifestyle/Reproductive
Health/Wellbeing, plus the "Log how you're feeling" and "Write in your
diary" entry points.

### `lib/screens/endo_screen.dart`
Mirrors `pcos_screen.dart`'s structure. The **Information** tab is fully
built (overview, symptoms, staging/diagnosis, treatment — reusing
`PcosCard`/`PcosLine`/`PcosTag` from `pcos_screen.dart`). The **Detection**
tab is currently a **placeholder only** — a static "coming soon"-style card
with no form and no persistence. This was an explicit product decision to
defer; see §5.

---

## 4. Common Development Patterns (so new code stays consistent)

- **Persisting a `HealthProfile` change:** always via
  `HealthProfileService().updateProfile((p) => p.copyWith(...))` — never
  mutate a loaded `HealthProfile` in place (all its fields are `final`).
- **Reloading after a write:** screens that display profile data call
  `_load()` (which calls `loadProfile()` again) after any write, usually
  via an `onSaved` callback passed into dialogs.
- **Fire-and-forget writes:** background persistence that shouldn't block
  showing a result to the user (see `_logEligibilityResultsToDiary` in
  `protection_screen.dart`) uses `unawaited(...)` and swallows errors
  silently, since the primary result is already on-screen regardless of
  whether the write succeeds.
- **Distinguishing sub-kinds of the same model via a note-prefix
  convention:** e.g. `ContraceptionLogEntry.note` starting with
  `"Eligibility check"` marks it apart from a manual method save. This
  avoids adding a new enum field for something that's still fundamentally
  the same underlying record type.
- **Cross-screen navigation without direct references:** screens never
  `Navigator.push` each other for tab switches — they call
  `onNavigateToTab(name)`, a callback threaded down from `HomeShell`, which
  is the only place that knows the actual tab index.

---

## 5. Known Gaps / Next Phases (for the next developer to pick up)

1. **Secure local token storage.** The current session token is in
   `SharedPreferences`; move it to platform secure storage before
   production rollout.
2. **Provider and privacy review.** Configure and verify Groq and SMTP
   credentials, review provider data handling, and retain the existing
   non-diagnostic and user-controlled AI-context safeguards.
3. **Full WHO MEC dataset.** The backend currently exposes 12 curated
   conditions; the complete dataset is future work.
4. **Shared production infrastructure.** SQLite and in-process rate limits
   are appropriate for the current single-instance target only; use a
   managed database and shared rate limiting before scaling out.
5. **Endometriosis Detection tab** — intentionally left as a placeholder;
   revisit using the same pattern as PCOS Detection, but as a
   symptom-based questionnaire (no lab/ultrasound values) producing a
   non-diagnostic risk/concern level.
6. **Unreviewed files** — `main.dart`, `app_theme.dart`, `cycle_data.dart`,
   `daily_log.dart`, `month_calendar.dart`, `ovulation_screen.dart`,
   `learn_screen.dart`, and `settings_screen.dart` should each get an
   entry in §3 once inspected.
