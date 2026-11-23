# JejakJamban

JejakJamban is a Flutter app, in Indonesian, for privately tracking bowel movement patterns (Bristol stool chart). Per the deployment assignment's instructions, the architecture is **Flutter -> Laravel REST API -> database** (not Supabase). Local notes use encrypted SQLite on Android/iOS; when a user is signed in, a sync queue sends entries to the Laravel API with a bearer token.

[Bahasa Indonesia](README.id.md)

> **Status note:** the source, local API, migrations, CRUD, validation and automated tests are all in place, and the source is pushed to [this repository](https://github.com/Ghivee/JejakJamban-app). The backend **has not been deployed to the internet** because no hosting has been set up yet. There is no production URL, no deployment/Postman/database screenshots and no demo video yet; do not treat any example URL as a live one.

JejakJamban is not a diagnostic tool and does not replace advice from a health professional. It has no feature for uploading photos of stool. Health logs are never shown on a leaderboard or shared socially.

## Structure

```text
lib/
  app/                    go_router routing and the 5-tab shell
  core/
    config/               API_BASE_URL and release-build validation
    domain/               XP, streak, Trail Score and red-flag rules
    network/              Laravel JSON client and secure token storage
    storage/              SQLCipher/outbox, local data, web demo mode
    theme/                SRS Material 3 tokens
  features/
    auth/                 login, registration, consent
    home/                 summary, check-in, hydration
    insight/               Bristol distribution and informational warnings
    log/                   quick/full logging, history, CRUD, sync
    league/                privacy info / Trail Score
    map/                   map coverage status
backend/
  app/                    models, request validation, controllers, resources
  database/               migrations, synthetic seeder
  routes/api.php           authenticated JSON API
  tests/                   Laravel feature tests
  infinityfree/            SQL schema and rewrite rules for FTP upload
  scripts/                 InfinityFree production packaging scripts
docs/
  PLAN.md
  CHANGELOG-KONFLIK.md
  LAPORAN-DEPLOYMENT.md    deployment report draft and evidence checklist
  DEPLOY-INFINITYFREE.md   InfinityFree hosting guide
  JejakJamban.postman_collection.json
```

## Local requirements

- Flutter stable and Dart 3 (this workspace is tested with Flutter 3.44.1 / Dart 3.12.1).
- PHP 8.3+ with `curl`, `fileinfo`, `mbstring`, `openssl`, `pdo_sqlite`, `sqlite3` and `zip`.
- Composer 2, Git, and the Android SDK for building the APK.
- An Android emulator or device for mobile use. iOS builds need macOS/Xcode.

## Running the Laravel backend

In PowerShell:

```powershell
Set-Location backend
Copy-Item .env.example .env
composer install
php artisan key:generate
if (-not (Test-Path database\database.sqlite)) { New-Item -ItemType File -Path database\database.sqlite | Out-Null }
# Set JEJAKJAMBAN_DEMO_PASSWORD in backend/.env (at least 12 characters)
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

The seeder creates the account **`demo@jejakjamban.local`** with three synthetic entries. The password comes from `JEJAKJAMBAN_DEMO_PASSWORD` in `.env`; the seeder refuses to run when `APP_ENV=production`. Never use the demo password as a production credential.

Main local endpoints:

| Method | Endpoint | Needs a token |
| --- | --- | --- |
| POST | `/api/register` | No |
| POST | `/api/login` | No |
| GET | `/api/me` | Yes |
| GET | `/api/logs` | Yes |
| GET | `/api/logs/{id}` | Yes |
| POST | `/api/logs` | Yes |
| PUT/PATCH | `/api/logs/{id}` | Yes |
| DELETE | `/api/logs/{id}` | Yes |

Login returns a Sanctum token. Send `Authorization: Bearer <token>` and `Accept: application/json` on every log route. Validation responses use HTTP 422; a resource the user does not own returns 404. `client_id` makes POST idempotent for offline queue retries. Logs are soft-deleted and can only be removed up to 30 days back.

A Postman collection is available at [`docs/JejakJamban.postman_collection.json`](./docs/JejakJamban.postman_collection.json). Set `baseUrl`, the demo email and password in the collection variables, then run the Login request first to store the token.

## Running Flutter

```powershell
flutter pub get
# local Android emulator; the Laravel server must be running on port 8000
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

A debug APK from a local build is at `build/app/outputs/flutter-apk/app-debug.apk`. That is a development artifact, not a production APK: rebuild it with the correct API URL for a demo on another device or server.

For a physical device, use the computer's LAN address in debug builds. A release build **rejects** any non-HTTPS, non-localhost URL:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-active-url/api
```

`.env.example` shows the shape of `API_BASE_URL`, but the Flutter app reads it through `--dart-define`; it never loads `.env` at runtime. Never commit a production URL, token or credential to source.

Guest users can create and edit notes offline. Local Android/iOS data is encrypted with SQLCipher; the database key and tokens live in the Keychain or Android Keystore through `flutter_secure_storage`. Guest data is kept separate from account data and **is not moved automatically** on login. The web build only uses in-memory storage for demos, not persistent storage.

## InfinityFree deployment

Source is available on [GitHub](https://github.com/Ghivee/JejakJamban-app). A step-by-step guide for setting up MySQL, importing the schema in phpMyAdmin, filling in `.env` safely, building a production ZIP and uploading over FTP is in [`docs/DEPLOY-INFINITYFREE.md`](./docs/DEPLOY-INFINITYFREE.md).

InfinityFree's free hosting has no SSH, terminal or Artisan access. Set up the database from [`backend/infinityfree/schema.sql`](./backend/infinityfree/schema.sql) and build the production package from PowerShell:

```powershell
Set-Location backend
.\scripts\prepare-infinityfree.ps1
```

The resulting ZIP is at `backend/dist/jejakjamban-infinityfree-upload.zip`; upload its contents to `htdocs`. Upload `backend/.env` separately over FTP after filling in the account credentials; never commit or send it. Details on the required PHP version, `htdocs`, `.htaccess`, phpMyAdmin and API tests are in the deployment guide. InfinityFree advertises free hosting with no fixed expiry, but the account still needs some traffic each month and is subject to fair-use and resource limits. Read the [full deployment guide](./docs/DEPLOY-INFINITYFREE.md) before uploading.

## Tests and checks

```powershell
flutter analyze
flutter test

Set-Location backend
composer install
php artisan test
vendor/bin/pint --test
```

Flutter tests cover the home widget and unit tests for XP, streak/freeze, Trail Score (0 to 100) and informational red flags. Laravel tests check auth, validation, CRUD, idempotency and isolation between users.

## MVP scope and limitations

Already in place: consent onboarding on simple registration, a 13+ age gate, aliases, the Home/Insight/Log/League/Map tabs, Bristol 1 to 7 logging, log detail, history, edit/delete, check-in and local water tracking, distribution charts, informational warnings, SQLCipher, the Laravel API, local seeding and tests.

Not yet in place: an internet-reachable backend URL, email OTP and social login, server-side XP/quests/production badges, a backend league/leaderboard, friends/squad features, a community map, production notifications, PDF export, account deletion, an admin/moderation panel, deployment screenshots, a final PDF report, and a demo video. Plan notes and a checklist are in [`docs/PLAN.md`](./docs/PLAN.md); conflicts between the assignment and the SRS are recorded in [`docs/CHANGELOG-KONFLIK.md`](./docs/CHANGELOG-KONFLIK.md).
