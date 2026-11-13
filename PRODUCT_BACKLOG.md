# Product Backlog — Ter The Cut Barbershop Mobile App

Dokumen Product Backlog ini disusun menggunakan kerangka kerja **Scrum / Agile**. Setiap User Story dilengkapi dengan format *"Sebagai [Role], saya ingin [Tindakan], sehingga [Manfaat]"*, kriteria penerimaan (Acceptance Criteria), estimasi bobot (*Story Points* menggunakan deret Fibonacci 1, 2, 3, 5, 8, 13), serta prioritas MoSCoW (*Must Have, Should Have, Could Have*).

---

## 1. Ringkasan Epics

| Epic ID | Nama Epic | Deskripsi Singkat |
|---|---|---|
| **EPC-01** | Autentikasi & Akun Pengguna | Pendaftaran, login pelanggan & admin langsung via Supabase Auth, dan manajemen profil. |
| **EPC-02** | Master Data & Eksplorasi | Katalog 11 cabang, kapster per cabang, layanan (durasi bulat), dan katalog gaya rambut. |
| **EPC-03** | Reservasi & Booking Jadwal | Alur pemesanan jadwal 1 jam bulat, pemilihan kapster / auto-assign, dan manajemen booking. |
| **EPC-04** | Loyalitas, Poin & Reward | Kartu keanggotaan digital, akumulasi poin atomik, progres tier, dan penukaran voucher reward. |
| **EPC-05** | Suara Pelanggan & Promo | Pengiriman feedback pelanggan (baca-saja bagi admin) dan penyusunan promo berbasis segmen. |
| **EPC-06** | Operasional Admin & Kasir | Manajemen jadwal harian cabang, status Datang/Selesai, pencatatan otomatis, dan pencarian pelanggan. |

---

## 2. Tabel Product Backlog

| Story ID | Epic | User Story | Prioritas | Bobot (SP) | Ref FR |
|---|---|---|:---:|:---:|:---:|
| **US-01** | EPC-01 | **Sebagai** pelanggan, **saya ingin** mendaftar dan masuk menggunakan nomor telepon/email dan password, **sehingga** saya memiliki akun keanggotaan tanpa perlu menunggu verifikasi SMS pihak ketiga. | Must Have | 5 | FR-01 |
| **US-02** | EPC-01 | **Sebagai** pelanggan, **saya ingin** melihat kartu keanggotaan digital saya beserta saldo poin dan tier (Bronze/Silver/Gold) di beranda, **sehingga** saya mengetahui status loyalitas saya. | Must Have | 3 | FR-02 |
| **US-03** | EPC-01 | **Sebagai** admin, **saya ingin** login ke aplikasi dengan akun khusus staf, **sehingga** saya diarahkan langsung ke dashboard kasir/manajemen cabang. | Must Have | 3 | FR-13 |
| **US-04** | EPC-02 | **Sebagai** pelanggan, **saya ingin** melihat daftar 11 cabang Ter The Cut dengan alamat lengkap dan jam operasionalnya, **sehingga** saya dapat memilih cabang terdekat. | Must Have | 3 | FR-10 |
| **US-05** | EPC-02 | **Sebagai** pelanggan, **saya ingin** melihat katalog layanan lengkap dengan harga dan durasi jam bulatnya (1–3 jam), **sehingga** saya paham rincian biaya dan waktu layanan. | Must Have | 3 | FR-10 |
| **US-06** | EPC-02 | **Sebagai** pelanggan, **saya ingin** menjelajahi katalog inspirasi gaya rambut dan menyimpannya ke favorit, **sehingga** saya dapat menunjukkannya kepada kapster saat berkunjung. | Should Have | 3 | FR-07 |
| **US-07** | EPC-03 | **Sebagai** pelanggan, **saya ingin** memilih 1 dari 2 kapster di cabang terpilih atau memilih opsi 'Bebas / Auto', **sehingga** saya fleksibel menentukan siapa yang mencukur saya. | Must Have | 5 | FR-10 |
| **US-08** | EPC-03 | **Sebagai** pelanggan, **saya ingin** memilih tanggal (H+0 s.d. H+4) dan melihat grid slot jam bulat 1 jam yang tersedia, **sehingga** saya tidak memilih jam yang sudah penuh. | Must Have | 8 | FR-10 |
| **US-09** | EPC-03 | **Sebagai** pelanggan, **saya ingin** mengonfirmasi pemesanan saya dan mendapatkan kode booking resmi, **sehingga** reservasi saya tercatat pasti di sistem tanpa bentrok jadwal. | Must Have | 5 | FR-10 |
| **US-10** | EPC-03 | **Sebagai** pelanggan, **saya ingin** melihat daftar booking saya yang akan datang serta membatalkan booking (minimal 2 jam sebelumnya), **sehingga** jadwal dapat dilepas jika saya berhalangan. | Should Have | 5 | FR-12 |
| **US-11** | EPC-04 | **Sebagai** pelanggan, **saya ingin** melihat riwayat kunjungan dan mutasi poin (point ledger), **sehingga** saya tahu perolehan dan penggunaan poin saya. | Must Have | 3 | FR-03 |
| **US-12** | EPC-04 | **Sebagai** pelanggan, **saya ingin** menukarkan poin saya dengan voucher reward secara langsung di aplikasi, **sehingga** saya memperoleh kode voucher diskon atau gratis layanan. | Must Have | 5 | FR-04 |
| **US-13** | EPC-04 | **Sebagai** pelanggan, **saya ingin** melihat daftar kode voucher yang sudah saya tukarkan beserta tanggal kedaluwarsanya, **sehingga** dapat saya tunjukkan ke kasir saat membayar. | Must Have | 3 | FR-04 |
| **US-14** | EPC-05 | **Sebagai** pelanggan, **saya ingin** mengirimkan kritik dan saran (feedback) mengenai pelayanan barbershop, **sehingga** aspirasi saya tersampaikan kepada manajemen. | Should Have | 3 | FR-08 |
| **US-15** | EPC-05 | **Sebagai** admin, **saya ingin** membaca seluruh kritik dan saran yang masuk dari pelanggan secara terpusat (read-only), **sehingga** dapat mengevaluasi kualitas staf dan layanan. | Should Have | 3 | FR-17 |
| **US-16** | EPC-05 | **Sebagai** pelanggan, **saya ingin** melihat banner promo menarik yang sedang berlangsung di beranda aplikasi, **sehingga** saya mengetahui penawaran hemat terbaru. | Should Have | 3 | FR-06 |
| **US-17** | EPC-05 | **Sebagai** admin, **saya ingin** membuat dan mengatur periode promo untuk segmen pelanggan tertentu, **sehingga** promo dapat disalurkan secara tepat sasaran. | Could Have | 3 | FR-18 |
| **US-18** | EPC-06 | **Sebagai** admin/kasir, **saya ingin** melihat daftar jadwal booking hari ini yang terurut per jam untuk cabang saya, **sehingga** operasional harian terpantau rapi. | Must Have | 5 | FR-19 |
| **US-19** | EPC-06 | **Sebagai** admin/kasir, **saya ingin** menandai booking pelanggan menjadi 'Datang' saat tiba dan 'Selesai' saat pengerjaan beres, **sehingga** transaksi dan penambahan poin pelanggan tercatat otomatis tanpa hitung manual. | Must Have | 5 | FR-19 |
| **US-20** | EPC-06 | **Sebagai** admin/kasir, **saya ingin** mencari data pelanggan berdasarkan nama atau nomor telepon (read-only), **sehingga** dapat memeriksa keanggotaan dan riwayat saat pelanggan datang walk-in. | Must Have | 3 | FR-14 |
| **US-21** | EPC-01 | **Sebagai** pelanggan, **saya ingin** menerima notifikasi di dalam aplikasi (in-app notifications) saat booking berhasil dan poin bertambah, **sehingga** saya mendapat kepastian instan. | Should Have | 3 | FR-05 |

**Total Story Points: 80 SP**

---

## 3. Rincian Kriteria Penerimaan (Acceptance Criteria)

### US-01: Registrasi & Login Mandiri
- **Given** pengguna belum masuk, **When** mengisi email/nomor telepon dan password pada form registrasi/login, **Then** Supabase Auth membuat sesi akun valid.
- Profil baru otomatis terbuat di tabel `profiles` via database trigger dengan `role = 'customer'` dan `points_balance = 0`.
- Menolak pendaftaran dengan format email/telepon yang tidak valid atau password kurang dari 6 karakter.

### US-07 & US-08: Pemilihan Kapster & Grid Jam Bulat
- **Given** pelanggan telah memilih salah satu dari 11 cabang, **When** masuk ke langkah kapster, **Then** sistem hanya menampilkan 2 nama kapster yang bertugas di cabang tersebut ditambah tombol "Bebas / Auto-Assign".
- **Given** layanan yang dipilih memiliki durasi 2 jam (2 slot), **When** pelanggan memilih jam, **Then** grid hanya mengaktifkan jam yang memiliki minimal 2 slot berurutan kosong (misal 14:00–16:00).
- Jam yang telah lewat dari waktu saat ini atau melebihi jam tutup cabang (22:00) wajib berstatus *disabled* dan dicoret.

### US-09: Anti-Double Booking via Auto-Assign RPC
- **Given** pelanggan memilih opsi 'Bebas / Auto-Assign', **When** menekan 'Konfirmasi Booking', **Then** fungsi database `create_booking_auto` mencari kapster yang kosong dan memilih kapster dengan total jadwal paling sedikit hari itu.
- Jika terjadi bentrok bersamaan dengan pelanggan lain (*race condition*), PostgreSQL `EXCLUSION CONSTRAINT` menolak salah satu transaksi secara aman dan mengembalikan pesan bahwa slot telah terisi.

### US-12: Penukaran Poin dengan Voucher
- Tombol 'Tukar Reward' hanya aktif jika `points_balance >= points_cost`.
- Menampilkan dialog konfirmasi sebelum penukaran poin.
- Saat ditukar, fungsi RPC `redeem_reward` memotong saldo poin dan menerbitkan record `reward_redemptions` dengan kode voucher unik (format `REW-XXXXXX`).

### US-15: Feedback Pelanggan (Read-Only Admin)
- Admin memiliki menu khusus 'Kritik & Saran'.
- Menampilkan daftar feedback pelanggan yang memuat nama pengirim, tanggal, dan isi pesan teks secara kronologis terbalik (terbaru di atas).
- Tidak ada tombol atau dropdown perubahan status apa pun di layar admin (bersifat murni baca saja).

### US-19: Kasir Menandai Selesai & Pencatatan Transaksi Otomatis
- Admin dapat menekan tombol aksi 'Datang' (`arrived`) dan 'Selesai' (`completed`).
- Ketika tombol 'Selesai' ditekan, sistem mengeksekusi RPC `complete_booking`:
  1. Status booking berubah menjadi `completed`.
  2. Data baru terbuat pada tabel `transactions`.
  3. Saldo `points_balance` dan `lifetime_points` di tabel `profiles` bertambah sesuai poin layanan.
  4. Baris mutasi poin tercatat di `point_ledger`.
  5. Notifikasi in-app terkirim ke pelanggan.

