# JejakJamban

JejakJamban is a Flutter app, in Indonesian, for privately tracking bowel movement patterns (Bristol stool chart). Per the deployment assignment's instructions, the architecture is **Flutter -> Laravel REST API -> database** (not Supabase). Local notes use encrypted SQLite on Android/iOS; when a user is signed in, a sync queue sends entries to the Laravel API with a bearer token.

[Baca dalam Bahasa Indonesia di bawah](#bahasa-indonesia)

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

---

## Bahasa Indonesia

JejakJamban adalah aplikasi Flutter berbahasa Indonesia untuk mencatat pola
pencernaan secara privat. Sesuai instruksi tugas deployment, arsitekturnya
menggunakan **Flutter → Laravel REST API → database** (bukan Supabase).
Catatan lokal menggunakan SQLite terenkripsi di Android/iOS; saat pengguna
masuk, antrean sinkronisasi dikirim ke API Laravel dengan bearer token.

> **Catatan status:** source, API lokal, migration, CRUD, validasi, dan tes
> otomatis sudah tersedia; source juga sudah dipush ke
> [repository GitHub](https://github.com/Ghivee/JejakJamban-app). Backend
> **belum dideploy ke internet** karena layanan hosting belum dibuat. URL
> production, screenshot deployment/Postman/database, dan video demo belum
> tersedia; jangan mengumpulkan URL contoh sebagai URL aktif.

JejakJamban bukan alat diagnosis atau pengganti nasihat tenaga kesehatan
profesional. Fitur unggah foto feses tidak disediakan. Log kesehatan tidak
ditampilkan di leaderboard atau sosial.

## Struktur

```text
lib/
  app/                    Routing go_router dan shell 5 tab
  core/
    config/               API_BASE_URL dan validasi build release
    domain/               Aturan XP, streak, Skor Jejak, red flag
    network/              Client JSON Laravel dan secure token
    storage/              SQLCipher/outbox, data lokal, mode web demo
    theme/                Token Material 3 SRS
  features/
    auth/                 Login/registrasi/consent
    home/                 Ringkasan, check-in, hidrasi
    insight/              Distribusi Bristol dan peringatan informatif
    log/                  Log cepat/lengkap, riwayat, CRUD, sinkronisasi
    league/                Informasi privasi/Skor Jejak
    map/                   Status cakupan peta
backend/
  app/                    Model, request validation, controller, resource
  database/               Migration, seeder sintetis
  routes/api.php           API JSON terautentikasi
  tests/                   Feature tests Laravel
  infinityfree/            SQL schema dan rewrite untuk upload FTP
  scripts/                 Skrip paket production InfinityFree
docs/
  PLAN.md
  CHANGELOG-KONFLIK.md
  LAPORAN-DEPLOYMENT.md    Draft laporan dan checklist bukti
  DEPLOY-INFINITYFREE.md   Panduan hosting InfinityFree
  JejakJamban.postman_collection.json
```

## Persyaratan lokal

- Flutter stable dan Dart 3 (workspace ini diuji dengan Flutter 3.44.1 / Dart
  3.12.1).
- PHP 8.3+ dengan `curl`, `fileinfo`, `mbstring`, `openssl`, `pdo_sqlite`,
  `sqlite3`, dan `zip`.
- Composer 2, Git, dan Android SDK untuk build APK.
- Android emulator/perangkat untuk pemakaian mobile. iOS build membutuhkan
  macOS/Xcode.

## Menjalankan backend Laravel

Di PowerShell:

```powershell
Set-Location backend
Copy-Item .env.example .env
composer install
php artisan key:generate
if (-not (Test-Path database\database.sqlite)) { New-Item -ItemType File -Path database\database.sqlite | Out-Null }
# Atur JEJAKJAMBAN_DEMO_PASSWORD di backend/.env (minimal 12 karakter)
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Seeder membuat akun **`demo@jejakjamban.local`** dan tiga jejak sintetis. Kata
sandi berasal dari `JEJAKJAMBAN_DEMO_PASSWORD` di `.env`; seeder menolak
berjalan di `APP_ENV=production`. Jangan menggunakan kata sandi demo sebagai
kredensial production.

Endpoint lokal utama:

| Method | Endpoint | Perlu token |
|---|---|---|
| POST | `/api/register` | Tidak |
| POST | `/api/login` | Tidak |
| GET | `/api/me` | Ya |
| GET | `/api/logs` | Ya |
| GET | `/api/logs/{id}` | Ya |
| POST | `/api/logs` | Ya |
| PUT/PATCH | `/api/logs/{id}` | Ya |
| DELETE | `/api/logs/{id}` | Ya |

Login mengembalikan token Sanctum. Kirim `Authorization: Bearer <token>` dan
`Accept: application/json` untuk semua route log. Response validasi memakai
HTTP 422; resource yang tidak dimiliki user menghasilkan 404. `client_id`
menjadikan POST idempoten untuk retry antrean offline. Log disimpan soft-delete
dan hanya dapat dihapus sampai 30 hari ke belakang.

Koleksi Postman tersedia di
[`docs/JejakJamban.postman_collection.json`](./docs/JejakJamban.postman_collection.json).
Atur `baseUrl`, email, dan kata sandi demo pada collection variables; jalankan
request Login lebih dahulu untuk menyimpan token.

## Menjalankan Flutter

```powershell
flutter pub get
# Android emulator lokal; server Laravel harus berjalan pada port 8000
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

APK debug hasil build lokal tersedia di
`build/app/outputs/flutter-apk/app-debug.apk`. Itu artefak pengembangan, bukan
APK production: compile ulang dengan URL API yang benar untuk demo pada perangkat
atau server lain.

Untuk perangkat fisik gunakan alamat LAN komputer pada build debug. Build
release **menolak** URL non-HTTPS/localhost:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://URL-AKTIF-ANDA/api
```

File `.env.example` menunjukkan bentuk `API_BASE_URL`, tetapi aplikasi Flutter
membaca nilainya melalui `--dart-define` (tidak memuat `.env` saat runtime).
Jangan menyimpan URL, token, atau kredensial production ke source.

Pengguna tamu dapat membuat dan mengedit catatan offline. Data lokal Android/iOS
dienkripsi dengan SQLCipher; kunci database dan token disimpan di Keychain /
Android Keystore melalui `flutter_secure_storage`. Data tamu dipisahkan dari
data akun dan **tidak otomatis dipindahkan** saat login. Versi web hanya
memakai penyimpanan in-memory untuk demo, bukan penyimpanan persisten.

## Deployment InfinityFree

Source tersedia di [GitHub](https://github.com/Ghivee/JejakJamban-app). Panduan
langkah demi langkah untuk setup MySQL, import schema di phpMyAdmin, mengisi
`.env` aman, membuat ZIP production dan upload lewat FTP tersedia di
[`docs/DEPLOY-INFINITYFREE.md`](./docs/DEPLOY-INFINITYFREE.md).

InfinityFree free hosting tidak menyediakan SSH, terminal, atau Artisan.
Siapkan database dari [`backend/infinityfree/schema.sql`](./backend/infinityfree/schema.sql)
dan buat paket production dari PowerShell:

```powershell
Set-Location backend
.\scripts\prepare-infinityfree.ps1
```

Hasil ZIP di `backend/dist/jejakjamban-infinityfree-upload.zip`; unggah isi
arsip ke `htdocs`. Unggah file `backend/.env` secara terpisah melalui FTP setelah
mengisi credential akun—jangan commit atau mengirimkannya. Detail syarat versi
PHP, `htdocs`, `.htaccess`, phpMyAdmin, dan tes API ada di panduan deployment.
InfinityFree menyatakan hosting free tanpa masa kedaluwarsa tetap, tetapi
account perlu menerima beberapa hit tiap bulan dan tetap tunduk pada fair-use/
resource limits. Baca [panduan deployment lengkap](./docs/DEPLOY-INFINITYFREE.md)
sebelum upload.

## Tes dan pemeriksaan

```powershell
flutter analyze
flutter test

Set-Location backend
composer install
php artisan test
vendor/bin/pint --test
```

Tes Flutter mencakup widget beranda dan unit test aturan XP, streak/freeze,
Skor Jejak (0–100), dan red flag informatif. Tes Laravel memeriksa auth, validasi,
CRUD, idempotensi, dan isolasi antar-user.

## Cakupan MVP dan keterbatasan

Sudah tersedia: onboarding consent pada registrasi sederhana, age gate 13+,
alias, tab Beranda/Insight/Jejak/Liga/Peta, log Bristol 1–7, detail log, riwayat,
edit/hapus, check-in dan air lokal, grafik distribusi, peringatan informatif,
SQLCipher, API Laravel, seed lokal, dan tes.

Belum tersedia: URL backend internet, email OTP dan social
login, XP server-side/quest/badge produksi, liga/leaderboard backend, fitur
teman/squad, peta komunitas, notifikasi produksi, ekspor PDF, hapus akun, panel
admin/moderasi, screenshot deployment, laporan PDF final, dan video demo.
Catatan rencana dan status checklist ada di
[`docs/PLAN.md`](./docs/PLAN.md); konflik tugas vs SRS dicatat di
[`docs/CHANGELOG-KONFLIK.md`](./docs/CHANGELOG-KONFLIK.md).
