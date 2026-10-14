# Laporan Tugas Deployment — JejakJamban

**Mata Kuliah:** Sistem Web dan Seluler (Mobile) Lanjutan  
**Tugas:** Deploy Backend Laravel + Integrasi Flutter ke Hosting Publik  
**Nama:** Galang Ahmad Ghifari  
**NIM:** *(isi sebelum kumpul)*  
**Kelas:** *(isi sebelum kumpul)*  
**Tanggal:** 14 Oktober 2026  

---

## 1. Pendahuluan

JejakJamban adalah aplikasi mobile yang mencatat jejak kesehatan pencernaan — khususnya tipe Bristol — untuk kebutuhan pemantauan pribadi. Pengguna bisa bekerja offline; setelah login, data disinkronkan ke backend REST API. Aplikasi ini bukan alat diagnosis medis.

Tugas ini meliputi deploy backend Laravel 12 ke hosting publik (InfinityFree), import database MySQL, integrasi URL produksi ke aplikasi Flutter, dan pembangunan APK release.

---

## 2. Arsitektur Sistem

```
┌──────────────┐     HTTPS/JSON      ┌─────────────────────┐     PDO      ┌──────────┐
│  Flutter App │ ──────────────────▶ │  Laravel 12 + API   │ ──────────▶ │  MySQL   │
│  (Android)   │  Bearer Token       │  (InfinityFree)     │             │ Infinity │
└──────────────┘                     └─────────────────────┘             └──────────┘
```

Alur request:
```
HTTP Request → public/index.php → routes/api.php → Middleware (throttle/auth)
→ FormRequest Validation → Controller → Eloquent Model → MySQL → JSON Response
```

---

## 3. Deployment Backend

### 3.1 Platform

| Item | Keterangan |
|---|---|
| Hosting | InfinityFree (gratis) |
| Domain | jejakjamban.site.je |
| URL API | https://jejakjamban.site.je/api |
| PHP | 8.4.25 (pdo_mysql aktif) |
| Framework | Laravel 12 + Sanctum |
| Database | MySQL — if0_43113401_1 @ sql106.infinityfree.com |
| Deploy | FTP (ftpupload.net) — 6.280 file |

### 3.2 Langkah Deploy

1. **Paket production** — `composer install --no-dev`, generate `.env` dengan `APP_ENV=production`, `APP_DEBUG=false`, `APP_KEY`, credential MySQL.

2. **Perbaikan .htaccess** — Rewrite rule asli menyebabkan infinite loop (HTTP 500). Ditambahkan kondisi `RewriteCond %{REQUEST_URI} !^/public/` agar hanya me-rewrite sekali ke folder `public/`.

3. **Upload via FTP** — Seluruh project (termasuk `vendor/`) di-upload ke `htdocs/` menggunakan curl batch, ±45 menit untuk 6.280 file.

4. **Import database** — Skema SQL (`backend/infinityfree/schema.sql`) dijalankan via script PHP di server hosting. DNS `sql106.infinityfree.com` tidak resolve dari jaringan lokal, tapi resolve dari dalam jaringan InfinityFree. Hasil: 14 statement OK, 11 tabel terbentuk.

5. **Perbaikan middleware** — Route API yang tidak terautentikasi sebelumnya membalas HTTP 500 (`Route [login] not defined`). Diperbaiki dengan konfigurasi `redirectGuestsTo` dan `shouldRenderJsonWhen` di `bootstrap/app.php` sehingga selalu membalas JSON 401.

6. **Smoke test** — 17 skenario pengujian dijalankan langsung terhadap URL produksi.

### 3.3 Struktur Database

| Tabel | Fungsi |
|---|---|
| users | Akun pengguna (alias, email, usia, persetujuan) |
| bowel_logs | Data jejak/tipe Bristol |
| personal_access_tokens | Token Sanctum untuk autentikasi API |
| sessions, cache, cache_locks | Sesi dan cache framework |
| jobs, job_batches, failed_jobs | Queue framework |
| password_reset_tokens | Token reset password |
| migrations | Catatan migrasi |

---

## 4. Pengujian API Produksi

Pengujian dilakukan terhadap `https://jejakjamban.site.je/api` menggunakan PHP curl yang dijalankan di server hosting. Hasil: **17/17 PASS**.

| No | Method | Endpoint | Skenario | Expected | Actual | Status |
|---:|---|---|---|---|---|---|
| 1 | POST | /api/register | Registrasi valid | 201 + token | 201 + token | PASS |
| 2 | POST | /api/register | Tanpa alias/age | 422 | 422 + errors | PASS |
| 3 | POST | /api/register | Usia 15 tanpa parental consent | 422 | 422 | PASS |
| 4 | POST | /api/login | Login valid | 200 + token | 200 + token | PASS |
| 5 | GET | /api/me | Tanpa token | 401 | 401 | PASS |
| 6 | GET | /api/me | Dengan token | 200 + data | 200 + data | PASS |
| 7 | GET | /api/logs | Tanpa token | 401 | 401 | PASS |
| 8 | POST | /api/logs | Tambah jejak (bristol 4) | 201 | 201 + data | PASS |
| 9 | POST | /api/logs | Bristol 9 (invalid) | 422 | 422 | PASS |
| 10 | GET | /api/logs | Daftar jejak | 200 + list | 200 + list | PASS |
| 11 | GET | /api/logs/1 | Detail jejak | 200 | 200 + data | PASS |
| 12 | GET | /api/logs/999999 | ID tidak ada | 404 | 404 | PASS |
| 13 | PUT | /api/logs/1 | Ubah tipe | 200 | 200 | PASS |
| 14 | DELETE | /api/logs/1 | Hapus jejak | 200 | 200 | PASS |
| 15 | GET | /api/logs/1 | Akses setelah hapus | 404 | 404 | PASS |
| 16 | POST | /api/logout | Logout | 200 | 200 | PASS |
| 17 | POST | /api/logout | Logout lagi | 401 | 401 | PASS |

Catatan: Token yang digunakan saat pengujian sudah di-revoke dari database. Data uji sudah dihapus.

---

## 5. Integrasi Flutter

### 5.1 Konfigurasi URL

URL API dibaca dari environment variable saat build time:

```dart
// lib/core/config/app_config.dart
static const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api', // emulator Android
);
```

Build release mewajibkan URL HTTPS — `AppConfig.validate()` menolak localhost/10.0.2.2/non-HTTPS di release.

### 5.2 Build APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://jejakjamban.site.je/api
```

Hasil: APK release 66,9 MB dengan URL produksi ter-embed.

### 5.3 Perbaikan yang Dilakukan

| Masalah | Perbaikan |
|---|---|
| APK release tanpa izin INTERNET | Ditambahkan `<uses-permission android:name="android.permission.INTERNET"/>` di AndroidManifest.xml |
| Nama app tidak konsisten (Android: `jejak_jamban`, iOS: `Jejak Jamban`) | Diseragamkan menjadi "JejakJamban" di AndroidManifest, Info.plist, pubspec.yaml, web manifest |
| Deskripsi masih template "A new Flutter project." | Diganti deskripsi aplikasi yang sesuai |
| Tidak ada logo (masih icon Flutter default) | Dibuat logo custom: teal gradient + huruf "J" putih, untuk semua ukuran Android/iOS/Web |
| Komentar TODO di build.gradle.kts | Dihapus |

---

## 6. Kendala dan Penyelesaian

| No | Kendala | Penyelesaian |
|---|---|---|
| 1 | Rewrite-loop .htaccess → HTTP 500 | Tambah kondisi `RewriteCond %{REQUEST_URI} !^/public/` |
| 2 | Server web InfinityFree down beberapa hari | Monitoring otomatis, menunggu server pulih |
| 3 | DNS `sql106.infinityfree.com` tidak resolve dari lokal | Import DB via script PHP di server hosting |
| 4 | Route API → 500 "Route [login] not defined" | Konfigurasi middleware `redirectGuestsTo` + `shouldRenderJsonWhen` |
| 5 | Folder `storage/framework/sessions` tidak ada → 500 | Buat folder via perintah MKD FTP |
| 6 | APK release tanpa izin INTERNET | Tambah permission di AndroidManifest.xml (bug klasik Flutter) |
| 7 | Token produksi bocor di file bukti git | Revoke token dari DB, scrub file, hapus data uji |

---

## 7. Kesimpulan

Backend Laravel 12 JejakJamban berhasil di-deploy ke InfinityFree dan berfungsi penuh:

- URL produksi aktif: https://jejakjamban.site.je (HTTPS)
- Health check `/up` merespons HTTP 200
- Database MySQL ter-import (11 tabel)
- 17/17 skenario pengujian API PASS
- APK Flutter release berhasil di-build dengan URL produksi dan logo custom

Aplikasi siap digunakan: pengguna dapat mendaftar, login, dan mencatat jejak kesehatan pencernaan melalui aplikasi Flutter yang terhubung ke backend production.

---

## 8. Daftar Pustaka / Referensi

- Laravel 12 Documentation — https://laravel.com/docs/12.x
- Flutter Documentation — https://docs.flutter.dev
- InfinityFree Knowledge Base — https://help.infinityfree.com
- Bristol Stool Scale — referensi medis tipe 1–7

---

## 9. Lampiran

| File | Deskripsi |
|---|---|
| `dist/JejakJamban-release.apk` | APK release Flutter (66,9 MB) |
| `docs/bukti-smoke-test-produksi.txt` | Transkrip lengkap 17 pengujian |
| `backend/infinityfree/schema.sql` | Skema database |
| `docs/JejakJamban.postman_collection.json` | Collection Postman untuk testing manual |

---

*Laporan ini merupakan dokumen tugas kuliah. Seluruh pengujian dan deployment dilakukan secara nyata terhadap infrastruktur production.*
