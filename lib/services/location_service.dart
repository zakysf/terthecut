import 'package:geolocator/geolocator.dart';

/// ============================================================================
/// Layanan Location-Based Services (LBS) - Mengacu pada Modul 7 Praktikum
/// ============================================================================
/// Berperan sebagai pusat logika penanganan GPS pada aplikasi:
/// 1. Memeriksa status keaktifan sensor GPS perangkat.
/// 2. Meminta izin (permission) akses lokasi kepada pengguna secara dinamis.
/// 3. Mengambil titik koordinat latitude & longitude terkini.
/// 4. Menghitung jarak lurus (meter) antara posisi user dan cabang barber.
/// 5. Memformat angka meter menjadi teks yang rapi (misal: "850 m" atau "1.2 km").
class LocationService {
  // ---------------------------------------------------------------------------
  // Penerapan Singleton Pattern:
  // Memastikan hanya ada 1 objek LocationService yang aktif di memori aplikasi.
  // ---------------------------------------------------------------------------
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// 1. Cek apakah layanan GPS (Location Service) di HP dalam kondisi AKTIF.
  /// Jika GPS dimatikan oleh pengguna lewat status bar, fungsi ini mengembalikan false.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 2. Cek dan minta perizinan akses lokasi perangkat (Modul 7 Contoh Program 7.12)
  /// - denied: pengguna belum mengizinkan, aplikasi meminta izin via dialog pop-up.
  /// - deniedForever: pengguna menolak permanen, harus diarahkan ke Pengaturan HP.
  /// - whileInUse / always: izin diberikan dan fitur LBS siap dijalankan.
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// 3. Mengambil posisi GPS pengguna saat ini (latitude & longitude)
  /// Menggunakan konsep Asynchronous (Future) karena proses pengambilan sinyal satelit
  /// GPS memerlukan waktu (I/O hardware) dan tidak boleh membekukan tampilan aplikasi.
  Future<Position?> getCurrentPosition() async {
    // a. Validasi: Pastikan tombol GPS perangkat sudah menyala
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS pada perangkat belum aktif. Silakan aktifkan layanan lokasi Anda.');
    }

    // b. Validasi: Periksa status izin akses lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Minta izin pertama kali ke pengguna
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    // Jika pengguna memilih "Jangan tanya lagi" / ditolak permanen
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi diblokir permanen. Silakan buka Pengaturan HP untuk mengizinkan.');
    }

    // c. Ambil posisi koordinat terkini dengan akurasi tinggi (LocationAccuracy.high)
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// 4. Menghitung jarak lurus (Great-Circle Distance) antara user dan cabang (dalam meter).
  /// Menggunakan formula bawaan Geolocator.distanceBetween() yang menghitung kelengkungan bumi (Haversine).
  double calculateDistance({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
  }

  /// 5. Helper pemformat jarak agar mudah dibaca pengguna (Modul 7 Contoh Program 7.11):
  /// - Jika jarak < 1000 meter, tampilkan dalam satuan meter bulat: "150 m", "850 m".
  /// - Jika jarak >= 1000 meter, konversikan ke kilometer dengan 1 angka desimal: "1.2 km", "3.5 km".
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
