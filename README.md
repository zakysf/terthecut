# 💈 Ter The Cut — Smart Barbershop Booking & Loyalty App

[![Flutter](https://img.shields.io/badge/Flutter-v3.13%2B-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0%2B-0175C2.svg?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase%20PostgreSQL-3ECF8E.svg?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Unit%20Tests-31%2F31%20Passing-brightgreen.svg)]()

**Ter The Cut** adalah aplikasi mobile reservasi barbershop modern berbasis **Flutter** dengan arsitektur **Clean MVC** (Model-View-Controller) tanpa ketergantungan library state management eksternal (menggunakan *native* `ChangeNotifier`). 

Aplikasi ini mengintegrasikan layanan **Cloud Backend Supabase (PostgreSQL)**, **Database Relasional Lokal SQLite (sqflite)** untuk tiket pemesanan offline dan caching, **Location-Based Services (LBS)** berbasis GPS untuk rekomendasi cabang terdekat dan navigasi Google Maps (Modul VII), **Sistem Notifikasi Lokal & Pengingat Jadwal** (Modul VII), serta **Penyimpanan Sesi Lokal Auto-Login** menggunakan SharedPreferences (Modul VI).

---

## 📑 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Teknologi & Dependensi](#-teknologi--dependensi)
- [Struktur Direktori & Arsitektur](#-struktur-direktori--arsitektur)
- [Database Lokal & Offline Fallback](#-database-lokal--offline-fallback)
- [Cloud Backend & REST API (Supabase)](#-cloud-backend--rest-api-supabase)
- [Konfigurasi Platform Android (Permissions & Intents)](#-konfigurasi-platform-android-permissions--intents)
- [Panduan Setup & Instalasi](#-panduan-setup--instalasi)
- [Akun Demo Pengujian](#-akun-demo-pengujian)
- [Location-Based Services (LBS) & Notifikasi](#-location-based-services-lbs--notifikasi)
- [Pengujian & Verifikasi (Unit Tests)](#-pengujian--verifikasi-unit-tests)

---

## 🌟 Fitur Utama

### 1. Multi-Role Authentication & Session Management
- **Role-Based Access Control (RBAC)**: Mendukung role **Customer**, **Kasir**, dan **Admin**.
- **Auto-Login (Modul VI)**: Sesi login pengguna tersimpan secara persisten di penyimpanan perangkat via `shared_preferences`. Saat aplikasi dibuka kembali, pengguna langsung diarahkan ke layar sesuai role tanpa perlu login ulang.
- **Registrasi & Lupa Password**: Pelanggan baru dapat mendaftar dengan tier default Bronze (0 Poin).

### 2. Location-Based Services (LBS) & Google Maps (Modul VII)
- **Deteksi Lokasi GPS**: Mengambil koordinat pengguna secara realtime menggunakan GPS perangkat (`geolocator`).
- **Pencarian Cabang Terdekat**: Menghitung jarak presisi ke seluruh cabang barbershop (menggunakan rumus Haversine) dan mengurutkan cabang dari yang paling dekat.
- **Navigasi Satu-Klik**: Membuka petunjuk arah langsung ke aplikasi **Google Maps** atau browser melalui deep-link intent (`url_launcher`).
- **Smart Booking**: Otomatis merekomendasikan cabang terdekat saat pelanggan memulai alur reservasi potong rambut.

### 3. Online Booking Wizard
- **Alur Reservasi Interaktif**:
  1. Pilih Cabang (dilengkapi indikator jarak terdekat).
  2. Pilih Kapster / Barber favorit beserta spesialisasi gaya rambutnya.
  3. Pilih Layanan (Gentleman Cut, Hair Spa, Shave, Grooming, dll) beserta harga dan durasi.
  4. Pilih Tanggal & Slot Waktu yang tersedia.
  5. Konfirmasi Pembayaran & Penggunaan Voucher Diskon Loyalty.
- **Anti Double-Booking**: Mencegah pemesanan slot waktu yang sama untuk kapster yang sedang melayani pelanggan lain.

### 4. Loyalty Program & Reward Points
- **Point Ledger System**: Setiap transaksi yang selesai otomatis memberikan poin loyalitas.
- **Tier Pelanggan**: Bronze, Silver, Gold, dan Platinum dengan keuntungan berbeda.
- **Katalog Hadiah**: Tukarkan poin dengan voucher diskon, pomade gratis, atau free hair treatment.
- **Barcode / QR Voucher**: Menampilkan kode voucher aktif yang dapat discan oleh kasir.

### 5. Local Notification & Reminder (Modul VII)
- **Notifikasi Instan**: Muncul saat reservasi berhasil dibuat atau saat poin loyalitas bertambah.
- **Scheduled Reminder**: Pengingat otomatis yang dijadwalkan beberapa jam sebelum waktu reservasi tiba menggunakan `flutter_local_notifications` dan `timezone`.

### 6. Admin & Cashier Dashboard
- **Manajemen Cabang & Layanan**: Tambah, ubah, dan pantau operasional cabang.
- **Kasir & Validasi Reservasi**: Konfirmasi kedatangan pelanggan, update status reservasi (`confirmed`, `in_progress`, `completed`, `cancelled`), dan input transaksi kasir.
- **Barcode Scanner**: Validasi voucher hadiah pelanggan secara cepat.

---

## 🛠 Teknologi & Dependensi

| Kategori | Paket / Teknologi | Versi | Kegunaan |
|---|---|---|---|
| **Framework** | Flutter SDK | `^3.13.2` | Mobile UI Framework multi-platform |
| **Language** | Dart | `^3.0.0` | Bahasa pemrograman utama |
| **State Management**| Native `ChangeNotifier` | SDK Bawaan | Arsitektur reaktif bersih & efisien tanpa library pihak ketiga |
| **Backend & Cloud** | `supabase_flutter` | `^2.18.3` | SDK Cloud PostgreSQL, Otentikasi, REST API, & RLS |
| **Local Database (SQLite)** | `sqflite` & `path` | `^2.4.1` / `^1.9.0` | Database lokal relasional untuk tiket booking & cache offline |
| **Local Storage** | `shared_preferences` | `^2.5.6` | Penyimpanan persisten lokal untuk sesi login (Modul VI) |
| **Location (LBS)** | `geolocator` | `^13.0.0` | Akses GPS & kalkulasi jarak geospasial (Modul VII) |
| **Deep Linking** | `url_launcher` | `^6.3.1` | Membuka rute Google Maps & link eksternal (Modul VII) |
| **Notification** | `flutter_local_notifications` | `19.0.0` | Menampilkan notifikasi lokal di status bar perangkat (Modul VII) |
| **Scheduler** | `timezone` | `0.10.0` | Manajemen zona waktu (WIB/WITA/WIT) untuk jadwal reminder |
| **Environment** | `flutter_dotenv` | `^6.0.1` | Membaca konfigurasi `.env` secara aman |
| **Typography** | `google_fonts` | `^9.0.0` | Font Playfair Display & Plus Jakarta Sans |
| **Formatting** | `intl` | `^0.20.3` | Format Rupiah (`Rp`) & tanggal Bahasa Indonesia (`id_ID`) |

---

## 📂 Struktur Direktori & Arsitektur

Aplikasi menggunakan arsitektur **Clean MVC (Model-View-Controller)** yang memisahkan tanggung jawab kode ke dalam lapisan terisolasi:

```
terthecut/
├── .env                                # Konfigurasi credentials Supabase (URL & Anon Key)
├── pubspec.yaml                        # Definisi dependensi & assets
├── android/                            # Konfigurasi platform Android (Manifest, permissions, queries)
├── supabase/
│   └── migrations/                     # Skrip SQL skema tabel & kolom LBS
│       ├── 20261114_sprint4_schema.sql
│       └── 20261126_lbs_branch_coordinates.sql
├── test/                               # 28 Unit Tests otomatis
│   ├── lbs_location_test.dart          # Pengujian LBS, jarak GPS, & sorting cabang
│   ├── booking_test.dart               # Pengujian validasi booking & slot
│   ├── native_flutter_migration_test.dart
│   └── sprint4_test.dart
└── lib/
    ├── main.dart                       # Entry point aplikasi & AuthGate (Pengecekan sesi lokal)
    ├── config/                         # Konfigurasi tema dan inisialisasi cloud
    │   ├── supabase_config.dart        # Inisialisasi koneksi Supabase dari .env
    │   └── theme.dart                  # Tema Material Design, palet warna, tipografi
    ├── models/                         # Blueprint / struktur data (Data Entities)
    │   ├── branch.dart                 # Model Cabang (nama, alamat, latitude, longitude)
    │   ├── barber.dart                 # Model Kapster / Barber
    │   ├── booking.dart                # Model Reservasi Booking
    │   ├── user_profile.dart           # Model Pengguna & Role
    │   ├── service_item.dart           # Model Layanan Potong Rambut
    │   ├── hairstyle.dart              # Model Katalog Gaya Rambut
    │   ├── loyalty_point.dart          # Model Reward & Point Ledger
    │   ├── promotion.dart              # Model Banner Promosi
    │   ├── feedback_item.dart          # Model Rating & Ulasan
    │   └── app_notification.dart       # Model Notifikasi
    ├── controllers/                    # State management (ChangeNotifier) penghubung View & Service
    │   ├── auth_controller.dart        # Manajemen login, register, dan SharedPreferences
    │   ├── branch_controller.dart      # Logika GPS, hitung jarak, dan pengurutan cabang terdekat
    │   ├── booking_controller.dart     # Logika alur wizard booking & validasi
    │   ├── loyalty_controller.dart     # Penukaran poin & voucher
    │   ├── promotion_controller.dart   # Manajemen promo aktif
    │   ├── feedback_controller.dart    # Pengiriman rating ulasan
    │   ├── admin_controller.dart       # Operasi kasir dan back-office
    │   └── notification_controller.dart# Pengontrol daftar notifikasi
    ├── services/                       # Data Access Layer (Supabase API & Local Seed Fallback)
    │   ├── local_database_helper.dart  # Database lokal SQLite (sqflite): tabel booking & cache cabang
    │   ├── location_service.dart       # Layanan GPS & integrasi Geolocator (Modul VII)
    │   ├── notification_service.dart   # Inisialisasi flutter_local_notifications (Modul VII)
    │   ├── branch_service.dart         # Master data cabang & koordinat lokal
    │   ├── auth_service.dart           # Otentikasi Supabase & session cache
    │   ├── booking_service.dart        # Sinkronisasi booking ke tabel cloud
    │   ├── service_catalog_service.dart# Katalog layanan potong rambut
    │   ├── hairstyle_service.dart      # Katalog model gaya rambut
    │   ├── loyalty_service.dart        # Mutasi poin & katalog hadiah
    │   ├── promotion_service.dart      # Daftar promosi
    │   └── feedback_service.dart       # Penyimpanan ulasan
    └── views/                          # Antarmuka Pengguna (UI Layer)
        ├── customer_root_view.dart     # Bottom navigation bar pelanggan
        ├── auth/                       # Layar Login, Register, & Forgot Password
        ├── branch/                     # Layar Daftar Cabang (LBS GPS Card) & Detail Cabang (Google Maps)
        ├── booking/                    # Layar Wizard Booking 5 Langkah & Riwayat Pemesanan
        ├── catalog/                    # Layar Katalog Layanan & Detail Layanan
        ├── hairstyles/                 # Layar Katalog Tren Model Rambut Pria
        ├── loyalty/                    # Layar Poin Loyalitas & Voucher Saya
        ├── promotions/                 # Layar Promo & Diskon Spesial
        ├── feedback/                   # Form Pengisian Ulasan & Bintang
        ├── notifications/              # Layar Notifikasi Masuk
        ├── profile/                    # Profil Pengguna & Edit Akun
        └── admin/                      # Dashboard Kasir/Admin & Scanner Barcode
```

---

## 💾 Database Lokal & Offline Fallback

Aplikasi menerapkan arsitektur **Offline-First with Cloud Sync** yang memadukan penyimpanan database lokal relasional (SQLite), penyimpanan key-value (SharedPreferences), dan data seed:

### 1. Database Relasional Lokal: SQLite (`sqflite` & `path`)
Menyimpan data transaksi dan data master secara permanen di storage smartphone ke dalam file basis data SQLite (`terthecut_local.db`).

* **Lokasi File Helper**: [`lib/services/local_database_helper.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/local_database_helper.dart)
* **Paket Dependensi**: `sqflite: ^2.4.1` dan `path: ^1.9.0` (Didukung `sqflite_common_ffi` untuk unit testing).
* **Tabel yang Dikelola**:
  1. **`local_bookings`**:
     * **Fungsi**: Menyimpan tiket pemesanan potong rambut pelanggan di HP secara offline.
     * **Skema Kolom**:
       * `id` (TEXT PRIMARY KEY), `code` (TEXT UNIQUE — contoh: `TTC-581923`)
       * `customer_id` (TEXT), `customer_name` (TEXT), `customer_phone` (TEXT)
       * `branch_id` (TEXT), `branch_name` (TEXT), `branch_address` (TEXT)
       * `barber_id` (TEXT), `barber_name` (TEXT), `barber_pref` (TEXT)
       * `service_id` (TEXT), `service_name` (TEXT), `service_price` (INTEGER), `service_points` (INTEGER), `duration_hours` (INTEGER)
       * `hairstyle_id` (TEXT), `hairstyle_name` (TEXT)
       * `starts_at` (TEXT), `ends_at` (TEXT)
       * `status` (TEXT — `confirmed`, `arrived`, `completed`, `cancelled`), `cancel_reason` (TEXT)
       * `arrived_at` (TEXT), `completed_at` (TEXT), `cancelled_at` (TEXT), `created_at` (TEXT)
       * `sync_status` (TEXT — `'synced'` jika sudah terkirim ke Supabase, `'pending'` jika antrean offline)
  2. **`local_branches`**:
     * **Fungsi**: Caching master cabang dan koordinat GPS (LBS) agar daftar cabang dapat muncul instan tanpa jeda loading (*0 ms latency*).
     * **Skema Kolom**: `id` (TEXT PRIMARY KEY), `name` (TEXT), `address` (TEXT), `city` (TEXT), `photo_url` (TEXT), `open_time` (TEXT), `close_time` (TEXT), `is_active` (INTEGER), `sort_order` (INTEGER), `latitude` (REAL), `longitude` (REAL).
* **Mekanisme Integrasi (*Clean Service Layer*)**:
  * **Pembuatan Booking Baru**: Saat user menekan tombol pesan di `BookingWizardView`, `BookingService.createBooking()` segera melakukan `LocalDatabaseHelper.instance.upsertBooking(..., syncStatus: 'pending')`. Begitu respon Supabase kembali sukses, status diubah menjadi `'synced'`.
  * **Akses Riwayat Offline**: Di layar riwayat booking (`BookingHistoryView`), `BookingService` membaca dari `LocalDatabaseHelper.instance.getBookingsForCustomer(...)`, sehingga tiket booking tetap bisa dibuka dan discan oleh kasir meski di lokasi tanpa sinyal internet.
  * **Update Status**: Pembatalan booking atau perubahan status oleh kasir (`arrived` / `completed`) otomatis memperbarui record SQLite via `LocalDatabaseHelper.instance.updateBookingStatus(...)`.

### 2. Persistent Local Storage: `shared_preferences` (Modul VI)
Digunakan untuk menyimpan sesi login pengguna secara permanen di memori fisik smartphone (Android SharedPreferences / iOS NSUserDefaults).

* **Lokasi File**: [`lib/controllers/auth_controller.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/controllers/auth_controller.dart)
* **Library**: `package:shared_preferences/shared_preferences.dart`
* **Key-Value yang Disimpan**:
  * `'loginData'`: String JSON berisi serialisasi lengkap data profil pengguna (`UserProfile`).
  * `'loggedInUserId'`: String UUID identitas pengguna yang sedang aktif.
* **Mekanisme Kerja**:
  1. Saat pengguna login berhasil (`AuthController.login()`), profil dienkapsulasi menjadi JSON dan disimpan via `prefs.setString('loginData', jsonEncode(profile.toJson()))`.
  2. Saat aplikasi pertama kali dijalankan, `_AuthGate` di `main.dart` memanggil `AuthController.checkSavedSession()`.
  3. Jika key `'loginData'` ditemukan, aplikasi otomatis melakukan login (*bypass* login screen) dan mengarahkan pengguna langsung ke Dashboard Admin atau Dashboard Customer sesuai perannya.
  4. Saat pengguna menekan tombol Logout, `AuthController.logout()` membersihkan seluruh key dari SharedPreferences.

### 3. Master Seed Data & In-Memory Cache (Offline Fallback)
Ketika koneksi internet terputus atau server Supabase sedang tidak dapat dijangkau, aplikasi tidak crash melainkan beralih menggunakan data seed lokal yang bersih dan konsisten:

| Nama File Layanan | Variabel / Koleksi Data | Jenis Data yang Disimpan |
|---|---|---|
| [`lib/services/branch_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/branch_service.dart) | `_seedBranches` | **11 Cabang Barbershop** lengkap dengan alamat asli, jam buka, nomor telepon, dan koordinat GPS nyata di wilayah D.I. Yogyakarta (Kotabaru, Gejayan, Jakal, Seturan, Malioboro, dll). |
| [`lib/services/branch_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/branch_service.dart) | `_seedBarbers` | Daftar nama kapster/barber resmi (2 barber per cabang) beserta spesialisasi potongannya. |
| [`lib/services/service_catalog_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/service_catalog_service.dart) | `_seedServices` | Katalog master layanan potong rambut (Gentleman Cut, Hair Spa, Beard Grooming, Hot Towel Shave, Hair Coloring) lengkap dengan harga dan durasi pengerjaan. |
| [`lib/services/hairstyle_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/hairstyle_service.dart) | `_seedHairstyles` | 8 Katalog model rambut pria terpopuler (Fade, Pompadour, Two Block, Undercut, Buzz Cut, French Crop, dll) disertai foto HD dan deskripsi bentuk wajah yang cocok. |
| [`lib/services/loyalty_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/loyalty_service.dart) | `_seedRewards`, `_inMemoryVouchers`, `_inMemoryLedger` | Master item hadiah penukaran poin (Potongan 20K, Free Pomade, Hair Wash Gratis), voucher yang aktif ditukarkan, dan riwayat mutasi poin pelanggan. |
| [`lib/services/auth_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/auth_service.dart) | `_inMemoryProfiles` | Cache akun pengguna lokal untuk validasi login offline. |
| [`lib/services/booking_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/booking_service.dart) | `_inMemoryBookings` | Cache pemesanan sesi potong rambut pelanggan. |
| [`lib/services/promotion_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/promotion_service.dart) | `_inMemoryPromotions` | Cache banner promosi diskon aktif. |
| [`lib/services/feedback_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/feedback_service.dart) | `_inMemoryFeedbacks` | Cache ulasan dan rating pelanggan. |
| [`lib/services/notification_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/notification_service.dart) | `_inMemoryNotifications` | Cache riwayat notifikasi lokal aplikasi. |

---

## ☁️ Cloud Backend & REST API (Supabase)

Aplikasi menggunakan backend berbasis **Supabase** (PostgreSQL).

### Konfigurasi `.env`
File `.env` terletak di root folder aplikasi:
```env
SUPABASE_URL=https://tdbetcjkqeihudihsjlq.supabase.co
SUPABASE_ANON_KEY=sb_publishable_1tBjL_d4dLJW7c0twHPzDw_rP6JsjNP
```

### Inisialisasi di Flutter
Diinisialisasi sebelum `runApp()` pada [`lib/main.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/main.dart) melalui helper [`lib/config/supabase_config.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/config/supabase_config.dart):
```dart
await dotenv.load(fileName: '.env');
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
);
```

### Skema Tabel Cloud
1. **`profiles`**: Data identitas, email, no HP, tier, poin loyalitas, dan peran/role (`customer`, `admin`).
2. **`branches`**: Master cabang barbershop. Telah diperluas dengan kolom `latitude` dan `longitude` bertipe `DOUBLE PRECISION` untuk LBS.
3. **`barbers`**: Data kapster barbershop per cabang.
4. **`services`**: Daftar layanan potong rambut beserta harga dan durasi.
5. **`hairstyles`**: Inspirasi model gaya rambut beserta foto.
6. **`bookings`**: Data transaksi reservasi, waktu jadwal, kapster, status, dan voucher diskon yang digunakan.
7. **`rewards`**: Master hadiah penukaran poin.
8. **`point_ledger`**: Buku besar riwayat pertambahan/pengurangan poin loyalitas.
9. **`promos`**: Banner pengumuman promosi aktif.
10. **`feedbacks`**: Ulasan ulasan bintang (1-5) dan komentar pelanggan.

### Skrip Migrasi SQL
Skrip migrasi database tersimpan rapi di direktori `supabase/migrations/`:
* `supabase/migrations/20261114_sprint4_schema.sql` (Skema awal aplikasi)
* `supabase/migrations/20261126_lbs_branch_coordinates.sql` (Migrasi koordinat latitude/longitude untuk fitur LBS Modul VII)

### Akses REST API Langsung (Postman / cURL)
Jika ingin menguji API publik Supabase melalui cURL atau Postman tanpa melalui aplikasi Flutter:

```bash
# Contoh: Mengambil daftar cabang barbershop
curl -X GET "https://tdbetcjkqeihudihsjlq.supabase.co/rest/v1/branches?select=*" \
  -H "apikey: sb_publishable_1tBjL_d4dLJW7c0twHPzDw_rP6JsjNP" \
  -H "Authorization: Bearer sb_publishable_1tBjL_d4dLJW7c0twHPzDw_rP6JsjNP"
```

---

## 📱 Konfigurasi Platform Android (Permissions & Intents)

File [`android/app/src/main/AndroidManifest.xml`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/android/app/src/main/AndroidManifest.xml) telah dikonfigurasi dengan izin dan deklarasi queries yang memenuhi standar Android 11+ (API Level 30 ke atas):

### 1. Izin Lokasi GPS (Modul VII LBS)
```xml
<!-- Izin akses lokasi GPS akurasi tinggi dan estimasi jaringan -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 2. Izin Notifikasi & Penjadwalan (Modul VII Notifikasi)
```xml
<!-- Izin notifikasi Android 13+ (Tiramisu) dan penjadwalan alarm presisi -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

### 3. Package Visibility Queries (Modul VII Google Maps Launching)
Android 11+ memberlakukan pembatasan visibilitas paket aplikasi. Tag `<queries>` berikut wajib ada agar `url_launcher` dapat mendeteksi dan membuka aplikasi Google Maps serta Browser:
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="http" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="geo" />
    </intent>
</queries>
```

---

## 🚀 Panduan Setup & Instalasi

### 1. Prasyarat Sistem
- **Flutter SDK**: Versi `3.13.2` atau lebih baru (`flutter doctor` untuk cek).
- **Dart SDK**: Versi `3.0.0` atau lebih baru.
- **Java JDK**: JDK 17 disarankan untuk Android build.
- **Android Studio / VS Code**: Terinstal Flutter & Dart extension.
- **Perangkat Fisik / Emulator**: Android API level 26+ dengan GPS aktif.

### 2. Langkah-Langkah Instalasi

1. **Clone Repository**:
   ```bash
   git clone https://github.com/your-username/terthecut.git
   cd terthecut
   ```

2. **Periksa Konfigurasi `.env`**:
   Pastikan file `.env` berada di root folder proyek dengan isi:
   ```env
   SUPABASE_URL=https://tdbetcjkqeihudihsjlq.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_1tBjL_d4dLJW7c0twHPzDw_rP6JsjNP
   ```

3. **Unduh Dependensi Proyek**:
   ```bash
   flutter pub get
   ```

4. **Jalankan Pengujian Unit (Unit Test)**:
   ```bash
   flutter test
   ```
   *Seluruh 28 unit tests harus lulus (100% PASS).*

5. **Jalankan Analisis Kode**:
   ```bash
   flutter analyze
   ```
   *Pastikan menghasilkan output: `No issues found!`.*

6. **Jalankan Aplikasi ke Perangkat / Emulator**:
   ```bash
   flutter run
   ```

---

## 👥 Akun Demo Pengujian

Gunakan akun berikut untuk menguji seluruh fitur aplikasi secara langsung:

| Role | Email | Password | Keterangan & Hak Akses |
|---|---|---|---|
| **Admin / Kasir** | `admin@terthecut.com` | `Password123!` | Mengakses Admin Dashboard, Manajemen Cabang, Update Status Reservasi Kasir, dan Scan Barcode Voucher. |
| **Customer (Gold)** | `budi.santoso@example.com` | `Password123!` | Akun pelanggan loyal tier Gold dengan 350 poin loyalitas, riwayat booking, dan voucher siap pakai. |
| **Customer Baru** | *Daftar Mandiri via Register* | *(Password bebas)* | Mendaftar akun baru via form Register (Otomatis menjadi role Customer tier Bronze dengan 0 poin). |

---

## 📍 Location-Based Services (LBS) & Notifikasi

Implementasi fitur LBS dan Notifikasi dirancang secara edukatif dan mudah dipelajari sesuai materi praktikum:

```
[Pengguna di Layar Cabang]
         │
         ▼
[Klik "Cek Cabang Terdekat"]
         │
         ▼
[LocationService.getCurrentPosition()] ──► Cek Service & Permission GPS
         │
         ▼ (Koordinat User: lat, lng)
[BranchController.findNearestBranches()]
         │
         ├─► Hitung jarak ke setiap cabang via Haversine Formula
         │   (Geolocator.distanceBetween)
         │
         ├─► Format jarak (Contoh: "850 m" atau "2.4 km")
         │
         └─► Sortir daftar cabang dari jarak terpendek
         │
         ▼
[UI Diperbarui Otomatis] ──► Menampilkan badge jarak & kartu cabang terdekat
         │
         ▼
[Klik "Lihat Rute di Google Maps"]
         │
         └─► Buka intent geo:/https://maps.google.com/dir/ via url_launcher
```

### Logika LBS pada Kode
* **`LocationService`** ([`lib/services/location_service.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/services/location_service.dart)):
  * `isLocationServiceEnabled()`: Memeriksa apakah tombol GPS di smartphone menyala.
  * `checkAndRequestPermission()`: Meminta izin lokasi secara runtime ke pengguna.
  * `getCurrentPosition()`: Mengambil koordinat lintang & bujur pengguna.
  * `calculateDistance()`: Menghitung jarak lurus dalam meter menggunakan rumus Haversine.
  * `formatDistance()`: Mengubah angka meter menjadi teks ramah pengguna (`"450 m"` atau `"3.2 km"`).
* **`BranchController`** ([`lib/controllers/branch_controller.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/controllers/branch_controller.dart)):
  * `findNearestBranches()`: Mengambil posisi GPS, menghitung jarak ke seluruh 11 cabang, dan mengurutkan daftar cabang secara otomatis dari yang terdekat.
* **`BranchDetailView`** ([`lib/views/branch/branch_detail_view.dart`](file:///c:/Users/ASUS/Documents/Semester%205/project-mobile/terthecut/lib/views/branch/branch_detail_view.dart)):
  * `_openGoogleMaps()`: Membuka navigasi rute ke titik cabang dengan mekanisme *fallback multi-tier* (Aplikasi Google Maps Native -> Web Browser Maps).

---

## 🧪 Pengujian & Verifikasi (Unit Tests)

Proyek ini dilengkapi dengan rangkaian pengujian unit otomatis komprehensif di folder `test/`:

1. **`test/lbs_location_test.dart`**:
   * Memvalidasi format string jarak (`formatDistance`) untuk meter dan kilometer.
   * Menguji kalkulasi jarak Haversine antar koordinat Yogyakarta.
   * Menguji sorting urutan cabang dari yang terdekat ke terjauh.
2. **`test/booking_test.dart`**:
   * Memvalidasi alur wizard pemesanan tanggal, slot waktu, dan pemilihan kapster.
3. **`test/booking_persistence_and_cashier_test.dart`**:
   * Menguji transaksi pemesanan kasir dan mutasi status reservasi.
4. **`test/native_flutter_migration_test.dart`**:
   * Memvalidasi bahwa seluruh state controller bekerja optimal menggunakan `ChangeNotifier` bawaan Flutter.

### Menjalankan Pengujian
```bash
# Menjalankan seluruh test suite
flutter test

# Menjalankan test khusus LBS
flutter test test/lbs_location_test.dart
```

---

## 📄 Lisensi
Proyek ini dibuat untuk keperluan akademik dan pengembangan sistem mobile barbershop modern. Bebas dimodifikasi dan dikembangkan lebih lanjut.
