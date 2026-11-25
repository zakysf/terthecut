import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/branch.dart';
import '../models/barber.dart';
import '../services/branch_service.dart';
import '../services/location_service.dart';

/// ============================================================================
/// Pengendali Data Cabang & Logika LBS (BranchController)
/// ============================================================================
/// Menggunakan pola ChangeNotifier (State Management Bawaan Flutter).
/// Ketika ada data yang berubah (misalnya cabang terdekat selesai dihitung),
/// fungsi `notifyListeners()` akan memicu UI (ListenableBuilder) untuk merender ulang.
class BranchController extends ChangeNotifier {
  // Singleton Pattern: Memastikan satu instance controller yang konsisten
  static final BranchController _instance = BranchController._internal();
  factory BranchController() => _instance;
  BranchController._internal();

  final _branchService = BranchService();
  final _locationService = LocationService();

  // State data cabang & pencarian teks
  bool _isLoading = false;
  List<Branch> _branches = [];
  List<Branch> _filteredBranches = [];
  List<Barber> _selectedBranchBarbers = [];
  String _searchQuery = '';

  // ---------------------------------------------------------------------------
  // State Khusus LBS (Location-Based Services - Modul 7)
  // ---------------------------------------------------------------------------
  Position? _currentPosition;              // Menyimpan koordinat GPS pengguna saat ini
  bool _isLocating = false;                 // Status loading saat sensor GPS sedang membaca satelit
  String? _locationError;                   // Menyimpan pesan jika GPS mati atau izin ditolak
  final Map<String, double> _branchDistances = {}; // Map relasi: branch.id -> jarak meter
  bool _isSortedByDistance = false;         // Penanda apakah daftar cabang sedang diurutkan terdekat

  // Getter publik agar UI hanya dapat membaca state (Read-Only)
  bool get isLoading => _isLoading;
  List<Branch> get branches => _filteredBranches;
  List<Barber> get selectedBranchBarbers => _selectedBranchBarbers;
  String get searchQuery => _searchQuery;

  Position? get currentPosition => _currentPosition;
  bool get isLocating => _isLocating;
  String? get locationError => _locationError;
  bool get isSortedByDistance => _isSortedByDistance;

  /// Mengambil jarak cabang tertentu dari posisi user (dalam satuan meter)
  double? getDistanceFor(String branchId) => _branchDistances[branchId];

  /// Mengambil jarak cabang dalam bentuk teks yang terformat rapi (misal: "850 m" atau "2.4 km")
  String? getFormattedDistanceFor(String branchId) {
    final distance = _branchDistances[branchId];
    if (distance == null) return null;
    return LocationService.formatDistance(distance);
  }

  /// Menemukan cabang yang jaraknya paling kecil (paling dekat) dengan pengguna
  Branch? get nearestBranch {
    if (_branchDistances.isEmpty || _branches.isEmpty) return null;
    Branch? closest;
    double minDistance = double.infinity;
    for (final b in _branches) {
      final d = _branchDistances[b.id];
      if (d != null && d < minDistance) {
        minDistance = d;
        closest = b;
      }
    }
    return closest;
  }

  /// Memuat daftar 11 cabang resmi dari database Supabase (atau fallback seed lokal)
  Future<void> retrieveBranches() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _branchService.fetchBranches();
      _branches = data;

      // Jika koordinat GPS user sudah pernah tersimpan, hitung ulang jaraknya secara otomatis
      if (_currentPosition != null) {
        _calculateDistancesForPosition(_currentPosition!);
      }

      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Gagal memuat cabang: $e');
    }
  }

  /// =========================================================================
  /// ALUR UTAMA FITUR LBS (Modul 7 Contoh Program 7.12):
  /// 1. Aktifkan indikator loading GPS.
  /// 2. Panggil LocationService untuk meminta izin & koordinat GPS HP pengguna.
  /// 3. Hitung jarak pengguna ke seluruh cabang Ter The Cut.
  /// 4. Urutkan (sort) daftar cabang dari jarak terdekat ke terjauh.
  /// 5. Kabari tampilan antarmuka (notifyListeners) untuk memperbarui tampilan.
  /// =========================================================================
  Future<void> findNearestBranches() async {
    try {
      _isLocating = true;
      _locationError = null;
      notifyListeners();

      // Langkah 1 & 2: Ambil posisi koordinat GPS terkini
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        
        // Langkah 3: Hitung jarak ke setiap cabang
        _calculateDistancesForPosition(position);

        // Langkah 4: Urutkan list cabang berdasarkan jarak secara ascending (terdekat di atas)
        _branches.sort((a, b) {
          final distA = _branchDistances[a.id] ?? double.infinity;
          final distB = _branchDistances[b.id] ?? double.infinity;
          return distA.compareTo(distB);
        });

        _isSortedByDistance = true;
        _applyFilter();
      }

      _isLocating = false;
      notifyListeners();
    } catch (e) {
      // Tangani error (misal GPS tidak aktif atau pengguna menolak izin)
      _isLocating = false;
      _locationError = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  /// Helper untuk menghitung jarak setiap cabang terhadap satu koordinat posisi user
  void _calculateDistancesForPosition(Position pos) {
    for (final b in _branches) {
      if (b.latitude != null && b.longitude != null) {
        final dist = _locationService.calculateDistance(
          userLat: pos.latitude,
          userLng: pos.longitude,
          targetLat: b.latitude!,
          targetLng: b.longitude!,
        );
        _branchDistances[b.id] = dist;
      }
    }
  }

  /// Mengembalikan urutan cabang ke urutan standar semula (berdasarkan nomor sort_order)
  void resetSort() {
    _branches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _isSortedByDistance = false;
    _applyFilter();
    notifyListeners();
  }

  /// Fitur pencarian teks cabang (berdasarkan nama cabang, alamat, atau kota)
  void searchBranches(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Memfilter cabang aktif berdasarkan query pencarian pengguna
  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredBranches = List.from(_branches);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredBranches = _branches.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q);
      }).toList();
    }
  }

  /// Mengambil data 2 kapster profesional yang bertugas pada cabang yang dipilih
  Future<void> loadBarbersForBranch(String branchId) async {
    try {
      _selectedBranchBarbers = [];
      notifyListeners();
      final barbers = await _branchService.fetchBarbersByBranch(branchId);
      _selectedBranchBarbers = barbers;
      notifyListeners();
    } catch (e) {
      _selectedBranchBarbers = [];
      notifyListeners();
    }
  }
}
