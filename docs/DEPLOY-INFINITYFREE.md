# Deploy API JejakJamban ke InfinityFree

Panduan ini khusus Laravel REST API pada InfinityFree free hosting. InfinityFree
menyatakan paket free tidak memiliki tanggal kedaluwarsa, tetapi tetap memiliki
fair-use/resource limits dan account perlu mendapat beberapa hit setiap bulan
agar dianggap aktif. PHP 8.3 diumumkan untuk seluruh free hosting pada 2025;
verifikasi kembali versi dan extension pada control panel akun sebelum deploy.
Laravel 12 memerlukan PHP 8.2+.

Referensi teknis InfinityFree:

- [Panduan resmi komunitas: deploy Laravel](https://forum.infinityfree.com/t/how-to-install-a-laravel-site-on-infinityfree/118578)
- [Panduan resmi komunitas: koneksi MySQL](https://forum.infinityfree.com/t/how-to-connect-with-mysql/49340)
- [SSH tidak tersedia di free hosting](https://forum.infinityfree.com/t/ssh/112637)
- [Pengumuman PHP 8.3 di free hosting](https://forum.infinityfree.com/t/free-hosting-is-now-upgraded-to-php-8-3/109714)
- [Panduan pemakaian inode](https://forum.infinityfree.com/t/inode-limit/49331)
- [Hosting gratis InfinityFree](https://www.infinityfree.com/)

## Penting sebelum mulai

- API harus berjalan pada InfinityFree yang sama dengan database. InfinityFree
  menolak koneksi database dari aplikasi/perangkat di luar platform. Flutter
  karena itu memanggil HTTPS REST API; jangan menghubungkan Flutter langsung ke
  MySQL.
- Tidak ada SSH, terminal, perintah Artisan, Composer, npm, queue worker, atau
  cron di hosting gratis. Dependency dipasang lokal lalu diunggah via FTP.
- Seluruh schema disiapkan sekali melalui phpMyAdmin dari
  [`backend/infinityfree/schema.sql`](../backend/infinityfree/schema.sql).
  Schema sudah berisi tabel `migrations` dengan enam migration proyek ditandai
  applied; jangan jalankan `php artisan migrate` pada hosting.
- Kuota free host untuk file/inode, CPU, request dan database berlaku. Folder
  Composer `vendor` berisi banyak file; skrip membuang dependency dev dan file
  yang tak diperlukan, tetapi tetap periksa penghitung inodes/space account.
- Jangan upload data kesehatan nyata ke demo hosting ini. Jangan bagikan file
  `.env`, `APP_KEY`, atau password MySQL.

## 1. Buat website dan database

1. Daftar/login di [InfinityFree](https://www.infinityfree.com/). Buat hosting
   account baru dengan free subdomain atau domain milik sendiri.
2. Pastikan website/account berstatus aktif. Setelah account siap, catat
   informasi FTP host, username, password, dan root directory `htdocs` dari
   client area.
3. Di control panel account, pilih **MySQL Databases** dan buat database.
   Catat persis database name, username, password dan hostname yang ditampilkan.
   Nama DB/user biasanya diberi prefix oleh provider. Hostname bukan `localhost`.
4. Buka phpMyAdmin dari control panel dan pilih database tadi. Pilih tab
   **Import**, upload `backend/infinityfree/schema.sql`, lalu jalankan import.
   Pastikan muncul tabel `users`, `bowel_logs`, `personal_access_tokens`, dan
   `migrations` tanpa error.
5. Di account settings/PHP selector, pastikan runtime PHP sekurangnya 8.2
   (lebih baik 8.3) dan extensions berikut tersedia: `pdo_mysql`, `mbstring`,
   `openssl`, `fileinfo`, `tokenizer`, `xml`, `ctype`, `json`, `session`.
   PHP CLI lokal tidak menentukan versi runtime hosting.

Import SQL ini membuat schema kosong, tidak membuat akun demo. Buat akun lewat
aplikasi atau request **Register - buat akun baru** di Postman setelah API
hidup. Request ini membuat alias dan email unik otomatis. Jangan jalankan SQL
dua kali pada database yang berisi tabel—import awal ditujukan untuk database
baru.

## 2. Buat production `.env` lokal (jangan commit)

Pastikan PHP 8.3 dan Composer 2 tersedia di komputer:

```powershell
Set-Location backend
Copy-Item .env.infinityfree.example .env
composer install
php artisan key:generate
```

Edit `backend/.env` yang hanya ada di komputer lokal. Isi:

- `APP_URL`: URL HTTPS persis untuk domain/subdomain hosting.
- `DB_HOST`: hostname MySQL dari control panel (bukan `localhost`).
- `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`: nilai persis dari halaman MySQL
  Databases.
- `APP_KEY`: hasil `php artisan key:generate`.
- Biarkan `APP_ENV=production`, `APP_DEBUG=false`, `SESSION_DRIVER=file`,
  `CACHE_STORE=file`, `QUEUE_CONNECTION=sync`.

`.env` masuk `.gitignore`; jangan menyalin isinya ke chat, screenshot publik,
source, atau repository. Aplikasi memakai bearer-token API; browser session
server hanya file lokal sementara.

## 3. Buat ZIP FTP production

Skrip di `backend/scripts/prepare-infinityfree.ps1` membuat dependency production
(tanpa dev packages), mengoptimalkan autoload, menjalankan package discovery,
dan membangun ZIP untuk diunggah. `.env`, SQLite lokal, tests, log, seeders,
`.git`, dan dependency development sengaja tidak dimasukkan.

Dari root repository:

```powershell
Set-Location backend
.\scripts\prepare-infinityfree.ps1
```

ZIP dibuat di `backend/dist/jejakjamban-infinityfree-upload.zip`. Script perlu
PHP dan Composer tersedia pada `PATH`. Jika tidak:

```powershell
.\scripts\prepare-infinityfree.ps1 `
  -PhpExecutable "C:\path\to\php.exe" `
  -ComposerExecutable "C:\path\to\composer.bat"
```

Upload juga file `.env` secara terpisah melalui FTP/file manager. Jangan pernah
mengunggah `.env` ke GitHub. File `.htaccess` root yang mengarahkan request ke
`public/` otomatis disertakan di ZIP; jangan mengganti atau menghapus
`backend/public/.htaccess`.

## 4. Upload via FTP

1. Ekstrak ZIP ke komputer untuk melihat susunan file. Upload **isi** ZIP (bukan
   ZIP bersarang) langsung ke `htdocs`; file Laravel ada di root dan front
   controller berada di `htdocs/public/index.php`. Root `.htaccess` ada di
   `htdocs/.htaccess`.
2. Upload file `.env` lokal ke direktori yang sama, yaitu `htdocs/.env`.
   Tampilkan hidden/dotfiles di FTP client. `.htaccess` root mengarahkan URL
   `/.env` ke `public/.env` yang tidak ada; jangan ubah rewrite rule tersebut.
3. Tunggu proses upload selesai. Jangan upload `backend/database/database.sqlite`
   atau seluruh project Flutter.
4. Pada control panel, buka file manager/permissions bila dibutuhkan. Pastikan
   `storage/` dan `bootstrap/cache/` dapat ditulis oleh PHP; jangan ubah
   permission seluruh tree menjadi world-writable.

## 5. Tes bertahap sebelum Flutter

1. Buka `https://DOMAIN-AKTUAL/up`; Laravel seharusnya mengembalikan HTTP 200.
2. Dari Postman jalankan Login/Register dan CRUD. Collection ada di
   [`JejakJamban.postman_collection.json`](./JejakJamban.postman_collection.json).
   Gunakan akun yang dibuat pada endpoint Register; schema baru tidak memiliki
   akun demo.
3. Verifikasi GET daftar, POST log Bristol valid, GET detail, PUT, DELETE, dan
   POST Bristol invalid (HTTP 422). API perlu bearer token dari Login.
4. Tes keamanan file: request `/.env`, `/backend/.env`, `/vendor/autoload.php`
   dan `/storage/logs/laravel.log` tidak boleh menampilkan file/secret. Bila
   route Laravel semua 500, cek PHP extensions, `.env`, MySQL host/kredensial,
   versi `APP_KEY`, file upload utuh, dan writable storage. Jangan aktifkan
   `APP_DEBUG=true` secara publik.
5. Bila semua endpoint lewat Postman sukses, build APK terpisah dengan URL:

   ```powershell
   Set-Location ..
   flutter build apk --release --dart-define=API_BASE_URL=https://DOMAIN-AKTUAL/api
   ```

   Pasang APK dan uji login, tambah/edit/hapus, serta offline lalu sinkronisasi.

## 6. Schema diubah kemudian

InfinityFree tidak punya shell/Artisan untuk migrasi. Untuk perubahan schema
setelah import awal:

1. Edit migration PHP dan uji di database development MySQL lokal yang versinya
   sepadan.
2. Tulis/hasilkan SQL `ALTER TABLE`/`CREATE TABLE` yang ekuivalen; backup DB
   dahulu, lalu import SQL perubahan melalui phpMyAdmin.
3. Tambahkan nama migration yang berhasil ke tabel `migrations` dengan batch
   berikutnya. Jangan menandainya applied sebelum perubahan SQL sukses.
4. Build ulang ZIP tanpa `.env`, upload file baru melalui FTP, uji endpoint.

Jangan pakai `migrate:fresh`, `migrate:refresh`, atau `db:seed` pada data
production. Tanpa cron/queue worker, pekerjaan terjadwal/asinkron tidak cocok
untuk hosting ini; API MVP memakai request sinkron.

## Checklist bukti tugas

- [ ] URL HTTPS aktual `/up`
- [ ] Screenshot dashboard hosting/account aktif
- [ ] Screenshot phpMyAdmin dengan tabel aplikasi
- [ ] Screenshot Postman untuk GET, detail, POST, PUT, DELETE dan validasi
- [ ] Screenshot Flutter benar-benar memakai API InfinityFree
- [ ] Update URL/hosting dan hasil tes aktual di `LAPORAN-DEPLOYMENT.md`
- [ ] Export laporan sebagai PDF dan rekam video sesuai tugas

Belum ada akun atau kredensial InfinityFree yang diakses dari workspace, jadi
hosting publik belum dibuat/divalidasi. Jangan mengklaim URL live sebelum semua
tes di atas berhasil.
