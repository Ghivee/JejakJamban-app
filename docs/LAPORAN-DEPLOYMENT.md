# Draft Laporan Tugas Deployment JejakJamban

> Isi bagian bertanda `[ISI]` setelah deployment menggunakan akun/URL milik
> mahasiswa. Lampirkan screenshot asli dan ekspor laporan menjadi PDF sebelum
> pengumpulan. Belum ada URL production atau bukti visual di workspace ini.

## 1. Identitas

- Nama: [ISI]
- NIM: [ISI]
- Kelas: [ISI]
- Kelompok: Tugas individu
- Mata kuliah: Sistem Web dan Seluler (Mobile) Lanjutan

## 2. Deskripsi aplikasi

JejakJamban adalah aplikasi Flutter untuk mencatat tipe Bristol dan ringkasan
kesehatan pencernaan secara privat. Pengguna dapat bekerja offline; setelah
masuk, log disinkronkan ke Laravel REST API. Log tidak digunakan pada
leaderboard. Aplikasi bukan alat diagnosis medis.

## 3. Arsitektur

```text
Flutter (Android/iOS)
  → HTTPS REST API (Laravel + Sanctum)
  → PostgreSQL production / SQLite lokal
```

Untuk setiap log: `Request → routes/api.php → FormRequest validation →
BowelLogController → BowelLog model → database → JSON Resource`.

## 4. Deployment backend

- Platform: [ISI setelah memilih hosting]
- URL backend/API: [ISI URL HTTPS AKTIF]
- Repository: [ISI LINK]
- PHP/Laravel: PHP 8.3, Laravel 12
- Database: [ISI TIPE DAN NAMA INSTANCE TANPA KREDENSIAL]
- Environment production: `APP_ENV=production`, `APP_DEBUG=false`, `APP_KEY`
  dan `DB_URL` disimpan pada secret/environment hosting. File `.env` tidak
  dipublikasikan.
- Migration: `php artisan migrate --force`; jangan jalankan seeder demo di
  production.
- Document root Apache: `backend/public`.
- Proses yang digunakan: Dockerfile Apache pada `backend/Dockerfile`; blueprint
  opsional di `render.yaml`. Validasi kuota/massa aktif layanan gratis perlu
  dilakukan di akun hosting.

## 5. Pengujian API lokal

Berikut hasil pengujian HTTP lokal aktual terhadap server development, bukan
bukti bahwa URL production sudah di-deploy:

| No | Method | Endpoint | Skenario | Expected | Actual | Status |
|---:|---|---|---|---|---|---|
| 1 | GET | `/api/logs` | Daftar Jejak dengan bearer token | 200 + JSON | 200 + JSON | Pass (lokal) |
| 2 | GET | `/api/logs/{id}` | Detail data | 200 + JSON | 200 + JSON | Pass (lokal) |
| 3 | POST | `/api/logs` | Data Bristol valid | 201 + JSON | 201 + JSON | Pass (lokal) |
| 4 | POST | `/api/logs` | Bristol di luar 1–7 | 422 + errors | 422 | Pass (lokal) |
| 5 | PUT | `/api/logs/{id}` | Ubah tipe | 200 + JSON | 200 + JSON | Pass (lokal) |
| 6 | DELETE | `/api/logs/{id}` | Hapus milik sendiri | 200 + JSON | 200 + JSON | Pass (lokal) |
| 7 | Flutter → API | URL production | Ambil/tampilkan data online | Data dari server | Belum diuji pada URL production | Pending deployment |

Login, authorization, ownership, idempotensi, dan response validasi juga
memiliki automated feature tests (`backend/tests/Feature/Api`).

## 6. Integrasi Flutter

URL dibaca dari `String.fromEnvironment('API_BASE_URL')`. Debug Android emulator
lokal memakai `http://10.0.2.2:8000/api`; build release mewajibkan URL HTTPS
melalui `--dart-define`. Token tersimpan di secure storage; data lokal Android/
iOS tersimpan dalam database SQLCipher, terpisah per pemilik.

Status bukti Flutter yang mengambil data dari backend production: [PENDING —
jalankan setelah URL deploy tersedia, lalu lampirkan screenshot].

## 7. Kendala dan penyelesaian

1. **PHP CLI tidak otomatis memuat extension konfigurasi sementara saat proses
   server turunan berjalan.** Request lokal awal menghasilkan HTTP 500 karena
   `mbstring` tidak aktif pada PHP server. Penyelesaian: aktifkan extension
   PHP pada `php.ini` yang digunakan server; untuk pemeriksaan workspace server
   dijalankan langsung menggunakan PHP terkonfigurasi. Verifikasi ulang route
   `/up` menghasilkan HTTP 200.
2. **Sanctum belum memiliki tabel `personal_access_tokens`.** Login gagal ketika
   token dibuat. Penyelesaian: publish migration Sanctum lalu jalankan
   `php artisan migrate`; automated login/auth tests setelah itu lulus.
3. **Flutter doctor memberi peringatan bahwa Android SDK berada pada path dengan
   spasi (`E:\Aplikasi\Android Studio`).** Jalur SDK ini bisa mengganggu tool
   NDK; pindahkan/konfigurasikan Android SDK ke path tanpa spasi jika build
   Android gagal. `[Perbarui dengan hasil build APK aktual]`

## 8. Kesimpulan

Backend dan Flutter source telah diintegrasikan untuk API Laravel; API lokal
telah lulus uji HTTP CRUD dan validasi. Kesimpulan keberhasilan deployment
publik serta integrasi Flutter terhadap internet baru dapat diisi setelah URL
hosting aktif diuji.

## 9. Checklist bukti pengumpulan

- [ ] Link repository remote
- [ ] URL backend/API HTTPS aktif
- [ ] Screenshot dashboard/status deployment
- [ ] Screenshot GET, GET detail, POST, PUT, DELETE, validasi/error di Postman
- [ ] Screenshot database hosting berisi tabel
- [ ] Screenshot Flutter menggunakan API production
- [ ] Video demo 5–10 menit
- [ ] Ekspor dokumen ini ke PDF setelah semua placeholder diisi
