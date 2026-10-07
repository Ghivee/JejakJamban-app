# JejakJamban

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
  Dockerfile               Image deploy Apache/PHP + PostgreSQL
docs/
  PLAN.md
  CHANGELOG-KONFLIK.md
  LAPORAN-DEPLOYMENT.md    Draft laporan dan checklist bukti
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

## Menyiapkan deployment

Source sudah tersedia di [GitHub](https://github.com/Ghivee/JejakJamban-app).
[`render.yaml`](./render.yaml) dan [`backend/Dockerfile`](./backend/Dockerfile)
menyiapkan Laravel + PostgreSQL melalui Render Blueprint.

### Deploy database dan API di Render

1. Buat/login ke akun Render, lalu pilih **New → Blueprint**.
2. Hubungkan GitHub, pilih repository `Ghivee/JejakJamban-app` dan branch
   `main`. Blueprint membaca `render.yaml` di root untuk membuat web service
   Laravel (Docker) dan PostgreSQL di region yang sama.
3. Render meminta nilai rahasia `APP_KEY`. Dari folder `backend`, siapkan
   dependency Composer lalu jalankan `php artisan key:generate --show`; salin
   nilai `base64:...` yang dihasilkan ke prompt secret Render. Simpan key hanya
   di Render—jangan masukkan ke source, chat, screenshot, atau `.env` yang
   dipush.
4. Tinjau resource dan biaya/plan yang ditampilkan, lalu pilih **Apply**.
   Tunggu database berstatus `Available` dan deployment selesai. `DB_URL`
   ditautkan ke connection string database secara otomatis; entrypoint
   container menjalankan `php artisan migrate --force`. Seeder demo tidak
   dijalankan di production.
5. Buka URL service yang diberikan Render, tambahkan `/up`, dan pastikan
   health check berhasil. Gunakan URL aktual yang ditampilkan dashboard.
6. Uji login, CRUD, dan validasi dengan Postman. Untuk Flutter jalankan:

   ```powershell
   flutter build apk --release --dart-define=API_BASE_URL=https://URL-SERVICE-AKTUAL.onrender.com/api
   ```

   Pasang APK dan uji sinkronisasi di perangkat.
7. Simpan screenshot aktual service, database, Postman, dan Flutter online.
   Isi URL di [`docs/LAPORAN-DEPLOYMENT.md`](./docs/LAPORAN-DEPLOYMENT.md),
   lengkapi identitas, lalu ekspor laporan final ke PDF dan rekam video demo.

**Peringatan paket gratis:** menurut dokumentasi Render saat ini, PostgreSQL
Free dibatasi 1 GB dan kedaluwarsa **30 hari setelah dibuat**. Setelah masa
grace 14 hari, database dan datanya dihapus bila tidak di-upgrade. Free web
service juga tidur setelah 15 menit tanpa trafik. Paket gratis cocok untuk
demo/praktikum singkat, bukan produksi atau data kesehatan nyata. Untuk data
yang perlu disimpan, pilih PostgreSQL berbayar/penyedia dengan masa simpan dan
backup yang sesuai. Selalu tinjau harga dan kebijakan terbaru di dashboard
sebelum membuat resource.

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
