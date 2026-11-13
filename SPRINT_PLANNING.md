# Sprint Planning — Ter The Cut Barbershop Mobile App

Rencana pengerjaan dibagi menjadi **4 Sprint** dengan durasi masing-masing **2 minggu** (Total siklus pengembangan: 8 minggu). Tim berfokus pada implementasi arsitektur **Full Flutter** yang terhubung langsung ke **Supabase (`supabase_flutter`)**.

---

## 1. Ikhtisar Alokasi Sprint

```
[Sprint 1: Fondasi, Auth, & Master Data] (20 SP)
       │
[Sprint 2: Mesin Reservasi & Anti-Bentrok Booking] (23 SP)
       │
[Sprint 3: Loyalitas, Voucher, & Operasional Kasir] (21 SP)
       │
[Sprint 4: Feedback Read-Only, Promo, & Pemolesan Akhir] (16 SP)
```

| Sprint | Fokus Utama | Target Story Points | Periode |
|---|---|:---:|:---:|
| **Sprint 1** | Setup Proyek, Integrasi Supabase, Desain Editorial, Auth Mandiri, Master Data Cabang & Layanan | **20 SP** | Minggu 1 – 2 |
| **Sprint 2** | Booking Flow, Slot Jam Bulat, Kapster per Cabang, Auto-Assign RPC, Pembatalan | **23 SP** | Minggu 3 – 4 |
| **Sprint 3** | Member Card, Point Ledger, Penukaran Reward Atomik, Kasir Flow (Datang & Selesai Otomatis) | **21 SP** | Minggu 5 – 6 |
| **Sprint 4** | Feedback Read-Only Admin, Promo Segmen, Pencarian Pelanggan, In-App Notif, Testing & Polish | **16 SP** | Minggu 7 – 8 |
| **Total** | | **80 SP** | 8 Minggu |

---

## 2. Rincian Pelaksanaan Sprint

### Sprint 1: Fondasi, Autentikasi Mandiri, & Eksplorasi Master Data
- **Sprint Goal**: Menyelesaikan inisialisasi basis data Supabase (RLS & seed), arsitektur state management Flutter (Riverpod), tema desain Minimalist Editorial, registrasi/login mandiri tanpa SMS pihak ketiga, serta eksplorasi 11 cabang dan katalog layanan.
- **Stories yang Dikerjakan**:
  - `US-01`: Registrasi & Login Mandiri Pelanggan (5 SP)
  - `US-03`: Login Khusus Admin via Supabase Auth (3 SP)
  - `US-04`: Katalog 11 Cabang dengan Alamat Lengkap Google Maps (3 SP)
  - `US-05`: Katalog Layanan dengan Durasi Bulat 1–3 Jam (3 SP)
  - `US-06`: Katalog Inspirasi Gaya Rambut & Favorit (3 SP)
  - *Technical Task*: Eksekusi Skema Supabase SQL, Inisialisasi Riverpod, GoRouter, dan Font Playfair + Inter (3 SP)
- **Sub-task / Kegiatan Teknis**:
  1. Menjalankan DDL skema database pada Supabase SQL Editor (tabel, enum, relasi, RLS policies).
  2. Memasang dependency `supabase_flutter`, `flutter_riverpod`, `go_router`, `google_fonts`.
  3. Mengonfigurasi `Supabase.initialize(url: ..., anonKey: ...)` pada `main.dart`.
  4. Merancang sistem warna Minimalist Editorial (`#F6F2EA`, `#16130F`, `#7A2E2A`, `#8C6A2F`).
  5. Membangun halaman Login & Registrasi dengan Supabase Auth (Email/Phone + Password/PIN).
  6. Membangun halaman daftar 11 Cabang (menampilkan jam 10:00–22:00 dan alamat lengkap GMaps).
  7. Membangun layar katalog layanan per kategori (*Hair Cut*, *Care Treatment*, *Texture Services*).
- **Definition of Done (DoD) Sprint 1**:
  - Pengguna dapat sign up dan sign in langsung melalui Supabase Auth.
  - Sesi login tersimpan secara aman dan ter-redirect sesuai role (`customer` atau `admin`).
  - Halaman cabang menampilkan 11 cabang dengan alamat lengkap dari Supabase.
  - Seluruh komponen mengikuti standar kontras tipografi WCAG AA.

---

### Sprint 2: Core Booking Engine & Penanganan Bentrok Jadwal
- **Sprint Goal**: Mengimplementasikan 6-tahap alur booking layanan pada aplikasi Flutter dengan verifikasi slot jam bulat 1 jam dan algoritma auto-assign kapster tanpa risiko double booking.
- **Stories yang Dikerjakan**:
  - `US-07`: Pemilihan Kapster (2 Kapster per Cabang atau opsi Bebas / Auto) (5 SP)
  - `US-08`: Pemilihan Tanggal (H+0 s.d. H+4) & Grid Slot Jam Bulat 10:00–21:00 (8 SP)
  - `US-09`: Konfirmasi Booking & Auto-Assign via RPC `create_booking_auto` (5 SP)
  - `US-10`: Manajemen Booking Pelanggan & Pembatalan Minimal 2 Jam Sebelumnya (5 SP)
- **Sub-task / Kegiatan Teknis**:
  1. Membuat stepper wizard booking 6 langkah di Flutter.
  2. Menghubungkan pemilihan kapster dengan query `barbers` berdasarkan `branch_id`.
  3. Membangun kalkulator ketersediaan slot jam di Flutter:
     - Mengambil rentang booking aktif pada tanggal yang dipilih.
     - Menyaring slot jam yang memiliki waktu cukup sesuai `duration_hours` layanan.
     - Menonaktifkan jam yang telah terisi atau melebihi jam 22:00.
  4. Menghubungkan konfirmasi booking dengan fungsi RPC Supabase `create_booking_auto`.
  5. Menangani penolakan *concurrency* (`EXCLUSION CONSTRAINT` PostgreSQL) dengan menampilkan notifikasi bahwa jam baru saja diambil orang lain.
  6. Membangun layar 'Booking Saya' (Upcoming & History) dengan aksi pembatalan valid.
- **Definition of Done (DoD) Sprint 2**:
  - Pelanggan berhasil membuat booking dengan kapster spesifik maupun mode auto-assign.
  - Tidak ada durasi layanan dengan pecahan menit; seluruh slot konsisten jam bulat.
  - Uji bentrok: Dua perangkat memesan kapster dan jam yang sama secara bersamaan; 1 berhasil, 1 ditolak rapi dengan pesan jelas.
  - Pelanggan dapat membatalkan booking yang berjarak > 2 jam dari jadwal.

---

### Sprint 3: Sistem Loyalitas, Voucher Reward, & Kasir Otomatis
- **Sprint Goal**: Mengembangkan ekosistem loyalitas pelanggan (member card digital, tier, akumulasi poin, penukaran voucher) dan alur kerja admin/kasir untuk menandai Datang dan Selesai secara otomatis.
- **Stories yang Dikerjakan**:
  - `US-02`: Beranda Member Card, Saldo Poin & Badge Tier (3 SP)
  - `US-11`: Riwayat Kunjungan & Mutasi Poin (Point Ledger) (3 SP)
  - `US-12`: Penukaran Poin dengan Voucher Reward Atomik via RPC (5 SP)
  - `US-13`: Dompet Voucher Reward Pelanggan (3 SP)
  - `US-18`: Jadwal Harian Admin per Cabang (5 SP)
  - `US-19`: Admin Kasir: Tandai Datang & Selesai Otomatis via RPC `complete_booking` (5 SP)
- **Sub-task / Kegiatan Teknis**:
  1. Merancang widget Member Card mewah di Beranda (Playfair Display, aksen emas vintage).
  2. Menghubungkan perhitungan tier dinamis: Bronze (0–99), Silver (100–299), Gold (≥300 poin).
  3. Membangun layar katalog Reward dan memanggil RPC `redeem_reward` di Supabase.
  4. Membuat layar 'Voucher Saya' yang menampilkan kode voucher dan masa berlaku 30 hari.
  5. Membangun dashboard jadwal admin dengan filter cabang dan tanggal.
  6. Menghubungkan tombol aksi kasir 'Selesai' ke RPC `complete_booking`:
     - Memastikan status booking berubah menjadi `completed`.
     - Memverifikasi tabel `transactions` dan `point_ledger` terisi secara otomatis.
- **Definition of Done (DoD) Sprint 3**:
  - Saldo poin berkurang secara atomik saat reward ditukarkan; voucher unik terbit.
  - Admin dapat memantau jadwal pelanggan per cabang secara real-time.
  - Menekan 'Selesai' di layar kasir otomatis membukukan transaksi dan menambahkan poin pelanggan tanpa input nominal manual.

---

### Sprint 4: Suara Pelanggan, Promo, In-App Notif, & Pemolesan Akhir
- **Sprint Goal**: Melengkapi modul masukan pelanggan (baca-saja bagi admin), manajemen promo segmen, in-app notif, pengujian fungsional menyeluruh, dan optimasi performa rilis.
- **Stories yang Dikerjakan**:
  - `US-14`: Formulir Kritik & Saran Pelanggan (3 SP)
  - `US-15`: Layar Baca Masukan Pelanggan untuk Admin (Read-Only) (3 SP)
  - `US-16`: Tampilan Banner Promo di Beranda Pelanggan (3 SP)
  - `US-17`: Form Input Promo oleh Admin (3 SP)
  - `US-20`: Pencarian Cepat Data Pelanggan oleh Kasir (3 SP)
  - `US-21`: Riwayat Notifikasi In-App (3 SP)
  - *Technical Task*: Audit Aksesibilitas, Empty States, Error Handling, & Build APK Release (2 SP)
- **Sub-task / Kegiatan Teknis**:
  1. Membangun form input kritik & saran pada menu profil pelanggan.
  2. Membangun layar admin masukan: murni daftar teks riwayat kritik & saran tanpa tombol ubah status.
  3. Mengimplementasikan fitur pencarian pelanggan dengan debounce 300 ms untuk kasir.
  4. Menampilkan banner promo aktif di beranda pelanggan.
  5. Membuat form penambahan promo baru pada sisi admin.
  6. Membangun pusat notifikasi in-app untuk mengamati riwayat transaksi dan poin.
  7. Menangani skenario offline/error (tombol coba lagi, shimmer loading, empty state).
  8. Uji coba APK di perangkat Android fisik.
- **Definition of Done (DoD) Sprint 4**:
  - Admin dapat membaca seluruh kritik & saran tanpa ada dropdown/status tindakan.
  - Pencarian pelanggan responsif di bawah 1 detik.
  - Seluruh alur (Pelanggan booking -> Kasir selesai -> Poin bertambah -> Pelanggan tukar reward) berjalan mulus tanpa kendala.
  - Aplikasi siap didemonstrasikan untuk laporan akhir praktikum mobile.

---

## 3. Rangkuman Target Akhir Pengembangan

1. **Stabilitas Basis Data**: Berjalan langsung di Supabase cloud dengan Row Level Security (RLS) aktif, memproteksi data tanpa perlu server perantara.
2. **Kesesuaian Desain**: Menerapkan gaya Minimalist Editorial secara konsisten di seluruh layar pelanggan dan admin.
3. **Kepatuhan Aturan Bisnis**: Memenuhi 100% spesifikasi yang telah disepakati (11 cabang dengan alamat nyata GMaps, 2 kapster tetap per cabang, durasi jam bulat tanpa menit, feedback read-only, dan registrasi mandiri).

