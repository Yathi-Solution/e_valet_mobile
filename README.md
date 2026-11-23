# ValetLink E-Valet (Mobile App)

A **Flutter mobile app** for running valet parking at an outlet. Valets park and retrieve cars, operators run the floor from a dashboard, and scanner staff raise retrieval requests by scanning a customer's card. One account can belong to several clients and outlets; the user picks which one to work at when logging in.

> **This README keeps itself up to date.** The sections marked *auto-generated* are rewritten from the code on every commit by [tool/update_readme.dart](tool/update_readme.dart). See [Keeping this README up to date](#keeping-this-readme-up-to-date).

## At a glance

*Auto-generated.*

<!-- AUTO:overview:START -->
|  |  |
|---|---|
| Package | `evalet` |
| Version | `1.0.0` |
| Dart SDK | `^3.6.1` |
| Screens | 30 |
| BLoCs / cubits | 30 |
| API service files | 49 |
| Model files | 100 |
| Service files | 39 |
| Dart files in `lib/` | 469 |
<!-- AUTO:overview:END -->

---

## Who uses it

After login the app opens the home screen that matches the account's role. The role is checked in this order:

| Role | Home screen | What they do |
|------|-------------|--------------|
| **Scanner** | Scanner Home | Scans a customer's WhatsApp card QR to raise a retrieval request, and sees the list of retrieval requests. |
| **Operator** (or admin) | Operator Dashboard | Watches KPIs and retrieval requests, assigns valets, manages valets, cards, groups and overtime. |
| **Driver** (valet) | Driver Home | Clocks in, parks cars, brings them back and hands them over. |

An account with none of these roles is refused with a message to contact the administrator.

---

## Login and start-up

1. **Splash** → if a session is saved the app goes straight to the right home screen; otherwise it shows **Login**.
2. **Login** with phone number and password. **Forgot password** uses an OTP.
3. **Client and outlet selection** – one dialog. If the account has several clients, pick the client, then pick the outlet. The role is shown next to each outlet.
4. **Location check** – the app verifies the user is at the outlet. If they are too far away, a full-screen "too far" page offers **Retry** (fresh GPS reading) without logging out.
5. **Version check** – if the server reports a newer mandatory build, an update dialog blocks the app.
6. **Permissions** – camera, location and notifications are requested.

If the same account logs in on another device, the session here is ended and the user is sent back to login.

---

## Driver flow

### Home screen

- **Go online / offline** (clock in and clock out) and **take a break**. Before a break the app shows the driver's break information.
- Clock-in is refused when the driver is too far from the outlet.
- The overflow menu has **Profile**, **Help**, **Guidelines**, **Cards** and **Logout**.

### 1. Park a car

1. Tap **Park car**.
2. **Scan the QR** on the valet card, or type the card number by hand.
3. A card that belongs to a different outlet is refused, even when offline.
4. Collect the car, drive it to the parking area and take a **car photo**. The photo is checked on the device (image labelling) and compressed before upload.
5. Preview the photo and submit → **car parked successfully** → back to home.

### 2. Retrieval request

- When a retrieval is assigned to the driver, a **bottom sheet** with the car details appears on the home screen, with a countdown.
- The driver gets a **push notification** even when the app is closed, and the message is **read aloud**.
- Tap **Collect keys** to accept, or **pass the request** to another available driver.
- Pending requests are also listed on their own screen.

### 3. Confirm arrival and handover

- At the gate, slide **Confirm arrival** → the customer is told on **WhatsApp** that the car has arrived.
- When the customer comes, hand over the keys and confirm **Handover** → the session is complete.
- The Confirm arrival, Customer missing and Handover buttons stay disabled for a short cooldown (set in `.env`).

### 4. Customer missing → re-park

- If the customer does not come, tap **Customer Missing**, take the car back, take a new photo and **re-park**. The retrieval is cancelled and the car can be requested again later.

### Other driver screens

- **My parked cars** – the cars this driver parked.
- **My cards** – the physical card numbers assigned to this driver, with **Sync cards** to refresh them.

### Working offline

- A park done without internet is saved on the phone (Hive) and sent to the server when the connection returns, including by a background job when the app is closed.
- A banner shows when the phone is offline.
- Internet on/off changes during a shift are logged and sent to the server in batches.

---

## Operator flow

### The two cards

For each car there are **two physical cards** with the same card number:

- The **customer card** has a WhatsApp QR. The customer scans it to chat with the ValetLink WhatsApp number; the QR carries the outlet code and card number.
- The **valet card** stays with the parking team. The valet scans it in the app when parking.

### How a retrieval is requested

- The customer sends a message in WhatsApp asking for their car, **or**
- scanner staff scan the customer's card, **or**
- the operator raises a **manual request** for a card number.

The request appears on the operator dashboard with the card number and a **sound alert** plays.

### Dashboard

- **KPIs** for the outlet and the list of **retrieval requests**.
- **Available drivers** – assign a valet to a request, or cancel an assignment.
- **Auto-assign** – when switched on, the server assigns valets itself and manual requests are disabled.

### Side drawer

| Menu | What it shows |
|------|---------------|
| **Dashboard** | KPIs, retrieval requests, available drivers. |
| **Parked car** | Digital key rack: every car currently parked. |
| **Valets** | Valet list with status, per-valet KPIs, details, and remote logout of a valet. **Add Driver** invites a new driver by phone number (name, optional email, one or more of the client's outlets); a failed invitation delivery can be resent. |
| **Car logs** | Sortable, paged table of every session with KPIs and a details popup; a session's status can be updated. |
| **Cards** | Which physical card numbers each driver may use. |
| **Drivers group** | Create groups of valets and add members. |
| **Overtime** | Grant overtime to a valet. |
| **Profile / Help / Guidelines / Logout** | Account, support contacts, operator responsibilities. |

---

## Scanner flow

- The home screen lists retrieval requests and updates live.
- Tap scan, point at the customer's WhatsApp card QR → the app reads the card number and raises a retrieval request.
- The menu has only **Profile** and **Logout**.

---

## App-wide features

- **Languages** – the app's text is translated; languages and translations come from the server and are cached. The language can be changed from the app bar.
- **Push notifications** (Firebase Cloud Messaging) with local notifications, sound, vibration and text-to-speech.
- **Real-time updates** over Socket.IO, reconnecting when the app comes back to the foreground.
- **Help & support** contacts and role-specific **guidelines**.
- **Profile** with change password.

---

## Tech stack

- **Flutter** (Dart) – UI and app logic
- **flutter_bloc** – state management (with `provider` for a few app-wide objects)
- **Dio** – HTTP API calls, with a token interceptor that refreshes the session
- **Hive** – local storage (tokens, offline parks, caches)
- **Firebase Messaging** – push notifications
- **socket_io_client** – real-time events
- **workmanager** – background sync
- **mobile_scanner**, **camera**, **Google ML Kit** – QR scanning and car photos
- **flutter_dotenv** – configuration from `.env`

### Dependencies

*Auto-generated from `pubspec.yaml`.*

<!-- AUTO:dependencies:START -->
| Package | Version |
|---|---|
| `audioplayers` | `^6.6.0` |
| `camera` | `^0.11.0+1` |
| `connectivity_plus` | `^7.0.0` |
| `cupertino_icons` | `^1.0.8` |
| `device_info_plus` | `^11.3.0` |
| `dio` | `^5.9.0` |
| `dropdown_button2` | `^2.3.9` |
| `equatable` | `^2.0.7` |
| `firebase_core` | `^4.3.0` |
| `firebase_messaging` | `^16.1.0` |
| `flutter` | `sdk: flutter` |
| `flutter_bloc` | `^9.1.1` |
| `flutter_dotenv` | `^6.0.0` |
| `flutter_image_compress` | `^2.1.0` |
| `flutter_local_notifications` | `^19.5.0` |
| `flutter_phone_direct_caller` | `^2.1.1` |
| `flutter_svg` | `^2.0.10+1` |
| `flutter_tts` | `^4.2.0` |
| `geolocator` | `13.0.4` |
| `google_fonts` | `^6.3.0` |
| `google_mlkit_image_labeling` | `0.14.1` |
| `google_mlkit_text_recognition` | `0.15.0` |
| `hive_flutter` | `^1.1.0` |
| `intl` | `^0.19.0` |
| `intl_phone_field` | `^3.2.0` |
| `lottie` | `^3.3.1` |
| `mobile_scanner` | `^6.0.11` |
| `package_info_plus` | `^8.1.2` |
| `path_provider` | `^2.1.2` |
| `permission_handler` | `^12.0.1` |
| `pinput` | `^5.0.0` |
| `provider` | `^6.1.2` |
| `pull_down_button` | `^0.10.2` |
| `slide_to_act` | `^2.0.2` |
| `socket_io_client` | `^2.0.3+1` |
| `url_launcher` | `^6.3.0` |
| `vibration` | `^2.0.0` |
| `workmanager` | `0.7.0` |

**Dev dependencies**

| Package | Version |
|---|---|
| `flutter_launcher_icons` | `^0.13.1` |
| `flutter_lints` | `^5.0.0` |
| `flutter_test` | `sdk: flutter` |
<!-- AUTO:dependencies:END -->

---

## Project structure

*Auto-generated.*

<!-- AUTO:structure:START -->
```
lib/
├── main.dart
├── api/  (49 files)
│   ├── core/  (4 files)
│   ├── driver/  (18 files)
│   ├── notification/  (1 file)
│   ├── oauth/  (5 files)
│   ├── ope_driv_help_support_api/  (1 file)
│   ├── operator/  (17 files)
│   ├── outlet/  (1 file)
│   └── translations/  (2 files)
├── bloc/  (89 files)
│   ├── connectivity/  (3 files)
│   ├── driver/  (30 files)
│   ├── oauth/  (14 files)
│   ├── operator/  (21 files)
│   ├── qr/  (3 files)
│   ├── retrival_request/  (3 files)
│   ├── scanner/  (9 files)
│   ├── splash/  (3 files)
│   └── websocket/  (3 files)
├── models/  (100 files)
│   ├── core/  (1 file)
│   ├── driver/  (40 files)
│   ├── help_support/  (1 file)
│   ├── notification/  (6 files)
│   ├── oauth/  (8 files)
│   ├── operator/  (39 files)
│   ├── outlet/  (3 files)
│   └── translations/  (2 files)
├── services/  (39 files)
│   ├── background/  (1 file)
│   ├── connectivity/  (1 file)
│   ├── device/  (1 file)
│   ├── driver/  (3 files)
│   ├── image/  (1 file)
│   ├── location/  (1 file)
│   ├── notification/  (4 files)
│   ├── oauth/  (4 files)
│   ├── offline_sync/  (2 files)
│   ├── operator/  (1 file)
│   ├── permissions/  (1 file)
│   ├── qr/  (1 file)
│   ├── storage/  (11 files)
│   ├── translations/  (3 files)
│   ├── version/  (1 file)
│   └── websocket/  (2 files)
├── ui/  (181 files)
│   ├── common/  (34 files)
│   ├── driver/  (62 files)
│   ├── guidelines/  (3 files)
│   ├── help_support/  (2 files)
│   ├── oauth/  (13 files)
│   ├── operator/  (60 files)
│   ├── permissions/  (1 file)
│   ├── scanner/  (3 files)
│   └── version/  (3 files)
└── utils/  (10 files)
```
<!-- AUTO:structure:END -->

| Folder | What lives there |
|--------|------------------|
| `api/` | One service per backend endpoint group. |
| `bloc/` | State management, one folder per feature (`*_bloc`, `*_event`, `*_state`). |
| `models/` | Request and response models. |
| `services/` | Things that outlive a screen: session, notifications, offline sync, location, WebSocket, translations. `services/storage/` holds one small store per kind of locally saved data (tokens, user, outlet, parking session, cooldowns, driver cards and so on), all sharing one Hive box. `TokenStorage` is the older single entry point and now only forwards to these stores; new code should call the store directly. |
| `ui/` | Screens and widgets, grouped by role, plus `common/` shared widgets, colours and text. |
| `utils/` | Small helpers (QR parsing, time, FIFO ordering of sessions). |

### What is in each area

*Auto-generated.*

<!-- AUTO:inventory:START -->
**Screens** (`lib/ui`)

| Area | Screens |
|---|---|
| `driver` (11) | `car_camera_screen`, `car_details_screen`, `car_photo_intro_screen`, `clock_in_too_far_screen`, `confirm_arrival_screen`, `driver_home`, `driver_vehicle_details_screen`, `my_cards_screen`, `my_parked_cars_screen`, `pending_retrieval_requests_screen`, `preview_Car_Screen` |
| `guidelines` (1) | `guidelines_screen` |
| `help_support` (1) | `help_screen` |
| `oauth` (5) | `forgot_password_screen`, `login`, `login_outlet_too_far_page`, `profile_screen`, `splash` |
| `operator` (9) | `operator_car_logs_screen`, `operator_cards_screen`, `operator_dashboard`, `operator_drivers_screen`, `operator_group_members_screen`, `operator_grouping_screen`, `operator_home`, `operator_overtime_screen`, `operator_parked_car_screen` |
| `permissions` (1) | `permissions_screen` |
| `scanner` (1) | `scanner_home` |
| `version` (1) | `version_check_screen` |

**BLoCs / cubits** (`lib/bloc`)

| Area | BLoCs |
|---|---|
| `connectivity` (1) | `connectivity_bloc` |
| `driver` (10) | `assigned_sessions_background_bloc`, `car_Camer_bloc`, `confirm_arrival_bloc`, `confirm_handover_bloc`, `driver_menu_bloc`, `driver_status_bloc`, `initiate_repark_bloc`, `pass_available_drivers_bloc`, `preview_car_bloc`, `tag_submission_bloc` |
| `oauth` (5) | `change_password_bloc`, `forgot_password_bloc`, `login_bloc`, `outlet_location_retry_cubit`, `profile_bloc` |
| `operator` (7) | `car_logs_bloc`, `operator_cards_bloc`, `operator_dashboard_bloc`, `operator_menu_bloc`, `operator_overtime_bloc`, `valet_kpis_bloc`, `valet_list_bloc` |
| `qr` (1) | `qr_bloc` |
| `retrival_request` (1) | `retrival_request_bloc` |
| `scanner` (3) | `scanner_menu_bloc`, `scanner_qr_bloc`, `scanner_retrieval_bloc` |
| `splash` (1) | `splash_bloc` |
| `websocket` (1) | `websocket_bloc` |

**API services** (`lib/api`)

| Area | Files |
|---|---|
| `core` (4) | `api_config`, `app_version_api_service`, `base_dio_service`, `base_http_service` |
| `driver` (18) | `arrived_api`, `assigned_sessions_api_service`, `config_api_service`, `connectivity_log_api_service`, `connectivity_settings_api_service`, `driver_status_api_service`, `handover_api`, `image_API`, `initiate_repark_api_service`, `my_cards_api_service`, `my_parked_sessions_api_service`, `pass_available_drivers_api_service`, `pass_parked_sessions_api_service`, `pre_break_info_api_service`, `re-park_api`, `retrival_accept_api`, `session_api_service`, `sessions_pending_api` |
| `notification` (1) | `notification_api_service` |
| `oauth` (5) | `login_api_service`, `logout_api_service`, `otp_api_service`, `password_api_service`, `profile_api_service` |
| `ope_driv_help_support_api` (1) | `help_support_api` |
| `operator` (17) | `card_assignments_api_service`, `grant_overtime_api_service`, `operator_add_driver_api_service`, `operator_assign_retrieval_api_service`, `operator_auto_assign_api_service`, `operator_available_drivers_api_service`, `operator_cancel_assignment_api_service`, `operator_car_logs_api_service`, `operator_dashboard_api_service`, `operator_digital_key_rack_api_service`, `operator_driver_groups_api_service`, `operator_manual_retrieval_api_service`, `operator_retrieval_requests_api_service`, `operator_update_session_api_service`, `valet_kpis_api_service`, `valet_list_api_service`, `valet_logout_api_service` |
| `outlet` (1) | `outlet_api_service` |
| `translations` (2) | `language_api_service`, `translations_api_service` |

**Services** (`lib/services`)

| Area | Files |
|---|---|
| `background` (1) | `background_sync_service` |
| `connectivity` (1) | `driver_connectivity_log_service` |
| `device` (1) | `device_info_service` |
| `driver` (3) | `customer_missing_service`, `repark_service`, `retrieval_override_service` |
| `image` (1) | `image_compression_service` |
| `location` (1) | `location_service` |
| `notification` (4) | `firebase_messaging_service`, `local_notification_service`, `notification_service`, `text_to_speech_service` |
| `oauth` (4) | `logout_progress`, `session_events`, `session_manager`, `token_interceptor` |
| `offline_sync` (2) | `offline_parking_service`, `parked_card_availability_service` |
| `operator` (1) | `driver_groups_repository` |
| `permissions` (1) | `permissions_service` |
| `qr` (1) | `valet_qr_scanner_controller_factory` |
| `storage` (11) | `app_config_storage`, `auth_box`, `auth_storage`, `connectivity_log_storage`, `cooldown_storage`, `driver_cards_storage`, `location_storage`, `outlet_storage`, `parking_session_storage`, `retrieval_flow_storage`, `user_storage` |
| `translations` (3) | `app_translations_notifier`, `language_cache`, `translations_cache` |
| `version` (1) | `version_service` |
| `websocket` (2) | `websocket_helper`, `websocket_service` |
<!-- AUTO:inventory:END -->

---

## How to run

### 1. Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) matching the Dart SDK version in [At a glance](#at-a-glance)
- Android Studio or Xcode, with a device or emulator
- Firebase config files for the platform you build (`google-services.json` / `GoogleService-Info.plist`)

### 2. Environment

Create a `.env` file at the project root with the variables listed under [Configuration](#configuration-env). `.env` is git-ignored; never commit real URLs or keys.

### 3. Install and run

```bash
flutter pub get
flutter run
```

Use `flutter run -d <device_id>` to pick a device. For a release build: `flutter build apk` or `flutter build ios`.

### 4. Turn on the README hook (once per clone)

```bash
git config core.hooksPath .githooks
```

On macOS or Linux also run `chmod +x .githooks/pre-commit`.

---

## Configuration (.env)

*Auto-generated: every variable the code reads.*

<!-- AUTO:env:START -->
| Variable | Read in |
|---|---|
| `API_BASE_URL` | `lib/api/core/api_config.dart` |
| `APP_NAME` | `lib/main.dart` |
| `CONFIRM_ARRIVAL_DISABLE_SECONDS` | `lib/ui/driver/confirm_arrival/confirm_arrival_screen.dart` |
| `CONFIRM_HANDOVER_DISABLE_SECONDS` | `lib/ui/driver/confirm_arrival/confirm_arrival_screen.dart` |
| `CUSTOMER_MISSING_DISABLE_SECONDS` | `lib/ui/driver/confirm_arrival/confirm_arrival_screen.dart` |
| `OUTLET_ID` | `lib/api/core/api_config.dart` and 24 more files |
| `WEBSOCKET_BASE_URL` | `lib/api/core/api_config.dart` |
<!-- AUTO:env:END -->

What they mean:

- `APP_NAME` – app title (defaults to `ValetLink`)
- `API_BASE_URL` – backend API base URL
- `WEBSOCKET_BASE_URL` – real-time server URL
- `OUTLET_ID` – optional fixed outlet id sent with API calls
- `CONFIRM_ARRIVAL_DISABLE_SECONDS`, `CUSTOMER_MISSING_DISABLE_SECONDS`, `CONFIRM_HANDOVER_DISABLE_SECONDS` – button cooldowns in seconds

Switch between UAT and production by changing the `*_BASE_URL` values.

---

## Assets and tests

*Auto-generated.*

<!-- AUTO:assets_tests:START -->
**Assets**

| Folder | Files |
|---|---|
| `assets/images/` | 19 |
| `assets/jsons/` | 4 |
| `assets/sounds/` | 2 |
| `assets/svg/` | 3 |

**Tests** (`flutter test`)

- `test/driver_flow_resolver_test.dart`
- `test/whatsapp_qr_parser_test.dart`
- `test/widget_test.dart`
<!-- AUTO:assets_tests:END -->

---

## CI

[.github/workflows/flutter-build.yml](.github/workflows/flutter-build.yml) runs on pull requests to `main` and `dev`:

- Commit messages must look like `feat: ...`, `fix: ...`, `docs: ...`, `style: ...`, `refactor: ...`, `test: ...` or `chore: ...`
- `flutter analyze`
- `dart format --set-exit-if-changed .`

---

## Keeping this README up to date

The README has two kinds of content:

1. **Auto-generated sections** – version, counts, folder tree, screens, BLoCs, API services, dependencies, `.env` variables, assets and tests. They sit between `<!-- AUTO:name:START -->` and `<!-- AUTO:name:END -->` markers. Do not edit them by hand; they are overwritten.
2. **Written sections** – the flows and explanations. These are edited by hand when behaviour changes.

How the automatic part works:

- [tool/update_readme.dart](tool/update_readme.dart) reads `pubspec.yaml`, `lib/`, `assets/` and `test/` and rewrites the auto-generated sections.
- [.githooks/pre-commit](.githooks/pre-commit) runs that script on every commit and adds the refreshed `README.md` to the commit.

```bash
dart tool/update_readme.dart          # refresh now
dart tool/update_readme.dart --check  # exit 1 if the README is stale
```

To add a new auto-generated section, add a marker pair to this file and a matching entry in the `sections` map of the script.
