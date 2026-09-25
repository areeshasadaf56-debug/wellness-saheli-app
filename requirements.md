# Wellness Saheli — Software Requirements Specification (SRS)

**Version:** 2.0 (fully expanded)
**Date:** 13 September 2026
**Status:** Derived from and verified against the live codebase
**Repositories:**
- Frontend: `github.com/areeshasadaf56-debug/wellness-saheli-app` (Flutter/Dart)
- Backend: `github.com/areeshasadaf56-debug/wellness-saheli-server` (Python/FastAPI)
- Deployment target: Railway/Render; current local API entry point is `app_backend.main:app`

---

## 0. Document Control

### 0.1 Purpose of this document
This SRS is written to be handed directly to a developer or an AI coding agent as the authoritative specification of the system. Every requirement below is traceable to a specific file, class, function, or endpoint in the existing codebase. Where a requirement describes something not yet built, it is explicitly marked **[NOT IMPLEMENTED]**.
### 0.2 Current implementation corrections

The following sections describe the current code, not the removed Flask implementation. The backend is FastAPI, the current eligibility module intentionally exposes a curated subset, and Phase 1 security requirements are implemented locally but still require live deployment validation.

### 0.3 Terminology
- **Profile / diary**: the `HealthProfile` JSON document — the single per-user record holding demographics, lifestyle, reproductive history, PCOS history, eligibility history, mental-health flags, conversation log, diary entries, and privacy settings.
- **Screening**, not diagnosis: the app never asserts a medical condition exists.
- **Category (1–4)**: WHO Medical Eligibility Criteria safety category for a contraceptive method given a condition.

---

## 1. Project Overview

Wellness Saheli is a women's reproductive-health application consisting of:

1. A **Flutter** client (Android, iOS, and Web from one codebase) with the 8-tab app shell and local-first cycle/diary data.
2. A **FastAPI** backend exposing authenticated account/profile/chat routes, public reference/eligibility routes, and the serialized PCOS model. It targets Railway/Render; deployment configuration remains an explicit production task.

It provides: menstrual cycle tracking, ovulation/fertility estimation, ML-based PCOS risk screening, WHO-MEC-based contraceptive eligibility checking, a bilingual (English/Urdu) AI check-in companion with voice input and file attachments, educational content, and a unified health diary synced across devices.

---

## 2. Problem Statement

Women, particularly in under-resourced settings, lack a single accessible tool combining cycle tracking, PCOS screening, contraceptive guidance, and supportive conversation without requiring a clinic visit for basic informational needs. Existing apps typically cover only one of these areas in isolation, and few provide any Urdu-language support.

---

## 3. Project Objectives

| ID | Objective | Satisfied by |
|---|---|---|
| OBJ-01 | Provide accurate menstrual cycle and ovulation tracking | FR-05 … FR-08 |
| OBJ-02 | Provide ML-based PCOS risk screening (screening, not diagnosis) | FR-09, FR-10 |
| OBJ-03 | Provide contraceptive eligibility guidance per WHO MEC | FR-11 … FR-13 |
| OBJ-04 | Provide supportive, non-diagnostic AI check-in with crisis handling | FR-14 … FR-17 |
| OBJ-05 | Consolidate all health data into one synced cross-device diary | FR-18, FR-19 |
| OBJ-06 | Make the AI usable by Urdu-speaking users | FR-22 |
| OBJ-07 | Allow users to bring in outside material (lab reports, documents) | FR-23, FR-24 |

---

## 4. Target Users and Roles

### 4.1 Users
- **Primary:** Women of reproductive age seeking cycle tracking and reproductive-health information.
- **Secondary:** Users evaluating contraceptive options wanting a quick eligibility reference before consulting a provider.
- **Tertiary:** Urdu-first speakers who cannot comfortably use an English-only health app.

### 4.2 Roles
| Role | Description | Capabilities |
|---|---|---|
| Registered User | Email/password account with a server-issued `user_id` and session token | All features; cross-device sync |
| Local-only User | A device where a profile cache exists but no valid session | Read/write local cache only; **no** backend calls, no sync |

There is **no** admin or clinician role. There is no mechanism for any user to view another user's data.

---

## 5. Functional Requirements

### 5.1 Authentication & Accounts

| ID | Requirement | Implementation |
|---|---|---|
| FR-01 | The system shall allow account creation with name, email, and password. Password minimum length: **6 characters**. Email is normalized (trimmed, lowercased) before storage and comparison. | `POST /signup`; `sign_up_screen.dart` |
| FR-01a | Signup shall return `{name, user_id, token, expires_at}`. The user id is an integer assigned by the FastAPI/SQLite user store. | `app_backend/auth.py::sign_up` |
| FR-01b | Attempting to sign up with an email that already exists shall return **409**. | `app_backend/auth.py::sign_up` |
| FR-01c | Signup shall be rate limited to **5 attempts per 600 seconds** per client key. | `app_backend/auth.py::_check_rate_limit` |
| FR-02 | The system shall allow sign-in with email and password, returning `{name, user_id, token, expires_at}`. | `POST /signin`; `sign_in_screen.dart` |
| FR-02a | Sign-in shall be rate limited to **8 attempts per 300 seconds**, keyed per `(client, email)` pair. | `app_backend/auth.py::sign_in` |
| FR-03 | The system shall request a one-time password-reset code for an email address. | `POST /reset_password/request`; `sign_in_screen.dart` |
| FR-03a | Password-reset requests shall return the same generic status whether or not the email exists, preventing account enumeration. | `app_backend/auth.py::request_password_reset` |
| FR-03b | A successful password reset shall validate the emailed 8-digit code, update the password, and invalidate **all** existing sessions for that account. | `POST /reset_password/confirm`; `app_backend/auth.py::confirm_password_reset` |
| FR-03c | Password reset shall rate-limit requests and confirmations, expire codes after **15 minutes**, and reject a code after **5** failed attempts. | `app_backend/auth.py`; `app_backend/database.py` |
| FR-04 | The system shall require a signed-in account for all cloud-backed features. A locally generated anonymous device ID is used only for local cache identity and never authenticates a backend request. | `health_profile_service.dart::getDeviceId` |
| FR-04a | The device ID shall be a UUID-shaped string generated from `Random.secure()`, persisted under SharedPreferences key `health_profile_device_id`. | same |
| FR-05 | The system shall allow logout, invalidating the server-side session on a best-effort basis and always clearing local state regardless of server response. | `POST /logout`; `cycle_provider.dart::logout` |
| FR-06 | Sessions shall expire **30 days** after issue; server-side expiry is parsed as a timestamp rather than compared lexically. | `app_backend/auth.py`; `app_backend/database.py` |
| FR-07 | The client shall persist the bearer token and account id locally and attach `Authorization: Bearer <token>` to every request touching personal data. | `cycle_provider.dart`, all services |

### 5.2 Cycle Tracking

| ID | Requirement | Implementation |
|---|---|---|
| FR-08 | The system shall record last period start date, average cycle length (default **28** days), and period duration (default **5** days). | `CycleData`; `cycle_data_screen.dart` |
| FR-09 | The system shall compute the current cycle day as `((today − lastPeriodStart).inDays % cycleLength) + 1`, 1-based. | `CycleData.getCurrentCycleDay()` |
| FR-10 | The system shall derive a phase label: **Menstrual** (day ≤ periodDuration), **Follicular** (day ≤ floor(cycleLength/2)), **Ovulation** (day ≤ floor(cycleLength/2)+2), **Luteal** (otherwise). | `CycleData.getPhase()` |
| FR-11 | The system shall compute days until next period as `cycleLength − currentDay + 1`. | `CycleData.daysUntilNextPeriod()` |
| FR-12 | The system shall estimate the fertile window and ovulation day from cycle data and display them. | `ovulation_screen.dart` |
| FR-13 | The system shall allow per-day logging of: period-day flag, mood, symptom list, and flow intensity. | `DailyLog`; `month_calendar.dart` |
| FR-14 | Cycle data and daily logs shall persist locally via SharedPreferences and survive app restart. | `cycle_provider.dart::_saveCycleData`, `_saveDailyLogs` |
| FR-15 | The system shall provide a month calendar view supporting date selection and visual indication of logged days. | `month_calendar.dart` |
| FR-16 | The system shall support a reminders on/off toggle, persisted locally. | `cycle_provider.dart::toggleReminders` |

### 5.3 PCOS Screening

| ID | Requirement | Implementation |
|---|---|---|
| FR-17 | The system shall accept exactly **22** clinical/lifestyle fields and return `{prediction, pcos_probability, model_used}`. | `POST /predict` |
| FR-17a | The 22 required field keys are: `age_yrs, weight_kg, height_cm, cycle_regularity, cycle_length_days, prl, vit_d3, prg, rbs, bp_systolic, bp_diastolic, follicle_no_l, follicle_no_r, avg_f_size_l, avg_f_size_r, endometrium, weight_gain, hair_growth, skin_darkening, hair_loss, pimples, fast_food, regular_exercise`. | `REQUIRED_FIELDS` |
| FR-17b | BMI shall be **derived server-side** as `weight_kg / (height_cm/100)²` — it is a model feature but is never sent by the client. | `build_feature_vector` |
| FR-17c | Features shall be assembled in the exact order given by `model_metadata.json::feature_order` (22 entries, BMI at index 1), then scaled with the persisted scaler before prediction. | same |
| FR-17d | `cycle_regularity` shall encode as Regular→**2**, Irregular→**4** (not 0/1 — this matches the training dataset's encoding). | `CYCLE_ENCODING` |
| FR-17e | All Yes/No fields shall encode via `BINARY_ENCODING` (Yes→1, No→0), case-insensitively via `.capitalize()`. | `encode_binary` |
| FR-17f | Missing fields shall return **422** naming every missing field. Invalid categorical values shall return **422** naming the offending field and the value received. | `predict()` |
| FR-17g | Model/library exceptions shall return a **500** with a generic user-facing message; internal details shall never be leaked in the response. | `predict()` |
| FR-18 | The system shall report which trained model produced the prediction (`model_metadata.json::model_name` — currently `NaiveBayes`, calibrated). | `/predict` response |
| FR-19 | Prediction output labels shall be exactly `"PCOS Detected"` / `"No PCOS Detected"`; probability shall be the class-1 probability rounded to 4 decimals. | `predict()` |
| FR-20 | Each completed PCOS check shall be appended to `pcosHistory` in the user's profile with date, prediction, probability, and model name. | `appendPcosResult` |
| FR-21 | On a successful PCOS check, the form shall write the entered age, weight, height, cycle regularity, and cycle length back to the profile alongside the result. | `pcos_screen.dart::_runDetection` |
| FR-22 | The PCOS form shall pre-populate age/weight/height from the stored profile when those fields are empty and profile values exist. | `pcos_screen.dart` (lines ~82–93) |

### 5.4 Contraceptive Eligibility

| ID | Requirement | Implementation |
|---|---|---|
| FR-23 | The system shall expose the curated backend condition list (**12** conditions, each `{id, label}`); unsupported local conditions remain visibly unassessed. | `GET /conditions`; `app_backend/eligibility_data.py` |
| FR-24 | The system shall expose the **10** modeled methods: `chc`, `pop`, `poi`, `impl`, `lng_iud`, `cu_iud`, `barrier`, `lam`, `fem_ster`, and `male_ster`. | `GET /methods_reference`; `app_backend/eligibility_data.py` |
| FR-25 | The system shall expose typical-use failure rates for the 10 modeled methods with practical usage notes. | `GET /effectiveness` |
| FR-26 | Given selected condition IDs, the system shall return a category 1–4 for each modeled method when data exists; otherwise it shall return `null` with an insufficient-data note. | `POST /eligibility` |
| FR-26a | Where multiple conditions are selected, the returned category per method shall be the most restrictive (numerically highest) classified category. | `app_backend/eligibility_data.py::check_eligibility` |
| FR-26b | Category semantics: **1** = no restriction; **2** = advantages generally outweigh risks; **3** = risks usually outweigh advantages; **4** = unacceptable health risk. | `app_backend/eligibility_data.py` |
| FR-27 | Requests containing unrecognized condition IDs shall return **422** naming every unknown ID; condition lists are bounded to 100 entries. | `app_backend/main.py::post_eligibility` |
| FR-28 | Each completed eligibility check shall be appended to `eligibilityHistory` with date, the conditions selected, and the per-method results. | `appendEligibilityCheck` |
| FR-29 | The user shall be able to record a current contraception method, appended to `contraceptionHistory` with date and optional note. | `ContraceptionLogEntry`; `protection_screen.dart` |

### 5.5 AI Check-In

| ID | Requirement | Implementation |
|---|---|---|
| FR-30 | The system shall provide a conversational AI check-in covering lifestyle, mood, sleep, stress, and reproductive health. | `POST /chat`; `ai_checkin_screen.dart` |
| FR-31 | The AI shall use the Groq Chat Completions API (OpenAI-compatible shape), model `llama-3.3-70b-versatile`, `max_tokens=800`. | `app_backend/chat.py` |
| FR-31a | The model shall support tool/function calling; the structured insight tool is wrapped in the OpenAI-compatible function shape. | `app_backend/chat.py::INSIGHTS_TOOL` |
| FR-32 | The API key shall be read from environment variable `GROQ_API_KEY` and never hardcoded. If absent, the backend shall return a safe explanatory fallback rather than fail the request. | `app_backend/chat.py::get_reply` |
| FR-32a | Production deployments shall configure `GROQ_API_KEY` through the hosting platform's environment-variable store, never source code. | `.env.example`; Railway/Render configuration |
| FR-33 | The AI shall reply conversationally in 2–4 sentences, asking **one** question at a time. | `SYSTEM_PROMPT` rule 3 |
| FR-34 | The AI shall call the `record_checkin_insights` tool when — and only when — concrete structured signal is available, returning any of: `lifestyle{regular_exercise, exercise_frequency, diet_quality, fast_food_frequent, average_sleep_hours}`, `mental_health{self_reported_stress_level (1–5), notes}`, `reproductive_history{cycle_regularity, cycle_length_days}`, plus `suggested_tab`, `suggested_tab_reason`, `crisis_concern`. | `INSIGHTS_TOOL` |
| FR-35 | `suggested_tab` shall be restricted to `"pcos"` or `"protection"` and set only where a genuine, specific reason exists tied to what the user said. | `SYSTEM_PROMPT` rule 6 |
| FR-36 | **Empty-reply mitigation:** when the model returns a tool call with empty `message.content`, the backend shall issue a **follow-up completion** so the user never sees a blank bubble. | `app_backend/chat.py` |
| FR-37 | Conversation history shall be sent from the client as `[{role, message}]` and converted server-side to OpenAI message format, with the system prompt prepended as the first message. | `_history_to_messages` |
| FR-38 | Each user and assistant turn shall be appended to the profile's `conversationLog` with timestamp, role, message, and session ID. | `appendConversationEntry` |
| FR-39 | The user shall be able to start a new chat session (new `sessionId`) and browse prior sessions from history. | `ai_checkin_screen.dart::_startNewChat`, `_openHistory` |
| FR-40 | When `privacySettings.aiMemoryEnabled` is false, prior history shall **not** be sent to the model; the conversation shall start fresh each turn. | `ai_checkin_screen.dart` |
| FR-41 | The `/chat` endpoint shall require authentication, preventing anonymous consumption of the API key quota. | `app_backend/main.py::chat_endpoint` |

### 5.6 Bilingual Support (English / Urdu)

| ID | Requirement | Implementation |
|---|---|---|
| FR-42 | The chat screen shall provide a language toggle in the header, displaying `EN` or `اردو` with a translate icon. | `ai_checkin_screen.dart::_toggleLanguage` |
| FR-43 | The selected language shall persist across app restarts under SharedPreferences key `ai_checkin_language`. | same |
| FR-44 | The client shall send `language: "en" \| "ur"` in the `/chat` request body. | `ai_service.dart::sendMessage` |
| FR-45 | When `language == "ur"`, the backend shall append an instruction to the system prompt directing the model to reply in natural, warm, conversational Urdu **for the entire conversation, regardless of the language the user writes in**, unless the user explicitly asks to switch back to English. | `_language_instruction` |
| FR-46 | When Urdu is selected, the message input field shall render right-to-left and display an Urdu placeholder (`سہیلی کو پیغام بھیجیں…`). | `_inputBar()` |
| FR-47 | Language switching shall require no app restart and shall not clear the existing conversation. | by design |
| FR-48 | **[NOT IMPLEMENTED]** Urdu localisation of the remaining 17 screens (labels, buttons, educational content). Only the AI chat is bilingual today. | — |

### 5.7 Voice Input

| ID | Requirement | Implementation |
|---|---|---|
| FR-49 | The chat screen shall provide a microphone button performing live speech-to-text into the message field. | `speech_to_text: ^7.0.0` |
| FR-50 | Recognition locale shall follow the language toggle: `ur_PK` when Urdu, `en_US` when English. | `_toggleListening` |
| FR-51 | Recognized words shall stream into the text field as the user speaks, with the caret kept at the end; the user reviews and edits before sending. Voice shall **not** auto-send. | same |
| FR-52 | While listening, the mic icon shall change to a filled state in the alert colour and the placeholder shall read "Listening…". | `_inputBar()` |
| FR-53 | Availability shall be checked at init; if unsupported (non-Chromium browser), tapping shall show a clear message rather than failing silently. | `_initSpeech` |
| FR-54 | Recognition errors and status changes (`done`, `notListening`) shall reset the listening state and surface the error text. | same |
| FR-55 | Any active recognition shall be stopped in `dispose()`. | same |

### 5.8 Attachments

| ID | Requirement | Implementation |
|---|---|---|
| FR-56 | The chat screen's "+" button shall open a file picker restricted to: `png, jpg, jpeg, gif, webp, pdf, doc, docx, txt`. | `file_picker: ^8.1.2` |
| FR-57 | Files shall be read with `withData: true` (required for web) and rejected with a clear message if bytes are unreadable. | `_pickAttachment` |
| FR-58 | Attachments shall be limited to **8 MB**; larger files shall be rejected by name with a clear message. | same |
| FR-59 | A staged attachment shall render as a removable chip above the input bar, with a distinct icon for images vs documents, before it is sent. | `_attachmentChip` |
| FR-60 | The attachment shall be transmitted as `attachment: {file_name, mime_type, data_base64}` in the `/chat` body. | `ChatAttachment.toJson` |
| FR-61 | A message may consist of an attachment with no text; in that case the chat bubble shall display `📎 <filename>` and the model shall receive `"(no text, see attachment)"`. | `_sendMessage` |
| FR-62 | The backend shall extract text from PDFs via `pypdf` and DOCX via `python-docx`, truncated to **6000 characters**. Legacy `.doc` shall be acknowledged without unsafe parsing. | `app_backend/chat.py::extract_attachment_text` |
| FR-63 | Plain text shall be UTF-8 decoded; undecodable content shall be rejected with a user-facing error. | same |
| FR-64 | Attachment MIME types, decoded size, and content signatures shall be validated before extraction. | `app_backend/main.py`; `app_backend/chat.py` |
| FR-65 | **Images:** the current model is text-only and cannot read image pixels. The backend shall pass a note instructing the assistant to acknowledge receipt honestly and ask the user to describe the image, rather than hallucinating contents. | `_extract_attachment_text` |
| FR-66 | Extracted content shall be folded into the **same** user turn as the typed message (not a separate message), preserving conversational coherence. | `chat()` |
| FR-67 | **[FUTURE]** Real image understanding requires switching to a vision-capable Groq model (e.g. a `llama-3.2-*-vision` variant) and sending image content blocks instead of the text note. | — |

### 5.9 Input Ergonomics

| ID | Requirement | Implementation |
|---|---|---|
| FR-68 | Pressing **Enter** on a physical keyboard shall send the message. | `_handleKey` |
| FR-69 | Pressing **Shift+Enter** shall insert a newline instead of sending. | same |
| FR-70 | The input field shall auto-grow between **1 and 4** lines. | `_inputBar()` |
| FR-71 | While a send is in flight, the send button shall be replaced by a progress indicator and further sends shall be blocked. | `_sending` guard |

### 5.10 Health Diary & Profile

| ID | Requirement | Implementation |
|---|---|---|
| FR-72 | The system shall persist a full `HealthProfile` server-side as a single JSON document keyed by `user_id`. | `PUT /profile/<user_id>` |
| FR-73 | The profile payload shall be capped at **300,000 bytes**; larger payloads return **413**. | `MAX_PROFILE_BYTES` |
| FR-74 | A `user_id` present in the body that contradicts the URL shall return **422**. The URL is authoritative and is force-written into the stored body. | `save_profile` |
| FR-75 | GET on a user with no stored profile shall return **404**, and the client shall fall back to a blank local profile rather than erroring. | `get_profile`, `loadProfile` |
| FR-76 | Saves shall be **upserts** (`ON CONFLICT DO UPDATE`), replacing the whole document — partial-merge logic lives client-side in `updateProfile()`. | `save_profile` |
| FR-77 | **Load order shall be local-cache-first.** The local cache is authoritative for "what this device just did"; the backend is fetched in the background only to pick up changes from other devices. | `loadProfile` |
| FR-78 | A backend copy shall be adopted **only** if `remote.lastUpdated.isAfter(local.lastUpdated)`. A stale server record must never clobber a fresher local one. (This guards the historical bug where a PCOS result saved seconds earlier vanished on reopening the Diary.) | `_refreshFromBackendIfNewer` |
| FR-79 | Saves shall write to local cache **immediately** and push to the backend in the background; UI shall never block on the network. A failed push shall leave the local cache correct and retry on the next save/load. | `saveProfile` |
| FR-80 | All profile access shall route through `HealthProfileService` — screens shall not call the backend directly. | architectural rule |
| FR-81 | The system shall present a unified, reverse-chronological timeline merging PCOS results, contraception changes, eligibility checks, cycle logs, and AI conversations. | `health_diary_screen.dart` |
| FR-82 | The diary shall show summary counts (PCOS checks, methods logged, cycle entries, AI check-ins) and a Timeline/Profile tab switch. | same |
| FR-83 | The Profile tab shall display four sections — Demographics, Lifestyle, Reproductive Health, Wellbeing — showing "Not set" for null values, plus a "Last updated" line. | `_buildProfileTab` |
| FR-84 | **[GAP]** The Profile tab is **read-only**. A direct profile-edit screen for demographics, lifestyle, and wellbeing fields **shall** be added. | — |
| FR-85 | The system shall support free-text diary entries with date, optional mood, symptom tags, and body text. | `DiaryEntry`, `diary_entry_dialog.dart` |
| FR-86 | The user shall be able to delete their entire stored profile. | `DELETE /profile/<user_id>` |

### 5.11 Settings, Privacy, Content

| ID | Requirement | Implementation |
|---|---|---|
| FR-87 | The user shall be able to edit display name, cycle data, and privacy settings. | `settings_screen.dart` |
| FR-88 | Privacy settings shall include `aiMemoryEnabled` (whether prior turns are sent to the model) and `aiCanAccessDiary` (whether diary content may be used as context). | `PrivacySettings` |
| FR-89 | The system shall provide educational content on reproductive anatomy, hormones, and menstruation. | `learn_screen.dart` |
| FR-90 | The system shall provide dedicated endometriosis information. | `endo_screen.dart` |
| FR-91 | The system shall provide About and Terms screens. | `about_screen.dart`, `terms_screen.dart` |
| FR-92 | The system shall provide a data & privacy screen explaining what is stored and where. | `data_privacy_screen.dart` |
| FR-93 | The app shell shall present 8 tabs — Cycle, Ovu, Prot, PCOS, Endo, Learn, Set, Chat — via an `IndexedStack` preserving each tab's state across switches. | `home_shell.dart` |
| FR-94 | Tab content shall be constrained to a max width of **640 px** and centred, for readable layout on wide screens. | same |
| FR-95 | **[FIXED]** The tab content area shall be given an explicit bounded height via `LayoutBuilder` rather than relying on ambient constraints, which could silently collapse to zero height and render a blank screen with no error. | `home_shell.dart` |

---

## 6. Non-Functional Requirements

| ID | Requirement | Notes |
|---|---|---|
| NFR-01 | Passwords shall be hashed with bcrypt; passwords and reset codes shall never be stored or logged in plaintext. | `app_backend/auth.py` |
| NFR-02 | PCOS prediction shall return in under **1 second** once the request reaches the backend; model and scaler load at module import. | `app_backend/main.py` |
| NFR-03 | The AI check-in shall degrade gracefully with a safe fallback if Groq is unconfigured or unreachable. | `app_backend/chat.py::get_reply` |
| NFR-04 | Backend input shall be validated with specific 4xx errors rather than unhandled 500s. | `app_backend/main.py` |
| NFR-05 | The system shall run on Android, iOS, and web from a single Flutter codebase. | — |
| NFR-06 | The current backend shall run on a single instance with SQLite; a persistent/shared database is required before multi-instance production rollout. | `app_backend/database.py` |
| NFR-07 | No API keys or credentials shall be committed to version control. `.gitignore` shall exclude database files and the virtualenv. | `.gitignore` |
| NFR-08 | Chat requests shall time out client-side at **30 seconds**; profile requests at **8 seconds**. | `ai_service.dart`, `health_profile_service.dart` |
| NFR-09 | CORS shall allow only explicitly configured origins; credentials remain disabled. Production startup shall fail without explicit origins. | `app_backend/main.py`; `.env.example` |
| NFR-10 | Every mutating endpoint shall handle the CORS preflight `OPTIONS` method. | FastAPI `CORSMiddleware` |
| NFR-11 | The app shall function offline for cycle tracking and diary reading; cloud features degrade with clear messaging. | local-cache-first design |
| NFR-12 | SQLite connections shall be opened per request and closed in `finally` blocks. | `app_backend/database.py` |
| NFR-13 | Background sync failures shall be silent and non-blocking. | `_refreshFromBackendIfNewer` |

---

## 7. System Features (Screen Inventory)

| Screen | File | Purpose |
|---|---|---|
| Splash | `splash_screen.dart` | Session restore; routes to sign-in or home |
| Sign In | `sign_in_screen.dart` | Email/password authentication |
| Sign Up | `sign_up_screen.dart` | Account creation |
| Forgot Password | `forgot_password_screen.dart` | Password reset |
| Home Shell | `home_shell.dart` | 8-tab `IndexedStack` container + bottom nav |
| Home / Cycle | `home_screen.dart` | Cycle day, phase, calendar, logging |
| Cycle Data | `cycle_data_screen.dart` | Edit period start, cycle length, duration |
| Ovulation | `ovulation_screen.dart` | Fertile window and ovulation estimate |
| Protection | `protection_screen.dart` | Methods, effectiveness, eligibility tool, My Plan |
| PCOS | `pcos_screen.dart` | 22-field screening form and result |
| Endometriosis | `endo_screen.dart` | Educational content |
| Learn | `learn_screen.dart` | Anatomy, hormones, menstruation content |
| Settings | `settings_screen.dart` | Name, cycle, privacy, logout |
| AI Check-In | `ai_checkin_screen.dart` | Bilingual chat, voice, attachments, history |
| Health Diary | `health_diary_screen.dart` | Timeline + read-only profile |
| Data & Privacy | `data_privacy_screen.dart` | Storage disclosure |
| About | `about_screen.dart` | App info |
| Terms | `terms_screen.dart` | Terms of use |

**Reusable widgets:** `ai_suggestion_card`, `ai_welcome_card`, `app_text_field`, `diary_entry_dialog`, `gradient_card`, `month_calendar`, `pill_button`, `wellness_check_in_dialog`.
*(Housekeeping: `app_text_field (1).dart` is a duplicate file and should be deleted. `lib/services/auth_session.dart` is dead code — nothing imports it since the migration to direct SharedPreferences reads.)*

---

## 8. AI Safety Requirements

| ID | Requirement |
|---|---|
| AI-01 | The AI shall never issue a diagnosis, physical or mental. It shall never say "you have X" or "this means you have X." Permitted framing: "some of what you're describing is worth checking with the PCOS tool." |
| AI-02 | The AI shall never provide medication dosages, tell a user to start or stop a medication, or give treatment directives. It shall redirect to a healthcare provider. |
| AI-03 | On disclosure suggesting emotional distress, self-harm risk, or an unsafe situation (e.g. family violence), the AI shall remain calm and supportive, shall not attempt to solve it, and shall set `crisis_concern: true` so the app can surface real crisis resources — while continuing to engage supportively in text rather than going silent. |
| AI-04 | The AI provider shall be configurable via environment variable, never hardcoded. |
| AI-05 | The AI shall ask one question at a time and keep replies to 2–4 sentences. |
| AI-06 | The AI shall never make the user feel screened or judged; the register is a caring, knowledgeable friend. |
| AI-07 | The AI shall not claim to have seen an image it cannot process (see FR-65). |
| AI-08 | Deterministic crisis and physical-medical-emergency detection shall run before the model; model-reported safety flags shall also force the corresponding safe response. | `app_backend/chat.py` |
| AI-09 | A missing `GROQ_API_KEY` shall produce a user-facing fallback response, not a server error. | `app_backend/chat.py::FALLBACK_REPLY` |

---

## 9. Data Model Specification

### 9.1 `HealthProfile` (root document)
| Field | Type | Notes |
|---|---|---|
| `userId` | String | Account `user_id`, or device ID in local-only mode |
| `demographics` | Demographics | |
| `lifestyle` | Lifestyle | |
| `reproductiveHistory` | ReproductiveHistory | |
| `pcosHistory` | List\<PcosCheckResult\> | Append-only |
| `eligibilityHistory` | List\<EligibilityCheckResult\> | Append-only |
| `mentalHealth` | MentalHealthFlags | |
| `conversationLog` | List\<ConversationEntry\> | Append-only |
| `privacySettings` | PrivacySettings | |
| `diaryEntries` | List\<DiaryEntry\> | |
| `lastUpdated` | DateTime | Drives sync conflict resolution (FR-78) |

### 9.2 Sub-objects
| Class | Fields |
|---|---|
| `Demographics` | `ageYrs: int?`, `weightKg: double?`, `heightCm: double?`, `maritalStatus: String?` |
| `Lifestyle` | `regularExercise: bool?`, `exerciseFrequency: String?`, `dietQuality: String?`, `fastFoodFrequent: bool?`, `averageSleepHours: double?`, `notes: String?` |
| `ReproductiveHistory` | `cycleRegularity: String?` ('Regular'/'Irregular'), `cycleLengthDays: int?`, `currentContraceptionMethod: String?`, `contraceptionHistory: List<ContraceptionLogEntry>` |
| `ContraceptionLogEntry` | `date: DateTime`, `method: String`, `note: String?` |
| `PcosCheckResult` | `date: DateTime`, `prediction: String`, `pcosProbability: double`, `modelUsed: String` |
| `EligibilityResultEntry` | `methodLabel: String`, `category: int` |
| `EligibilityCheckResult` | `date: DateTime`, `conditions: List<String>`, `results: List<EligibilityResultEntry>` |
| `MentalHealthFlags` | `selfReportedStressLevel: int?` (1–5), `notes: String?`, `lastCheckIn: DateTime?` |
| `ConversationEntry` | `timestamp: DateTime`, `role: String` ('user'/'assistant'), `message: String`, `sessionId: String?` |
| `PrivacySettings` | `aiMemoryEnabled: bool`, `aiCanAccessDiary: bool` |
| `DiaryEntry` | `date: DateTime`, `mood: String?`, `symptomTags: List<String>`, `text: String` |
| `CycleData` | `lastPeriodStart: DateTime`, `cycleLength: int` (default 28), `periodDuration: int` (default 5) |
| `DailyLog` | `isPeriodDay: bool`, `mood: String?`, `symptoms: List<String>`, `flowIntensity: String?` |

**Design note:** every sub-object implements `copyWith`, `toJson`, and `fromJson`. All `copyWith` methods use `value ?? this.value`, which means **a field cannot be set back to null via copyWith** — a known constraint to be aware of when implementing profile editing (FR-84).

---

## 10. Database Requirements

The current FastAPI backend uses one SQLite database, `app_backend/wellness_saheli.db` by default. `DATABASE_PATH` may override the path for a persistent deployment volume.

| ID | Requirement | Status |
|---|---|---|
| DB-01 | Tables shall be created on import via `CREATE TABLE IF NOT EXISTS`. | ✅ |
| DB-02 | Users, hashed sessions, password-reset tokens, and profiles shall use separate tables in the same database. | ✅ |
| DB-03 | Health profiles shall be stored as a single JSON document per `user_id`. | ✅ |
| DB-04 | Session bearer tokens shall be stored only as SHA-256 hashes, not plaintext bearer values. | ✅ |
| DB-05 | Session and reset-token expiry shall be compared using parsed timestamps, not lexical string ordering. | ✅ |
| DB-06 | Password-reset codes shall be stored only as bcrypt hashes, expire after 15 minutes, and be deleted after success or exhaustion. | ✅ |
| DB-07 | SQLite is the current engine. PostgreSQL/shared storage is required before multi-instance production deployment. | ⚠️ |

---

## 11. Security Requirements

| ID | Requirement | Status |
|---|---|---|
| SEC-01 | Passwords are hashed with bcrypt. | ✅ |
| SEC-02 | Sign-in returns an identical error for unknown email and wrong password. | ✅ |
| SEC-03 | Password-reset requests return an identical generic response regardless of email existence. | ✅ |
| SEC-04 | No secrets or database files are committed to git. | ✅ |
| SEC-05 | `/profile/<user_id>` GET, PUT, and DELETE require a valid Bearer token and enforce URL ownership. | ✅ |
| SEC-06 | `/chat` requires authentication and is rate limited. | ✅ |
| SEC-07 | Sessions expire after 30 days and are individually invalidatable. | ✅ |
| SEC-08 | Successful password reset revokes all sessions for the account. | ✅ |
| SEC-09 | Signup, signin, reset request, and reset confirmation are rate limited. | ✅ |
| SEC-10 | Prediction errors do not leak model/library internals. | ✅ |
| SEC-11 | Profile, chat context, message, history, and attachment sizes are bounded. | ✅ |
| SEC-12 | Password reset uses an emailed one-time code in production; SMTP delivery still requires live credentials and verification. | ⚠️ |
| SEC-13 | Rate limiting is in-process and does not share state across workers/instances. | ⚠️ |
| SEC-14 | `/predict` and public reference/eligibility endpoints are unauthenticated; prediction remains publicly consumable. | ⚠️ |
| SEC-15 | Attachments use MIME allowlisting, decoded-size limits, and content-signature checks, but no antivirus scanning. | ⚠️ |
| SEC-16 | Health disclosures may be transmitted to Groq; provider terms, consent, retention, and the privacy screen require deployment review. | ⚠️ |
| SEC-17 | Flutter bearer tokens currently use SharedPreferences; migrate to platform secure storage before handling real health data. | ⚠️ |


---

## 12. Hardware Requirements
- **Client:** any Android or iOS device, or a modern browser (Chromium-based recommended — voice input depends on the Web Speech API, unavailable in some browsers).
- **Server:** any host running Python 3.10+ with Uvicorn; Railway/Render is the current deployment target.

---

## 13. Software Requirements

### 13.1 Frontend
Flutter SDK (stable), Dart. Packages: `provider ^6.1.5+1`, `shared_preferences ^2.5.5`, `google_fonts ^8.1.0`, `http ^1.1.0`, `speech_to_text ^7.0.0`, `file_picker ^8.1.2`.

### 13.2 Backend
Python 3.10+ (current local verification uses Python 3.14), FastAPI ≥0.115, Uvicorn, `bcrypt`, `python-dotenv`, `groq` ≥0.11, `scikit-learn`, `joblib`, `numpy`, `pypdf`, `python-docx`, and SQLite.

### 13.3 Deployment topology
ASGI entry point → `app_backend.main:app`, started by `uvicorn app_backend.main:app --host 0.0.0.0 --port $PORT` through `Procfile`. Railway/Render must provide `APP_ENV`, `CORS_ORIGINS`, `FORCE_HTTPS`, `GROQ_API_KEY`, and SMTP variables through their secret/environment stores. The model artifacts must be included in the deployed image.

**Deployment hazard:** SQLite data is not durable on an ephemeral host. Configure a persistent volume or migrate to PostgreSQL before relying on production account/profile data.

---

## 14. Constraints
1. The current deployment target is a single FastAPI instance backed by SQLite; persistent storage and shared rate limiting are required before multi-instance rollout.
2. Groq usage is rate-limited by the provider; live credentials and provider terms must be reviewed before production health-data processing.
3. The current Groq model is text-only; image understanding is not implemented.
4. Voice input on web depends on the browser's Web Speech API and is unavailable in some browsers.
5. `copyWith` cannot null out a field (see §9.2 note).

---

## 15. Assumptions
1. Users are literate in English or Urdu.
2. Users have internet access for prediction, chat, eligibility, and sync; cycle tracking and diary reading work offline.
3. Users understand this is a screening and information tool, not a clinician.
4. Lab values entered into the PCOS form come from an actual lab report — the app cannot validate them.

---

## 16. Out of Scope
- Clinical diagnosis of any condition.
- Telemedicine or direct provider consultation.
- Payment processing.
- Languages beyond English and Urdu.
- Admin or clinician dashboards.
- Data export (no CSV/PDF export exists).
- Push notifications (the reminders toggle stores a preference but no notification system is wired up).
- Wearable or health-platform integration.

---

## 17. Acceptance Criteria

| ID | Traces to | Criterion |
|---|---|---|
| AC-01 | FR-01, FR-02 | A user can register and subsequently sign in with the same credentials, receiving a token both times. |
| AC-02 | FR-01b | Registering an existing email returns 409, not a duplicate account. |
| AC-03 | FR-02a | Nine consecutive failed sign-ins from one client for one email return 429. |
| AC-04 | FR-03b | After a successful password reset, a previously issued token is rejected. |
| AC-05 | FR-17 | Submitting a valid 22-field form returns a prediction label, a probability in [0,1] to 4dp, and the persisted model name `NaiveBayes`. |
| AC-06 | FR-17f | Omitting `prl` returns 422 naming `prl`. Sending `cycle_regularity: "Maybe"` returns 422 naming the field and the value. |
| AC-07 | FR-17b | Two requests with identical inputs except height produce different results, confirming BMI derivation is live. |
| AC-08 | FR-26 | Submitting selected conditions returns a category 1–4 for each of the 10 modeled methods when classified. |
| AC-09 | FR-26a | Selecting `smoking_age35_lt15` and `migraine_with_aura` returns the most restrictive combined category for combined hormonal contraceptives. |
| AC-10 | FR-27 | Submitting an unknown condition ID returns 422 naming it. |
| AC-11 | FR-72, FR-75 | Data saved via PUT is retrievable via GET for the same `user_id`; a user with no profile gets 404 and the app still opens. |
| AC-12 | SEC-05 | User A's token used against `/profile/<user_B_id>` returns 403 for GET, PUT, and DELETE. |
| AC-13 | FR-78 | With a fresher local profile and a stale server copy, reopening the Diary preserves the local data. |
| AC-14 | FR-45 | With the toggle on اردو, sending "hello how are you" in English produces an **Urdu** reply. |
| AC-15 | FR-43 | The language choice survives a full app restart. |
| AC-16 | FR-62 | Attaching a text-bearing PDF results in a reply that references its actual contents. |
| AC-17 | FR-65 | Attaching a photo produces an acknowledgement asking for a description — never a fabricated reading of the image. |
| AC-18 | FR-58 | A file larger than 8 MB is rejected by name before any network call. |
| AC-19 | FR-68, FR-69 | Enter sends; Shift+Enter inserts a newline. |
| AC-20 | FR-36 | A turn that triggers `record_checkin_insights` still renders a non-empty assistant bubble. |
| AC-21 | AI-03 | A message containing crisis-indicating language returns `crisis_concern: true` and surfaces crisis resources; a physical-emergency message returns the separate medical-emergency flag and response. |
| AC-22 | FR-21 | After running a PCOS check, the Diary's Profile tab shows the entered age, weight, height, and reproductive inputs. |
| AC-23 | FR-93 | Switching tabs and returning preserves each tab's scroll position and form state. |
| AC-24 | NFR-02 | `/predict` responds in under 1 second measured server-side. |

---

## 18. Known Defects and Required Work

Ordered by priority. This is the actionable backlog after Phase 1.

### P1 — Data and privacy correctness
1. **FR-84** — The profile tab remains read-only; add direct editing for demographics, lifestyle, and wellbeing fields, accounting for the `copyWith` null constraint in §9.2.
2. **FR-23/FR-26** — Restore the full verified WHO MEC dataset after sourcing and reviewing the official matrix; do not invent ratings.
3. **SEC-17** — Move bearer tokens from SharedPreferences to platform secure storage before real health-data deployment.
4. **SEC-16** — Complete provider/privacy review and update the data/privacy screen for Groq processing, retention, consent, and deletion behavior.

### P2 — Deployment and reliability
5. Configure Railway/Render secrets and variables, persistent storage, SMTP, and the live `GROQ_API_KEY`; verify live email and AI behavior.
6. Replace in-process rate limiting with Redis or another shared store before running multiple workers/instances.
7. Resolve the scikit-learn model-version warning by deploying a compatible runtime or retraining/exporting the model artifact.
8. Add automated backend tests for attachment extraction, reset expiry/attempt limits, CORS/HTTPS behavior, and session invalidation.

### P3 — Feature completion and cleanup
9. Replace the removed `predict_explain.py` functionality with a supported explanation flow, or explicitly remove that requirement from the product scope.
10. Build releases with `--dart-define=API_BASE_URL=<Railway/Render URL>`; the local default is an Android-emulator address and must be overridden for web/iOS/device deployments.
11. Replace deprecated Flutter `withOpacity` calls with `withValues(alpha:)` where applicable.
12. Add real image understanding, broader Urdu localization, push notifications, and data export only after the core security and deployment work is complete.

---

## 19. Traceability Summary

| Objective | Functional requirements | Acceptance criteria |
|---|---|---|
| OBJ-01 Cycle tracking | FR-08 … FR-16 | AC-23 |
| OBJ-02 PCOS screening | FR-17 … FR-22 | AC-05, AC-06, AC-07, AC-22, AC-24 |
| OBJ-03 Contraceptive guidance | FR-23 … FR-29 | AC-08, AC-09, AC-10 |
| OBJ-04 AI check-in | FR-30 … FR-41, AI-01 … AI-09 | AC-20, AC-21 |
| OBJ-05 Unified diary | FR-72 … FR-86 | AC-11, AC-12, AC-13 |
| OBJ-06 Urdu support | FR-42 … FR-48 | AC-14, AC-15 |
| OBJ-07 Attachments | FR-49 … FR-71 | AC-16, AC-17, AC-18, AC-19 |
| Auth & security | FR-01 … FR-07, SEC-01 … SEC-17 | AC-01 … AC-04, AC-12 |
