import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/branch_service.dart';
import '../services/loyalty_service.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

/// Singleton controller Panel Kasir & Operasional Admin (US-18, US-19, US-20).
class AdminController extends ChangeNotifier {
  static final AdminController _instance = AdminController._internal();
  factory AdminController() => _instance;
  AdminController._internal();

  final BookingService _bookingService = BookingService();
  final BranchService _branchService = BranchService();
  final LoyaltyService _loyaltyService = LoyaltyService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  List<Branch> branches = [];
  String selectedBranchId = 'all';
  DateTime selectedDate = DateTime.now();
  String statusFilter = 'all';

  List<Booking> scheduleBookings = [];
  bool isLoading = false;
  String errorMessage = '';

  // Pencarian Cepat Pelanggan oleh Kasir dengan Debounce 300ms (US-20)
  List<Profile> searchedCustomers = [];
  bool isSearching = false;
  String customerSearchQuery = '';
  Timer? _searchDebounce;

  // Rekap Kasir
  int get totalToday => scheduleBookings.length;
  int get pendingCount => scheduleBookings
      .where((b) => b.status == 'confirmed' || b.status == 'arrived')
      .length;
  int get completedCount =>
      scheduleBookings.where((b) => b.status == 'completed').length;

  int get totalRevenue => scheduleBookings
      .where((b) => b.status == 'completed')
      .fold(0, (sum, b) => sum + b.servicePrice);

  int get totalPointsAwarded => scheduleBookings
      .where((b) => b.status == 'completed')
      .fold(0, (sum, b) => sum + b.servicePoints);

  List<Booking> get filteredBookings {
    if (statusFilter == 'all') {
      return scheduleBookings;
    }
    if (statusFilter == 'active' || statusFilter == 'confirmed') {
      return scheduleBookings
          .where((b) => b.status == 'confirmed' || b.status == 'arrived')
          .toList();
    }
    return scheduleBookings.where((b) => b.status == statusFilter).toList();
  }

  /// Mengubah query pencarian pelanggan dengan debounce native 300 ms (US-20).
  void onCustomerSearchChanged(String query) {
    customerSearchQuery = query;
    notifyListeners();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      performCustomerSearch(query);
    });
  }

  /// Menjalankan pencarian data pelanggan untuk kasir.
  Future<void> performCustomerSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      searchedCustomers = [];
      isSearching = false;
      notifyListeners();
      return;
    }

    try {
      isSearching = true;
      notifyListeners();

      searchedCustomers = await _authService.searchCustomers(clean);
    } catch (_) {
      searchedCustomers = [];
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadBranches() async {
    try {
      branches = await _branchService.fetchBranches();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSchedule() async {
    isLoading = true;
    notifyListeners();
    try {
      scheduleBookings = await _bookingService.fetchAdminDailySchedule(
        branchId: selectedBranchId == 'all' ? null : selectedBranchId,
        date: selectedDate,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void changeBranch(String branchId) {
    selectedBranchId = branchId;
    notifyListeners();
    loadSchedule();
  }

  void changeDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
    loadSchedule();
  }

  void setStatusFilter(String status) {
    statusFilter = status;
    notifyListeners();
  }

  /// Admin/Kasir menandai pelanggan Datang / Tiba di lokasi (US-19).
  Future<bool> markBookingArrived(Booking booking) async {
    try {
      errorMessage = '';
      await _bookingService.markBookingArrived(booking.id);
      await loadSchedule();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin/Kasir menyelesaikan pengerjaan layanan & membukukan transaksi otomatis (US-19).
  Future<bool> executeCompleteBooking(Booking booking) async {
    try {
      errorMessage = '';
      await _bookingService.completeBooking(booking: booking);

      // Catat juga ke loyalty service mock jika ada
      _loyaltyService.recordPointEarning(
        customerId: booking.customerId,
        points: booking.servicePoints,
        serviceName: booking.serviceName,
      );

      // Update profile pelanggan jika pelanggan yang sama sedang login
      final auth = AuthController();
      if (auth.currentProfile?.id == booking.customerId ||
          (booking.customerPhone != null &&
              auth.currentProfile?.phone == booking.customerPhone)) {
        final curr = auth.currentProfile!;
        auth.updateCurrentProfile(
          curr.copyWith(
            pointsBalance: curr.pointsBalance + booking.servicePoints,
            lifetimePoints: curr.lifetimePoints + booking.servicePoints,
          ),
        );
      }

      // Terbitkan notifikasi in-app ke pelanggan (US-21)
      _notificationService.createNotification(
        userId: booking.customerId,
        title: 'Layanan Selesai (+${booking.servicePoints} Poin)',
        message:
            'Layanan ${booking.serviceName} di cabang ${booking.branchName} telah selesai. Poin loyalitas Anda otomatis bertambah.',
        type: 'points',
      );

      await loadSchedule();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
