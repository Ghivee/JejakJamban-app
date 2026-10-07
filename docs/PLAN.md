# JejakJamban — Rencana Implementasi

## 1. Ringkasan persyaratan tugas

1. **T-01 — Backend Laravel production:** siapkan backend Laravel agar dapat dijalankan pada konfigurasi production dan dideploy ke hosting gratis yang mendukung PHP serta database.
2. **T-02 — Database dan migration:** sediakan database, minimal satu tabel utama, migration, model, controller, dan mekanisme pengisian data demo.
3. **T-03 — REST API CRUD:** sediakan endpoint JSON untuk daftar, detail, tambah, ubah, dan hapus data aplikasi.
4. **T-04 — Validasi dan response API:** validasi input; data valid menghasilkan response sukses yang sesuai (POST `201`), sedangkan input tidak valid dan data tak ditemukan menghasilkan error JSON/HTTP yang sesuai.
5. **T-05 — Konfigurasi aman untuk deploy:** konfigurasi URL dan database melalui environment; jangan unggah `.env`, jangan bergantung pada `localhost` di build production, dan siapkan migration production.
6. **T-06 — Integrasi Flutter:** Flutter mengambil, menampilkan, menambah, mengubah, dan menghapus data dari REST API; hasil akhir menggunakan URL API online, bukan `localhost` atau `10.0.2.2`.
7. **T-07 — Verifikasi API dan deployment:** verifikasi GET koleksi, GET detail, POST, PUT/PATCH, DELETE, dan validasi/error menggunakan Postman atau Insomnia; siapkan bukti URL, method, status, request, dan response serta screenshot deployment/database/API.
8. **T-08 — Dokumentasi pengumpulan:** dokumentasikan identitas, deskripsi, arsitektur, hosting/URL/repository, environment/database, deployment, tabel hasil uji, integrasi Flutter, sedikitnya dua kendala dan solusinya, kesimpulan, serta panduan demo video 5–10 menit. Output tugas juga meminta link repository, URL API, laporan PDF, screenshot, dan video.
9. **T-09 — Alur yang dapat dijelaskan:** dokumentasikan alur `Request → Route → Controller → Model/Database → Response` dan perbedaan konfigurasi lokal/production.

Sumber utama: **TUGAS DEPLOYMENT APLIKASI WEB DAN SELULER**, mata kuliah Sistem Web dan Seluler (Mobile) Lanjutan, khususnya bagian A–M. Endpoint contoh `/api/products` diganti dengan resource aplikasi JejakJamban.

## 2. Matriks keterlacakan

| Requirement tugas | Kebutuhan SRS terkait | Modul/file implementasi |
|---|---|---|
| T-01 | FR-2.1, FR-2.2, FR-2.6; §9.1, §9.6 | Laravel/Docker di `backend/`, blueprint `render.yaml`, source di GitHub dan instruksi deploy di `README.md`; deployment/URL online belum tersedia |
| T-02 | FR-2.1, FR-2.2, FR-2.4; kamus data §9.4 | Migration, model, demo sintetis di `backend/database/` dan `backend/app/`; backend tests lulus |
| T-03 | FR-2.1, FR-2.2, FR-2.4 | `backend/routes/api.php`, controller, FormRequest, Resource, dan Flutter repository untuk CRUD |
| T-04 | FR-2.2, FR-2.4, FR-2.6; NFR-P2 | Validasi Laravel/response JSON; `backend/tests/Feature/Api/`; HTTP lokal terverifikasi (200/201, invalid 422) |
| T-05 | FR-2.6, NFR-SEC1–SEC4 | `backend/.env.example`, `.gitignore`, `render.yaml`, `backend/Dockerfile`; Flutter `--dart-define=API_BASE_URL=...`; secret production belum tersedia |
| T-06 | FR-2.1, FR-2.2, FR-2.4, FR-2.6; S-05–S-07 | `lib/core/network/`, `lib/features/log/`, API repository dan layar log; APK debug berhasil, URL production belum diuji |
| T-07 | FR-2.1, FR-2.4, FR-2.6; AC-1, AC-2 | `docs/JejakJamban.postman_collection.json`, feature tests, tabel hasil HTTP lokal, checklist bukti; screenshot/tes hosting belum ada |
| T-08 | NFR-M1–M4; §15.1–15.3 | Source di GitHub, `README.md`, `docs/PLAN.md`, `docs/CHANGELOG-KONFLIK.md`, draft `docs/LAPORAN-DEPLOYMENT.md`; PDF final/video belum ada |
| T-09 | §9.1, §9.6–9.7; NFR-SEC | Alur request/config backend pada `README.md` dan draft laporan |

## 3. Konflik tugas dan SRS

| Topik | Instruksi tugas | SRS | Keputusan |
|---|---|---|---|
| Backend | Laravel REST API dan database hosting | Supabase Auth/Postgres/Edge Functions (§2.1, §9.1) | **Tugas menang:** Laravel menjadi satu-satunya backend API untuk deliverable ini. Tidak menambahkan Supabase yang akan menggandakan sumber data dan bertentangan dengan arsitektur wajib. |
| Operasi API | Wajib uji CRUD pada resource aplikasi | Log BAB bersifat privat, dapat diedit/dihapus (FR-2.4) | CRUD log menggunakan Sanctum bearer token, validasi server, dan query dibatasi ke pemilik. |
| Deployment publik | Wajib ada URL backend internet dan Flutter memakai URL itu | SRS berorientasi backend Supabase; tidak menetapkan hosting Laravel | Tugas menang. Dockerfile/blueprint tersedia dan source dipush ke GitHub; resource hosting belum dibuat sehingga belum ada deployment atau URL aktif. |
| Backend praktikum sebelumnya | Gunakan aplikasi Laravel dari praktikum; tidak perlu membuat baru jika sudah memenuhi syarat | SRS tidak menentukan source praktikum | Tidak ada source Laravel pada direktori kerja saat analisis. Asumsi: buat backend JejakJamban baru yang memenuhi kontrak tugas, bukan mengganti project lama yang tidak tersedia. |
| Format pengumpulan | Laporan PDF, link, screenshot, video 5–10 menit | SRS meminta dokumentasi aplikasi | Repository remote tersedia di `https://github.com/Ghivee/JejakJamban-app`; README dan draft laporan teknis tersedia. PDF, screenshot, dan video aktual tetap pending. |

## 4. Cakupan MVP

**Dikerjakan lebih dahulu**

- Fase prioritas tugas: proyek Flutter dan Laravel terpisah jelas; endpoint log utama tervalidasi; migration, model, CRUD JSON, seed demo dan pengujian.
- Fondasi UI Bahasa Indonesia dengan lima tab, tema terang/gelap dan token warna SRS.
- Log cepat Bristol 1–7 dan log lengkap; daftar, detail, edit, hapus; API dapat dipilih lewat konfigurasi environment. Tanpa foto feses.
- Ringkasan sederhana dan tracker air; penyimpanan lokal/penanganan jaringan offline sejauh dapat diimplementasikan dengan dependensi proyek.
- Consent/disclaimer dan data demo sintetis; jangan mengirim catatan kesehatan ke leaderboard.
- Dokumentasi cara menjalankan, menguji, men-deploy, dan bukti yang masih harus direkam.

**Ditunda atau dibatasi, dengan alasan**

- Backend online pada hosting, URL publik, bukti deployment/database/Postman, laporan PDF beridentitas, dan video: menunggu akun hosting/database, identitas mahasiswa, serta bukti aktual. Repository remote sudah tersedia; bukti lain tidak boleh direkayasa atau dianggap selesai.
- Login sosial/email terverifikasi, admin 2FA/moderasi, liga multi-pengguna, teman/squad, dan push notification produksi: perlu layanan/konfigurasi server dan kredensial yang tidak tersedia; persyaratan tugas deployment lebih dulu.
- Peta komunitas, unggah foto fasilitas, premium, integrasi HealthKit/Health Connect, dan panel admin penuh: fitur SRS noninti yang memerlukan API/izin/layanan eksternal; setelah MVP dan waktu/akses tersedia.
- XP server-side, 40 badge, quest personalisasi, freeze/repair streak, skor liga penuh, insight korelasi 14 hari, PDF laporan dokter dan export/hapus akun lengkap: pekerjaan lanjutan setelah jalur backend dan operasi data inti stabil. Aturan yang menyentuh kesehatan tetap informatif, bukan diagnosis.
- Fitur SRS yang mengungkap data kesehatan pengguna tidak akan diimplementasikan; leaderboard/sosial hanya boleh memuat alias/avatar/level/skor dengan persetujuan.

Penundaan fitur SRS Must di atas adalah pembatasan MVP, bukan pengubahan requirement SRS. Keduanya akan tetap terlihat di checklist akhir dengan status yang jujur.

## 5. Asumsi

1. Tidak ditemukan project aplikasi atau backend sebelumnya pada direktori kerja ketika rencana dibuat; project baru boleh disiapkan bila source praktikum tidak tersedia.
2. Resource CRUD adalah `bowel_logs` (Jejak), bukan contoh generik `products`; data kesehatan harus privat per pengguna.
3. Laravel dan Flutter dapat dipasang/dijalankan pada mesin pengguna; versi SDK/dependensi aktual diverifikasi sebelum memilih implementasi.
4. Link repository GitHub diberikan kemudian: `https://github.com/Ghivee/JejakJamban-app`; source lokal dipush ke branch `main`. Tidak ada kredensial/akun hosting, database production, URL domain, atau identitas/NIM/kelas. Nilai sensitif tidak ditulis ke source; deployment dan evidence memerlukan pemilik untuk melakukan langkah akun.
5. Lingkungan pengembangan lokal boleh menggunakan localhost; hasil production wajib menerima URL HTTPS melalui konfigurasi, dan tidak boleh mengklaim pengujian online sebelum benar-benar berhasil.
6. Data/demo yang disediakan sintetis dan tidak berisi informasi kesehatan nyata.
7. Bahasa antarmuka MVP adalah Bahasa Indonesia. Tema dan panduan visual merujuk SRS §7.5; klaim/konten medis memakai disclaimer SRS §10.3.

## 6. Fase dan estimasi

Estimasi berikut adalah perkiraan rekayasa untuk MVP dan dapat berubah setelah akses lingkungan serta hosting dikonfirmasi.

| Fase | Cakupan | Hasil |
|---|---|---:|
| 0. Analisis | Baca tugas/SRS, tetapkan matriks dan konflik | Selesai |
| 1. Fondasi + prioritas deployment | Struktur Flutter/Laravel, env, tema/routing, database, API CRUD, seed, Docker/deploy template | Fondasi lokal selesai; deploy publik pending |
| 2. Auth & profil | Login/alias/onboarding/consent dan pembatasan data per pemilik | Auth dasar dan API token; profil/OTP lengkap tertunda |
| 3. Fitur inti | Log cepat/lengkap, check-in/air/riwayat/kalender, sinkronisasi/offline | Log, check-in, air, riwayat, antrean offline selesai sebagian |
| 4. Gamifikasi | XP/level/streak/badge/quest dengan tes logika dan desain anti-spam | Aturan domain utama dites; persistensi/server/quest/badge tertunda |
| 5. Insight | Grafik, skor transparan, red flag, laporan | Grafik dan red flag dasar; PDF/insight lanjutan tertunda |
| 6. Liga & sosial | Privasi opt-in, leaderboard Skor Jejak, teman/squad | UI placeholder; backend/social tertunda |
| 7. Pelengkap | Peta/edukasi/pengaturan privasi sesuai akses layanan | UI status/edukasi dasar; peta dan ekspor/penghapusan tertunda |
| 8. Finalisasi | Analyze/test/build, README, deployment/evidence/laporan/video | Analyze/tests/build lokal lulus; bukti online/PDF/video pending akses |

## 7. Checklist persyaratan tugas

| ID | Status akhir | Bukti / alasan |
|---|---|---|
| T-01 | **Sebagian** | Laravel production config, Dockerfile, dan `render.yaml` tersedia; hosting belum dibuat dan URL publik belum diverifikasi. |
| T-02 | **Selesai (lokal)** | Migration, model, seeder sintetis dan SQLite tersedia; 11 backend tests/39 assertions lulus. PostgreSQL produksi belum dijalankan. |
| T-03 | **Selesai (lokal)** | Endpoint list/detail/create/update/delete terlindungi; HTTP lokal menghasilkan 200/201. |
| T-04 | **Selesai (lokal)** | Bristol invalid menghasilkan HTTP 422; automated tests memeriksa validasi, auth, ownership, idempotensi, dan CRUD. |
| T-05 | **Sebagian** | Contoh environment, konfigurasi URL Flutter, Docker/Render, dan release HTTPS guard disediakan; secret/domain/database production belum dikonfigurasi. |
| T-06 | **Sebagian** | Source Flutter terhubung ke Laravel CRUD dan APK debug berhasil dibuat. URL online belum tersedia untuk diuji. |
| T-07 | **Sebagian** | CRUD HTTP lokal, Postman collection, automated tests, dan tabel hasil lokal tersedia. Screenshot API/deployment/database serta tes URL online pending. |
| T-08 | **Sebagian** | Repository GitHub, README, dan draft laporan dengan hasil/kendala tersedia. PDF beridentitas, screenshot, URL production, dan video 5–10 menit belum tersedia. |
| T-09 | **Selesai** | Alur `Request → Route → Controller → Model/Database → Response` dan konfigurasi lokal/deploy didokumentasikan. |

### Validasi akhir

- `flutter analyze`: bersih.
- `flutter test`: 9 test lulus.
- Android `assembleDebug`: berhasil; APK tersedia di `build/app/outputs/flutter-apk/app-debug.apk`.
- `php artisan test --compact`: 11 test lulus, 39 assertions; Laravel Pint `--test` lulus.
- HTTP API lokal: GET daftar 200, POST valid 201, GET detail 200, PUT 200, DELETE 200, POST invalid 422.
- Postman collection JSON valid; `render.yaml` berhasil diparse dan memuat service Docker serta database PostgreSQL yang diharapkan. Docker image/deployment tetap belum dapat diuji karena Docker CLI dan kredensial hosting tidak tersedia.
