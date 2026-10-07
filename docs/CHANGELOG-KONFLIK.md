# Catatan Konflik Instruksi: Tugas vs SRS

| Topik | Tugas | SRS | Keputusan |
|---|---|---|---|
| Backend | Wajib Laravel REST API dan database hosting | Supabase Auth/Postgres/Edge Functions | Mengikuti tugas. Laravel menjadi backend API; tidak menambahkan Supabase. |
| CRUD | GET, GET detail, POST, PUT/PATCH, DELETE dan validasi wajib diuji | Log BAB privat dan dapat diedit/dihapus (FR-2.4) | Resource adalah log Jejak milik pengguna; CRUD harus mempertahankan kerahasiaan data kesehatan. |
| Backend praktikum | Gunakan Laravel yang telah dibuat; buat baru hanya jika source sebelumnya tidak memenuhi/tersedia | Tidak menentukan backend praktikum | Saat analisis, folder kerja tidak memiliki source Laravel. Asumsi membuat backend baru yang sesuai tugas. |
| URL online | Backend harus dapat diakses internet; Flutter harus memakai URL deploy | SRS mengasumsikan layanan backend Supabase | Mengikuti tugas. InfinityFree dipilih sebagai target shared hosting setelah pemilik meminta gratis tanpa masa trial; hosting perlu disiapkan manual via phpMyAdmin/FTP dan belum ada deployment atau URL yang boleh diklaim aktif. |
| Bukti pengumpulan | Laporan PDF, screenshot, repository, URL, video 5–10 menit | Dokumentasi aplikasi | README dan draft laporan teknis tersedia; bukti yang memerlukan akun/rekaman asli tidak dibuat-buat dan tetap pending. |

Tidak ada konflik lain yang diketahui saat analisis. Catatan ini akan diperbarui bila ditemukan konflik baru selama implementasi.
