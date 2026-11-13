# PRD — Ter The Cut Barbershop Mobile App (Flutter & Supabase)

| Metadata | Keterangan |
|---|---|
| **Versi** | 2.0 (Direct Supabase Backend) |
| **Tanggal** | 13 November 2026 |
| **Sumber** | Laporan Final Project DPP — Ter The Cut Barbershop |
| **Platform** | Android (Flutter murni, tanpa kode native kustom) |
| **Backend** | Full Flutter murni langsung ke **Supabase** via `supabase_flutter` (Database PostgreSQL, Supabase Auth, Row Level Security / RLS, Stored Procedures / RPC, Realtime) |
| **Desain** | Minimalist Editorial — klasik, bersih, tipografi elegan (Playfair Display + Inter) |

---

## 1. Ringkasan

Aplikasi mobile CRM untuk **Ter The Cut Barbershop** (satu brand barbershop dengan 11 lokasi cabang di Yogyakarta & Sleman). Pelanggan dapat melihat status keanggotaan dan poin, memesan jadwal (memilih kapster cabang atau auto-assign), memilih gaya rambut, menukar voucher reward, serta mengirim kritik dan saran. Admin/kasir mengelola jadwal booking (menandai Datang/Selesai), membaca masukan pelanggan, mencari data pelanggan, dan menyusun promo.

Arsitektur aplikasi menggunakan **Full Flutter** yang berkomunikasi langsung ke **Supabase** menggunakan paket resmi `supabase_flutter`. Seluruh integritas data, aturan anti-double booking, kalkulasi poin atomik, dan keamanan akses data ditangani oleh PostgreSQL (Exclusion Constraints, Triggers, RLS, dan RPC Stored Functions).

### 1.1 Keputusan Kebutuhan & Koreksi

| Aspek | Ketetapan | Dampak Implementasi |
|---|---|---|
| **Arsitektur Backend** | Full Flutter + `supabase_flutter` | Tidak ada server custom (Node.js/Fastify dihapus). Flutter langsung berinteraksi dengan Supabase client SDK dengan Row Level Security (RLS) & RPC. |
| **Cabang & Kapster** | 1 Brand Barbershop, 11 Cabang, 2 Kapster per Cabang | Setiap cabang memiliki 2 kapster tetap yang berbeda (total 22 kapster). Relasi `barbers.branch_id` langsung mengikat kapster ke cabang tertentu. |
| **Durasi Layanan** | Dibulatkan penuh per 1 jam (tanpa menit) | Seluruh layanan berdurasi bilangan bulat jam (1 jam = 1 slot, 2 jam = 2 slot, dst.). Slot waktu seragam kelipatan jam (10:00, 11:00, ..., 21:00). |
| **Feedback Pelanggan** | Baca saja (Read-only) bagi Admin | Tabel `feedbacks` tidak memiliki status tindak lanjut. Admin hanya bisa membaca masukan pelanggan tanpa aksi pengubahan status. |
| **Autentikasi** | Supabase Native Auth (tanpa SMS/WA gateway pihak ketiga) | Pelanggan mendaftar dan masuk menggunakan Email/Telepon + Password/PIN secara mandiri via Supabase Auth tanpa ketergantungan API pihak ketiga (Twilio/Wablas/Fonnte). |
| **Alamat Cabang** | Lengkap sesuai GMaps | 11 alamat cabang Ter The Cut di Yogyakarta & Sleman telah dilengkapi secara akurat. |
| **Pembayaran** | Di luar aplikasi (FR-11 ditiadakan) | Booking langsung berstatus `confirmed`. Pembayaran dilakukan langsung di kasir (tunai/QRIS) saat layanan selesai. |
| **Pencatatan Transaksi** | Otomatis saat booking `completed` (FR-15 ditiadakan) | Admin tidak menginput transaksi manual. Ketika admin menandai booking "Selesai", fungsi atomik RPC membuat transaksi dan menambah poin pelanggan. |
| **Penukaran Reward** | Mandiri oleh pelanggan (FR-16 ditiadakan) | Pelanggan menukar poin dengan kode voucher langsung di aplikasi. Kasir memeriksa kode voucher secara fisik saat pembayaran. |

---

## 2. Tujuan & Indikator Keberhasilan

| Tujuan | Indikator Keberhasilan |
|---|---|
| Meningkatkan frekuensi kunjungan & retensi | Rata-rata kunjungan per pelanggan meningkat; jumlah penukaran reward aktif meningkat |
| Efisiensi reservasi mandiri | 100% booking terhindar dari bentrok jadwal (zero double-booking); antrean walk-in berkurang |
| Transparansi loyalitas pelanggan | Pelanggan dapat memantau akumulasi poin dan progres tier (Bronze, Silver, Gold) secara real-time |
| Suara pelanggan terdengar langsung | Seluruh masukan pelanggan terekam rapi dan dapat dibaca langsung oleh admin secara terpusat |
| Otomasi operasional kasir | 100% transaksi dan poin kunjungan tercatat otomatis tanpa kesalahan hitung manual kasir |

---

## 3. Pengguna & Hak Akses

Aplikasi memiliki dua peran dalam satu paket Flutter dengan navigasi terpisah berdasarkan profil pengguna di Supabase:

| Peran | Profil Pengguna | Hak Akses Utama |
|---|---|---|
| **Pelanggan** | Pria & wanita usia 17–35 tahun pelanggan Ter The Cut | Registrasi/Login, melihat kartu member & saldo poin, riwayat kunjungan, booking jadwal, katalog gaya rambut, tukar voucher reward, kirim feedback |
| **Admin / Kasir** | Staf cabang / pengelola barbershop | Login admin, melihat jadwal booking hari ini per cabang, menandai status Datang (`arrived`) dan Selesai (`completed`), mencari data pelanggan, membaca feedback, membuat promo |

---

## 4. Lingkup Kebutuhan Fungsional (FR)

### 4.1 Fitur Pelanggan

| ID | Fitur | Prioritas | Detail Implementasi via `supabase_flutter` |
|---|---|---|---|
| **FR-01** | Registrasi & Login Mandiri | Must | Supabase Auth (Email / Telepon + Password/PIN). Profil pelanggan otomatis terbuat via trigger `handle_new_user()`. |
| **FR-02** | Beranda: Member Card & Poin | Must | Menampilkan kartu digital keanggotaan, tier badge (Bronze/Silver/Gold), saldo poin, dan progres menuju reward berikutnya. |
| **FR-03** | Riwayat Kunjungan & Ledger Poin | Must | Mengambil data riwayat transaksi dan log mutasi poin dari tabel `transactions` dan `point_ledger`. |
| **FR-04** | Katalog Reward & Penukaran Voucher | Must | Daftar reward aktif. Penukaran poin memanggil RPC `redeem_reward` (atomik memotong poin dan menerbitkan `voucher_code`). |
| **FR-05** | Notifikasi / Pengingat Jadwal | Should | Riwayat notifikasi di dalam aplikasi (in-app notifications) untuk konfirmasi booking dan perubahan poin. |
| **FR-06** | Banner Promo Segmen Pelanggan | Should | Menampilkan promo aktif yang relevan berdasarkan riwayat kunjungan (Aktif, Berisiko, Nonaktif). |
| **FR-07** | Katalog Gaya Rambut & Favorit | Should | Eksplorasi katalog gaya rambut; pelanggan dapat menandai dan menyimpan gaya rambut favorit. |
| **FR-08** | Formulir Kritik & Saran | Should | Mengirimkan pesan feedback (pesan teks 5–1000 karakter) ke tabel `feedbacks`. |
| **FR-09** | Profil & Pengaturan | Could | Melihat data diri, preferensi gaya rambut tersimpan, dan logout. |
| **FR-10** | Alur Booking Layanan | Must | Memilih cabang (11 cabang), memilih kapster (atau auto-assign), memilih layanan, tanggal (H+0 s.d. H+4), dan jam sesi bulat 1 jam. |
| **FR-12** | Kelola Booking (Lihat, Jadwal Ulang, Batal) | Should | Melihat booking aktif; pembatalan mandiri diizinkan maksimal 2 jam sebelum jam mulai. |

### 4.2 Fitur Admin / Kasir

| ID | Fitur | Prioritas | Detail Implementasi via `supabase_flutter` |
|---|---|---|---|
| **FR-13** | Login Khusus Admin | Must | Login menggunakan kredensial admin. Sistem memeriksa role `admin` di profil Supabase. |
| **FR-14** | Pencarian Pelanggan | Must | Pencarian cepat pelanggan berdasarkan nama atau nomor telepon (debounce 300 ms, query `ilike`). Profil bersifat baca saja. |
| **FR-17** | Baca Kritik & Saran (Feedback) | Should | **Read-only**: Menampilkan seluruh daftar masukan pelanggan secara kronologis untuk evaluasi kualitas pelayanan. |
| **FR-18** | Buat & Kelola Promo | Could | Form pembuatan promo baru: judul, deskripsi, gambar, target segmen, dan tanggal berlaku. |
| **FR-19** | Kelola Jadwal Booking & Kasir | Must | Filter jadwal per cabang dan tanggal. Mengubah status booking: **Datang** (`arrived`) dan **Selesai** (`completed`). Saat selesai, memanggil RPC `complete_booking` untuk pembukuan transaksi dan penerbitan poin otomatis. |

---

## 5. Alur Bisnis & Aturan Booking

### 5.1 Tahapan Pemesanan oleh Pelanggan

```
[Pilih Cabang (11 Cabang)] 
          ↓
[Pilih Kapster Cabang (2 Kapster atau "Bebas / Auto")] 
          ↓
[Pilih Layanan (Durasi 1–3 Jam Bulat)] 
          ↓
[Pilih Tanggal (Hari ini s.d. H+4)] 
          ↓
[Pilih Jam (Grid Sesi 1 Jam: 10:00 - 21:00)] 
          ↓
[Pilih Gaya Rambut (Opsional)] 
          ↓
[Konfirmasi Booking] → Status 'confirmed'
```

### 5.2 Aturan Ketersediaan Slot & Auto-Assign Kapster

1. **Jam Operasional**: Seragam seluruh cabang, pukul 10:00 – 22:00 WIB.
2. **Durasi Slot**: Seluruh layanan memiliki durasi jam bulat (tanpa menit):
   - Layanan 1 jam membutuhkan **1 slot** (misal 14:00 - 15:00).
   - Layanan 2 jam membutuhkan **2 slot berurutan** (misal 14:00 - 16:00).
   - Layanan 3 jam membutuhkan **3 slot berurutan** (misal 14:00 - 17:00).
   - Slot mulai terakhir yang diizinkan untuk layanan 1 jam adalah 21:00. Layanan 2 jam maksimal mulai pukul 20:00.
3. **Pilihan Kapster**:
   - Jika pelanggan memilih **Kapster Tertentu** (dari 2 kapster di cabang tersebut): slot jam aktif jika kapster tersebut tidak memiliki booking berstatus `confirmed` atau `arrived` pada jam-jam yang dibutuhkan.
   - Jika memilih **Bebas / Auto-Assign**: slot jam aktif jika **minimal salah satu dari 2 kapster** di cabang tersebut kosong pada jam tersebut. Saat dikonfirmasi, sistem secara otomatis memilih kapster yang kosong dengan beban booking paling sedikit pada hari itu.
4. **Pencegahan Double-Booking (Concurrency)**:
   Dijamin pada level basis data menggunakan PostgreSQL `EXCLUSION CONSTRAINT` dengan ekstensi `btree_gist`. Jika dua pelanggan mengonfirmasi jam yang sama secara simultan, database menjamin hanya satu yang berhasil dan satu lainnya menerima feedback bahwa slot telah terisi.

### 5.3 Siklus Status Booking

```
confirmed (Terkonfirmasi)
   │
   ├── [Pelanggan Tiba] ──> arrived (Datang)
   │                           │
   │                           └── [Layanan Selesai] ──> completed (Selesai)*
   │
   ├── [Batal oleh Pelanggan / Admin] ──> cancelled (Dibatalkan)
   └── [Tidak Hadir] ─────────────────> no_show (Tidak Hadir)
```
*\*Ketika status berubah menjadi `completed`, trigger / fungsi RPC `complete_booking` otomatis membuat baris pada `transactions` dan menambahkan poin ke `customers`.*

---

## 6. Data Master & Seed

### 6.1 Data 11 Cabang Ter The Cut (Alamat Lengkap Berdasarkan Google Maps)

Jam operasional seluruh cabang: **10:00 – 22:00 WIB**.

| # | Nama Cabang | Alamat Lengkap (Google Maps) | Kota/Kabupaten |
|---|---|---|---|
| 1 | **Cabang Warungboto** | Jl. Prof. DR. Soepomo SH No. 55, Warungboto, Kec. Umbulharjo | Kota Yogyakarta |
| 2 | **Cabang Tajem (Maguwoharjo)** | Jl. Stadion No. 34 / Jl. Raya Tajem, Denokan, Maguwoharjo, Kec. Depok | Kab. Sleman |
| 3 | **Cabang Soragan** | Jl. Soragan No. 80, Cungkuk, Ngestiharjo, Kec. Kasihan | Kab. Bantul |
| 4 | **Cabang Palagan** | Jl. Palagan Tentara Pelajar No. 88, Mudal, Sariharjo, Kec. Ngaglik | Kab. Sleman |
| 5 | **Cabang Mrican 2 (Pringwulung)** | Jl. Tantular No. 440, Pringwulung, Condongcatur, Kec. Depok | Kab. Sleman |
| 6 | **Cabang Mrican 1 (Demangan)** | Jl. Brojomusti, Jl. Pringgodani No. 3, Demangan / Caturtunggal, Kec. Depok | Kab. Sleman |
| 7 | **Cabang Godean** | Jl. Godean Km. 4.5 (Jl. Sidoarum - Bantulan No. 43), Bantulan, Sidoarum, Kec. Godean | Kab. Sleman |
| 8 | **Cabang Gedongkiwo** | Jl. Bantul No. 74B, Gedongkiwo, Kec. Mantrijeron | Kota Yogyakarta |
| 9 | **Cabang Gamping** | Jl. Pasir No. 1 / Jl. Wates Km. 5, Ambarketawang, Kec. Gamping | Kab. Sleman |
| 10 | **Cabang Concat (Condongcatur)** | Jl. Nusa Indah / Jl. Anggajaya, Condongcatur, Kec. Depok | Kab. Sleman |
| 11 | **Cabang Candi Gebang** | Jl. Candi Gebang No. 5, Jetis, Wedomartani, Kec. Ngemplak | Kab. Sleman |

### 6.2 Data Layanan (Durasi Dibulatkan ke Jam Penuh, Tanpa Menit)

| Kategori | Nama Layanan | Harga (Rp) | Durasi | Slot Dibutuhkan | Poin |
|---|---|---:|---|:---:|:---:|
| **Hair Cut** | Premium Haircut | 35.000 | 1 Jam | 1 Slot | 10 |
| | Signature VIP Haircut | 65.000 | 1 Jam | 1 Slot | 10 |
| **Face & Hair Care Treatment** | Facial Treatment | 55.000 | 1 Jam | 1 Slot | 10 |
| | Hair Mask - Short Hair | 35.000 | 1 Jam | 1 Slot | 10 |
| | Creambath - Short Hair | 50.000 | 1 Jam | 1 Slot | 10 |
| | Creambath - Medium Hair | 60.000 | 1 Jam | 1 Slot | 10 |
| **Texture Services** | Down Perm - Short Hair | 150.000 | 1 Jam | 1 Slot | 25 |
| | Bye-Bye Pomade - Normal Hair | 125.000 | 1 Jam | 1 Slot | 25 |
| | Texture Perm Wavy (Men) - Short Hair | 200.000 | 2 Jam | 2 Slot | 25 |
| | Texture Perm Wavy (Men) - Medium Hair | 300.000 | 2 Jam | 2 Slot | 50 |
| | Texture Perm Wavy (Men) - Long Hair | 500.000 | 2 Jam | 2 Slot | 50 |
| | Design Perm - 1.0 | 350.000 | 2 Jam | 2 Slot | 50 |
| | Design Perm - 2.0 | 500.000 | 2 Jam | 2 Slot | 50 |
| | Texture Perm (Women) - Short Hair | 300.000 | 2 Jam | 2 Slot | 50 |
| | Texture Perm (Women) - Medium Hair | 400.000 | 3 Jam | 3 Slot | 50 |
| | Texture Perm Curly (Men) - Short Hair | 200.000 | 2 Jam | 2 Slot | 25 |
| | Texture Perm Curly (Men) - Medium Hair | 300.000 | 3 Jam | 3 Slot | 50 |
| | Texture Perm Curly (Men) - Long Hair | 500.000 | 3 Jam | 3 Slot | 50 |

### 6.3 Data Kapster (2 Kapster Khusus di Setiap Cabang)

Setiap cabang memiliki 2 orang kapster tetap (total 22 kapster di sistem):

| Cabang | Kapster 1 | Kapster 2 |
|---|---|---|
| Cabang Warungboto | Bagas (Warungboto) | Rian (Warungboto) |
| Cabang Tajem | Fajar (Tajem) | Dimas (Tajem) |
| Cabang Soragan | Doni (Soragan) | Gilang (Soragan) |
| Cabang Palagan | Hendra (Palagan) | Satria (Palagan) |
| Cabang Mrican 2 | Bayu (Mrican 2) | Angga (Mrican 2) |
| Cabang Mrican 1 | Reza (Mrican 1) | Ilham (Mrican 1) |
| Cabang Godean | Wahyu (Godean) | Pandu (Godean) |
| Cabang Gedongkiwo | Yusuf (Gedongkiwo) | Tegar (Gedongkiwo) |
| Cabang Gamping | Aris (Gamping) | Bima (Gamping) |
| Cabang Concat | Aldi (Concat) | Farhan (Concat) |
| Cabang Candi Gebang | Rio (Candi Gebang) | Danang (Candi Gebang) |

---

## 7. Skema Database Supabase (PostgreSQL DDL)

Skema ini siap dieksekusi langsung di **Supabase SQL Editor**. Mengimplementasikan relasi cabang, kapster per cabang, durasi jam bulat, feedback baca-saja, RPC booking, serta Row Level Security (RLS) untuk Flutter client.

```sql
-- ============================================================================
-- DATABASE SCHEMA: TER THE CUT BARBERSHOP (SUPABASE POSTGRESQL)
-- ============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";

-- ENUMS
create type user_role as enum ('customer', 'admin');
create type booking_status as enum ('confirmed', 'arrived', 'completed', 'cancelled', 'no_show');
create type barber_pref as enum ('chosen', 'auto');
create type customer_segment as enum ('active', 'at_risk', 'inactive');
create type notif_type as enum ('schedule', 'reward', 'promo', 'booking', 'system');
create type ledger_reason as enum ('visit', 'redeem', 'adjustment');

-- HELPER FUNCTIONS
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 1. PROFILES & AKUN (Terhubung ke auth.users Supabase)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'customer',
  phone text unique,
  name text,
  points_balance int not null default 0 check (points_balance >= 0),
  lifetime_points int not null default 0 check (lifetime_points >= 0),
  last_visit_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_upd before update on profiles
  for each row execute function set_updated_at();

-- Trigger otomatis pembuatan profil saat user sign up via Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, phone, name, role)
  values (
    new.id,
    new.phone,
    coalesce(new.raw_user_meta_data->>'name', 'Pelanggan'),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'customer')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. CABANG (11 Cabang Barbershop)
create table branches (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  address text not null,
  city text not null default 'Yogyakarta / Sleman',
  photo_url text,
  open_time time not null default '10:00',
  close_time time not null default '22:00',
  is_active boolean not null default true,
  sort_order int not null default 0
);

-- 3. KAPSTER (2 Kapster per Cabang)
create table barbers (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references branches(id) on delete cascade,
  name text not null,
  photo_url text,
  is_active boolean not null default true,
  sort_order int not null default 0
);
create index idx_barbers_branch on barbers(branch_id);

-- 4. KATEGORI & LAYANAN (Durasi dalam jam bulat)
create table service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  photo_url text,
  sort_order int not null default 0
);

create table services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references service_categories(id),
  name text not null,
  description text,
  price int not null check (price >= 0),
  duration_hours int not null check (duration_hours >= 1), -- Bulat 1, 2, atau 3 jam
  slots_needed int generated always as (duration_hours) stored,
  audience text, -- 'Pria' / 'Wanita' / null
  points int not null default 10,
  photo_url text,
  is_active boolean not null default true,
  sort_order int not null default 0
);
create index idx_services_cat on services(category_id, sort_order);

-- 5. GAYA RAMBUT
create table hairstyles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  photo_url text,
  is_active boolean not null default true
);

create table customer_hairstyles (
  customer_id uuid references profiles(id) on delete cascade,
  hairstyle_id uuid references hairstyles(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (customer_id, hairstyle_id)
);

-- 6. BOOKING & ANTI-DOUBLE BOOKING
create table bookings (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  customer_id uuid not null references profiles(id),
  branch_id uuid not null references branches(id),
  barber_id uuid not null references barbers(id),
  barber_pref barber_pref not null,
  service_id uuid not null references services(id),
  hairstyle_id uuid references hairstyles(id),
  service_name text not null,
  service_price int not null,
  service_points int not null,
  duration_hours int not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  during tstzrange generated always as (tstzrange(starts_at, ends_at, '[)')) stored,
  status booking_status not null default 'confirmed',
  arrived_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  -- Cegah bentrok jadwal kapster pada rentang waktu yang sama (hanya booking aktif)
  constraint no_barber_overlap exclude using gist (
    barber_id with =,
    during with &&
  ) where (status in ('confirmed', 'arrived'))
);

create trigger trg_bookings_upd before update on bookings
  for each row execute function set_updated_at();

create index idx_bookings_customer on bookings(customer_id, starts_at desc);
create index idx_bookings_branch on bookings(branch_id, starts_at);
create index idx_bookings_barber on bookings(barber_id, starts_at);

-- 7. TRANSAKSI & POIN
create table transactions (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references bookings(id),
  customer_id uuid not null references profiles(id),
  branch_id uuid not null references branches(id),
  service_name text not null,
  amount int not null,
  points_earned int not null,
  occurred_at timestamptz not null default now()
);

create table point_ledger (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references profiles(id) on delete cascade,
  delta int not null,
  reason ledger_reason not null,
  ref_id uuid,
  note text,
  created_at timestamptz not null default now()
);

create table rewards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  terms text,
  points_cost int not null check (points_cost > 0),
  photo_url text,
  is_active boolean not null default true,
  sort_order int not null default 0
);

create table reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references profiles(id),
  reward_id uuid not null references rewards(id),
  points_spent int not null,
  voucher_code text not null unique,
  status text not null default 'active' check (status in ('active', 'used', 'expired')),
  expires_at timestamptz not null default (now() + interval '30 days'),
  created_at timestamptz not null default now()
);

-- 8. FEEDBACK (Kritik & Saran - BACA SAJA oleh Admin)
create table feedbacks (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references profiles(id),
  message text not null check (char_length(message) between 5 and 1000),
  created_at timestamptz not null default now()
);
create index idx_feedbacks_created on feedbacks(created_at desc);

-- 9. PROMO
create table promos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  photo_url text,
  segments customer_segment[] not null default '{active,at_risk,inactive}',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 10. NOTIFIKASI DALAM APLIKASI
create table notifications (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references profiles(id) on delete cascade,
  type notif_type not null default 'system',
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 11. SUPABASE STORAGE BUCKET (FOTO & MEDIA)
-- Bucket publik untuk menyimpan foto cabang, kapster, layanan, gaya rambut, dan promo
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'images',
  'images',
  true,
  5242880, -- Maks 5 MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- ============================================================================
-- STORED FUNCTIONS / RPC (Dipanggil langsung dari Flutter)
-- ============================================================================

-- RPC: Booking dengan Auto-Assign Kapster (Bila barber_id null)
create or replace function create_booking_auto(
  p_branch_id uuid,
  p_service_id uuid,
  p_starts_at timestamptz,
  p_barber_id uuid default null,
  p_hairstyle_id uuid default null
) returns bookings language plpgsql security definer as $$
declare
  v_customer_id uuid := auth.uid();
  v_svc services%rowtype;
  v_ends_at timestamptz;
  v_assigned_barber uuid;
  v_code text;
  v_booking bookings;
begin
  if v_customer_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  select * into v_svc from services where id = p_service_id and is_active;
  if not found then raise exception 'SERVICE_NOT_FOUND'; end if;

  v_ends_at := p_starts_at + (v_svc.duration_hours || ' hours')::interval;

  -- Jika kapster ditentukan
  if p_barber_id is not null then
    v_assigned_barber := p_barber_id;
  else
    -- Auto-assign: cari kapster cabang yang kosong pada jam tsb, pilih beban paling sedikit hari ini
    select b.id into v_assigned_barber
    from barbers b
    where b.branch_id = p_branch_id and b.is_active
      and not exists (
        select 1 from bookings bk
        where bk.barber_id = b.id
          and bk.status in ('confirmed', 'arrived')
          and tstzrange(bk.starts_at, bk.ends_at, '[)') && tstzrange(p_starts_at, v_ends_at, '[)')
      )
    order by (
      select count(*) from bookings bk2
      where bk2.barber_id = b.id
        and bk2.starts_at::date = p_starts_at::date
        and bk2.status in ('confirmed', 'arrived', 'completed')
    ) asc, b.sort_order asc
    limit 1;
  end if;

  if v_assigned_barber is null then
    raise exception 'SLOT_TAKEN';
  end if;

  v_code := 'TTC-' || upper(substr(md5(random()::text), 1, 6));

  insert into bookings (
    code, customer_id, branch_id, barber_id, barber_pref,
    service_id, hairstyle_id, service_name, service_price,
    service_points, duration_hours, starts_at, ends_at, status
  ) values (
    v_code, v_customer_id, p_branch_id, v_assigned_barber,
    case when p_barber_id is not null then 'chosen'::barber_pref else 'auto'::barber_pref end,
    v_svc.id, p_hairstyle_id, v_svc.name, v_svc.price,
    v_svc.points, v_svc.duration_hours, p_starts_at, v_ends_at, 'confirmed'
  ) returning * into v_booking;

  return v_booking;
end;
$$;

-- RPC: Admin menyelesaikan booking (buat transaksi & tambah poin atomik)
create or replace function complete_booking(p_booking_id uuid)
returns transactions language plpgsql security definer as $$
declare
  b bookings;
  t transactions;
begin
  select * into b from bookings where id = p_booking_id for update;
  if not found or b.status not in ('confirmed', 'arrived') then
    raise exception 'INVALID_BOOKING_STATUS';
  end if;

  update bookings
  set status = 'completed', completed_at = now()
  where id = b.id;

  insert into transactions (booking_id, customer_id, branch_id, service_name, amount, points_earned)
  values (b.id, b.customer_id, b.branch_id, b.service_name, b.service_price, b.service_points)
  returning * into t;

  update profiles
  set points_balance = points_balance + b.service_points,
      lifetime_points = lifetime_points + b.service_points,
      last_visit_at = now()
  where id = b.customer_id;

  insert into point_ledger (customer_id, delta, reason, ref_id, note)
  values (b.customer_id, b.service_points, 'visit', t.id, b.service_name);

  insert into notifications (customer_id, type, title, body)
  values (
    b.customer_id,
    'reward',
    'Kunjungan Selesai',
    'Terima kasih telah berkunjung! Anda mendapatkan +' || b.service_points || ' poin.'
  );

  return t;
end;
$$;

-- RPC: Tukar Reward Poin Atomik
create or replace function redeem_reward(p_reward_id uuid)
returns reward_redemptions language plpgsql security definer as $$
declare
  v_cust_id uuid := auth.uid();
  r rewards;
  c profiles;
  v_voucher text;
  v_red reward_redemptions;
begin
  if v_cust_id is null then raise exception 'UNAUTHORIZED'; end if;
  select * into r from rewards where id = p_reward_id and is_active;
  if not found then raise exception 'REWARD_NOT_FOUND'; end if;

  select * into c from profiles where id = v_cust_id for update;
  if c.points_balance < r.points_cost then raise exception 'INSUFFICIENT_POINTS'; end if;

  update profiles
  set points_balance = points_balance - r.points_cost
  where id = v_cust_id;

  v_voucher := 'REW-' || upper(substr(md5(random()::text), 1, 8));

  insert into reward_redemptions (customer_id, reward_id, points_spent, voucher_code)
  values (v_cust_id, r.id, r.points_cost, v_voucher)
  returning * into v_red;

  insert into point_ledger (customer_id, delta, reason, ref_id, note)
  values (v_cust_id, -r.points_cost, 'redeem', v_red.id, r.name);

  return v_red;
end;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
alter table profiles enable row level security;
alter table branches enable row level security;
alter table barbers enable row level security;
alter table service_categories enable row level security;
alter table services enable row level security;
alter table hairstyles enable row level security;
alter table customer_hairstyles enable row level security;
alter table bookings enable row level security;
alter table transactions enable row level security;
alter table point_ledger enable row level security;
alter table rewards enable row level security;
alter table reward_redemptions enable row level security;
alter table feedbacks enable row level security;
alter table promos enable row level security;
alter table notifications enable row level security;

-- Public read untuk data master
create policy "Public branches are viewable by everyone" on branches for select using (true);
create policy "Public barbers are viewable by everyone" on barbers for select using (true);
create policy "Public service categories are viewable" on service_categories for select using (true);
create policy "Public services are viewable" on services for select using (true);
create policy "Public hairstyles are viewable" on hairstyles for select using (true);
create policy "Public rewards are viewable" on rewards for select using (true);
create policy "Public promos are viewable" on promos for select using (true);

-- Profiles
create policy "Users can view their own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update their own profile" on profiles for update using (auth.uid() = id);
create policy "Admins can view all profiles" on profiles for select using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

-- Bookings
create policy "Customers view their own bookings" on bookings for select using (auth.uid() = customer_id);
create policy "Customers can insert bookings" on bookings for insert with check (auth.uid() = customer_id);
create policy "Customers can update their booking to cancelled" on bookings for update using (
  auth.uid() = customer_id and status = 'confirmed'
);
create policy "Admins can view and manage all bookings" on bookings for all using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

-- Feedbacks
create policy "Customers can insert feedbacks" on feedbacks for insert with check (auth.uid() = customer_id);
create policy "Admins can view feedbacks (read-only)" on feedbacks for select using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

-- Transaksi, Ledger, Vouchers, Notifications
create policy "Users can view their own transactions" on transactions for select using (auth.uid() = customer_id);
create policy "Admins can view all transactions" on transactions for select using (
  exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);
create policy "Users can view their own point ledger" on point_ledger for select using (auth.uid() = customer_id);
create policy "Users can view their vouchers" on reward_redemptions for select using (auth.uid() = customer_id);
create policy "Users can view their notifications" on notifications for select using (auth.uid() = customer_id);
create policy "Users can update notifications" on notifications for update using (auth.uid() = customer_id);

-- Storage (Bucket 'images') Policies
create policy "Public images are viewable by everyone" on storage.objects for select using (bucket_id = 'images');
create policy "Authenticated users/admins can upload images" on storage.objects for insert with check (
  bucket_id = 'images' and auth.role() = 'authenticated'
);
create policy "Admins can update or delete images" on storage.objects for delete using (
  bucket_id = 'images' and exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);

-- ============================================================================
-- SEED DATA AWAL
-- ============================================================================
-- 1. Cabang (11 Cabang dengan alamat lengkap Google Maps)
insert into branches (name, address, city, sort_order) values
 ('Cabang Warungboto', 'Jl. Prof. DR. Soepomo SH No. 55, Warungboto, Kec. Umbulharjo', 'Kota Yogyakarta', 1),
 ('Cabang Tajem (Maguwoharjo)', 'Jl. Stadion No. 34 / Jl. Raya Tajem, Denokan, Maguwoharjo, Kec. Depok', 'Sleman', 2),
 ('Cabang Soragan', 'Jl. Soragan No. 80, Cungkuk, Ngestiharjo, Kec. Kasihan', 'Bantul', 3),
 ('Cabang Palagan', 'Jl. Palagan Tentara Pelajar No. 88, Mudal, Sariharjo, Kec. Ngaglik', 'Sleman', 4),
 ('Cabang Mrican 2 (Pringwulung)', 'Jl. Tantular No. 440, Pringwulung, Condongcatur, Kec. Depok', 'Sleman', 5),
 ('Cabang Mrican 1 (Demangan)', 'Jl. Brojomusti, Jl. Pringgodani No. 3, Demangan / Caturtunggal, Kec. Depok', 'Sleman', 6),
 ('Cabang Godean', 'Jl. Godean Km. 4.5 (Jl. Sidoarum - Bantulan No. 43), Bantulan, Sidoarum, Kec. Godean', 'Sleman', 7),
 ('Cabang Gedongkiwo', 'Jl. Bantul No. 74B, Gedongkiwo, Kec. Mantrijeron', 'Kota Yogyakarta', 8),
 ('Cabang Gamping', 'Jl. Pasir No. 1 / Jl. Wates Km. 5, Ambarketawang, Kec. Gamping', 'Sleman', 9),
 ('Cabang Concat (Condongcatur)', 'Jl. Nusa Indah / Jl. Anggajaya, Condongcatur, Kec. Depok', 'Sleman', 10),
 ('Cabang Candi Gebang', 'Jl. Candi Gebang No. 5, Jetis, Wedomartani, Kec. Ngemplak', 'Sleman', 11);

-- 2. Kapster (2 Kapster tetap di masing-masing dari 11 Cabang)
with br as (select id, name from branches)
insert into barbers (branch_id, name, sort_order) values
 ((select id from br where name like '%Warungboto%'), 'Bagas (Warungboto)', 1),
 ((select id from br where name like '%Warungboto%'), 'Rian (Warungboto)', 2),
 ((select id from br where name like '%Tajem%'), 'Fajar (Tajem)', 1),
 ((select id from br where name like '%Tajem%'), 'Dimas (Tajem)', 2),
 ((select id from br where name like '%Soragan%'), 'Doni (Soragan)', 1),
 ((select id from br where name like '%Soragan%'), 'Gilang (Soragan)', 2),
 ((select id from br where name like '%Palagan%'), 'Hendra (Palagan)', 1),
 ((select id from br where name like '%Palagan%'), 'Satria (Palagan)', 2),
 ((select id from br where name like '%Mrican 2%'), 'Bayu (Mrican 2)', 1),
 ((select id from br where name like '%Mrican 2%'), 'Angga (Mrican 2)', 2),
 ((select id from br where name like '%Mrican 1%'), 'Reza (Mrican 1)', 1),
 ((select id from br where name like '%Mrican 1%'), 'Ilham (Mrican 1)', 2),
 ((select id from br where name like '%Godean%'), 'Wahyu (Godean)', 1),
 ((select id from br where name like '%Godean%'), 'Pandu (Godean)', 2),
 ((select id from br where name like '%Gedongkiwo%'), 'Yusuf (Gedongkiwo)', 1),
 ((select id from br where name like '%Gedongkiwo%'), 'Tegar (Gedongkiwo)', 2),
 ((select id from br where name like '%Gamping%'), 'Aris (Gamping)', 1),
 ((select id from br where name like '%Gamping%'), 'Bima (Gamping)', 2),
 ((select id from br where name like '%Concat%'), 'Aldi (Concat)', 1),
 ((select id from br where name like '%Concat%'), 'Farhan (Concat)', 2),
 ((select id from br where name like '%Candi Gebang%'), 'Rio (Candi Gebang)', 1),
 ((select id from br where name like '%Candi Gebang%'), 'Danang (Candi Gebang)', 2);

-- 3. Kategori Layanan
insert into service_categories (name, description, sort_order) values
 ('Hair Cut', 'Layanan potong rambut presisi sesuai bentuk kepala dan karakter Anda.', 1),
 ('Face & Hair Care Treatment', 'Perawatan intensif kulit kepala dan rambut agar sehat berkilau.', 2),
 ('Texture Services', 'Menciptakan volume dan tekstur rambut melalui teknik perming modern.', 3);

-- 4. Layanan (Durasi bulat per jam)
with c as (select id, name from service_categories)
insert into services (category_id, name, price, duration_hours, audience, points, sort_order) values
 ((select id from c where name='Hair Cut'), 'Premium Haircut', 35000, 1, null, 10, 1),
 ((select id from c where name='Hair Cut'), 'Signature VIP Haircut', 65000, 1, null, 10, 2),
 ((select id from c where name='Face & Hair Care Treatment'), 'Facial Treatment', 55000, 1, null, 10, 1),
 ((select id from c where name='Face & Hair Care Treatment'), 'Hair Mask - Short Hair', 35000, 1, null, 10, 2),
 ((select id from c where name='Face & Hair Care Treatment'), 'Creambath - Short Hair', 50000, 1, null, 10, 3),
 ((select id from c where name='Face & Hair Care Treatment'), 'Creambath - Medium Hair', 60000, 1, null, 10, 4),
 ((select id from c where name='Texture Services'), 'Down Perm - Short Hair', 150000, 1, null, 25, 1),
 ((select id from c where name='Texture Services'), 'Bye-Bye Pomade - Normal Hair', 125000, 1, null, 25, 2),
 ((select id from c where name='Texture Services'), 'Texture Perm Wavy (Men) - Short Hair', 200000, 2, 'Pria', 25, 3),
 ((select id from c where name='Texture Services'), 'Texture Perm Wavy (Men) - Medium Hair', 300000, 2, 'Pria', 50, 4),
 ((select id from c where name='Texture Services'), 'Texture Perm Wavy (Men) - Long Hair', 500000, 2, 'Pria', 50, 5),
 ((select id from c where name='Texture Services'), 'Design Perm - 1.0', 350000, 2, null, 50, 6),
 ((select id from c where name='Texture Services'), 'Design Perm - 2.0', 500000, 2, null, 50, 7),
 ((select id from c where name='Texture Services'), 'Texture Perm (Women) - Short Hair', 300000, 2, 'Wanita', 50, 8),
 ((select id from c where name='Texture Services'), 'Texture Perm (Women) - Medium Hair', 400000, 3, 'Wanita', 50, 9),
 ((select id from c where name='Texture Services'), 'Texture Perm Curly (Men) - Short Hair', 200000, 2, 'Pria', 25, 10),
 ((select id from c where name='Texture Services'), 'Texture Perm Curly (Men) - Medium Hair', 300000, 3, 'Pria', 50, 11),
 ((select id from c where name='Texture Services'), 'Texture Perm Curly (Men) - Long Hair', 500000, 3, 'Pria', 50, 12);

-- 5. Reward
insert into rewards (name, description, terms, points_cost, sort_order) values
 ('Diskon Rp 10.000', 'Potongan harga langsung untuk satu kali layanan', 'Berlaku 30 hari di seluruh cabang', 50, 1),
 ('Gratis Hair Mask', 'Satu kali perawatan Hair Mask - Short Hair', 'Berlaku 30 hari di seluruh cabang', 80, 2),
 ('Gratis Premium Haircut', 'Satu kali potongan Premium Haircut', 'Berlaku 30 hari di seluruh cabang', 150, 3);
```

---

## 8. Arsitektur Frontend & Supabase (Full Flutter)

### 8.1 Paket Flutter Utama (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.8.0
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  google_fonts: ^6.2.1
  flutter_dotenv: ^5.2.1
  intl: ^0.19.0
  cached_network_image: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### 8.2 Struktur Direktori Proyek

```
lib/
├─ main.dart                         # Inisialisasi Supabase & runApp
├─ app/
│  ├─ app.dart                       # MaterialApp.router
│  ├─ router.dart                    # Konfigurasi GoRouter (redirect auth & role)
│  └─ theme/                         # Desain Minimalist Editorial (Playfair + Inter)
│     ├─ colors.dart
│     ├─ typography.dart
│     └─ app_theme.dart
├─ core/
│  ├─ config/supabase_config.dart    # Client instance Supabase
│  ├─ constants/app_constants.dart
│  ├─ utils/formatters.dart          # Format Rupiah & Tanggal ID
│  └─ widgets/                       # Reusable UI widgets
│     ├─ primary_button.dart
│     ├─ hairline_divider.dart
│     ├─ slot_card.dart
│     └─ empty_view.dart
└─ features/
   ├─ auth/                          # Login, Register, Splash
   ├─ home/                          # Member card, poin, booking shortcut
   ├─ booking/                       # 6-step booking flow, availability check
   ├─ rewards/                       # Katalog reward, redeem RPC, list voucher
   ├─ hairstyles/                    # Katalog gaya rambut
   ├─ profile/                       # Edit profil, feedback form
   └─ admin/                         # Admin booking schedule, search customer, feedbacks (read-only), promos
```

---

## 9. Desain Visual: Minimalist Editorial

- **Tone & Karakter**: Editorial majalah klasik, bersih, tipografi tegas, berkelas.
- **Palet Warna**:
  - `paper` (`#F6F2EA`): Latar belakang utama bernuansa kertas lembut.
  - `surface` (`#FFFFFF`): Latar kartu dan modal bottom sheet.
  - `ink` (`#16130F`): Teks utama dan tombol aksi utama (kontras tinggi 17:1).
  - `ink-soft` (`#5A544B`): Teks sekunder dan caption.
  - `hairline` (`#D9D2C4`): Garis pembatas tipis 1 px.
  - `accent` (`#7A2E2A`): Merah marun/anggur elegan untuk highlight status dan badge.
  - `gold` (`#8C6A2F`): Aksen emas vintage untuk angka poin dan badge status tier (Bronze/Silver/Gold).
- **Tipografi**:
  - Display / Headings: **Playfair Display** (huruf serif elegan untuk judul dan nama brand).
  - Body & UI: **Inter** (sans-serif bersih dengan keterbacaan tinggi).

---

## 10. Kriteria Penerimaan (Acceptance Criteria)

1. **Direct Supabase**: Flutter berhasil melakukan query langsung ke database Supabase dan menjalankan Supabase Auth tanpa backend intermediary.
2. **Cabang & Kapster**: Terdapat 11 cabang. Saat memilih cabang tertentu, hanya muncul 2 kapster dari cabang tersebut (+ opsi "Bebas / Auto-assign").
3. **Slot Jam Bulat**: Tidak ada layanan dengan durasi menit ganjil. Seluruh slot dihitung dalam interval 1 jam penuh (10:00 s.d. 21:00). Layanan berdurasi 2 jam otomatis mengunci 2 slot berurutan.
4. **Pencegahan Bentrok**: PostgreSQL `EXCLUSION CONSTRAINT` berhasil menolak booking jika terjadi bentrok jadwal pada kapster yang sama.
5. **Feedback Read-Only**: Admin dapat melihat daftar seluruh feedback pelanggan tanpa ada fitur/kolom pengubahan status.
6. **Otomasi Transaksi & Poin**: Menekan tombol "Selesai" pada booking admin otomatis memanggil fungsi RPC `complete_booking`, menerbitkan transaksi, dan menambahkan poin pelanggan secara atomik.

