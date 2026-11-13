import 'package:get/get.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/branch_service.dart';
import '../services/loyalty_service.dart';
import '../models/branch.dart';
import 'auth_controller.dart';

class AdminController extends GetxController {
  final BookingService _bookingService = BookingService();
  final BranchService _branchService = BranchService();
  final LoyaltyService _loyaltyService = LoyaltyService();

  final RxList<Branch> branches = <Branch>[].obs;
  final RxString selectedBranchId = 'all'.obs;
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final RxString statusFilter = 'all'.obs;

  final RxList<Booking> scheduleBookings = <Booking>[].obs;
  final RxBool isLoading = false.obs;

  // Rekap Kasir
  int get totalToday => scheduleBookings.length;
  int get pendingCount => scheduleBookings.where((b) => b.status == 'confirmed' || b.status == 'arrived').length;
  int get completedCount => scheduleBookings.where((b) => b.status == 'completed').length;

  int get totalRevenue => scheduleBookings
      .where((b) => b.status == 'completed')
      .fold(0, (sum, b) => sum + b.servicePrice);

  int get totalPointsAwarded => scheduleBookings
      .where((b) => b.status == 'completed')
      .fold(0, (sum, b) => sum + b.servicePoints);

  List<Booking> get filteredBookings {
    if (statusFilter.value == 'all') {
      return scheduleBookings;
    }
    if (statusFilter.value == 'active' || statusFilter.value == 'confirmed') {
      return scheduleBookings.where((b) => b.status == 'confirmed' || b.status == 'arrived').toList();
    }
    return scheduleBookings.where((b) => b.status == statusFilter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadBranches();
    loadSchedule();
  }

  Future<void> loadBranches() async {
    try {
      final list = await _branchService.fetchBranches();
      branches.assignAll(list);
    } catch (_) {}
  }

  Future<void> loadSchedule() async {
    isLoading.value = true;
    try {
      final list = await _bookingService.fetchAdminDailySchedule(
        branchId: selectedBranchId.value == 'all' ? null : selectedBranchId.value,
        date: selectedDate.value,
      );
      scheduleBookings.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  void changeBranch(String branchId) {
    selectedBranchId.value = branchId;
    loadSchedule();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    loadSchedule();
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
  }

  /// Admin/Kasir menandai pelanggan Datang / Tiba di lokasi (US-19)
  Future<void> markBookingArrived(Booking booking) async {
    try {
      await _bookingService.markBookingArrived(booking.id);
      await loadSchedule();
      Get.snackbar(
        'Pelanggan Hadir',
        '${booking.customerName ?? "Pelanggan"} telah ditandai Hadir di cabang.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.ink,
        colorText: AppColors.paper,
      );
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
    }
  }

  /// Admin/Kasir menyelesaikan pengerjaan layanan & membukukan transaksi secara otomatis (US-19)
  Future<void> completeBooking(Booking booking) async {
    Get.defaultDialog(
      title: 'Konfirmasi Kasir',
      middleText:
          'Selesaikan layanan ${booking.serviceName}?\nTransaksi Rp ${booking.servicePrice} akan dibukukan dan +${booking.servicePoints} Poin akan otomatis ditambahkan ke akun pelanggan.',
      textConfirm: 'Ya, Selesaikan',
      textCancel: 'Batal',
      confirmTextColor: AppColors.paper,
      buttonColor: AppColors.success,
      onConfirm: () async {
        Get.back();
        try {
          await _bookingService.completeBooking(booking: booking);

          // Catat juga ke loyalty service mock jika ada
          _loyaltyService.recordPointEarning(
            customerId: booking.customerId,
            points: booking.servicePoints,
            serviceName: booking.serviceName,
          );

          // Update profile pelanggan jika pelanggan yang sama sedang login
          if (Get.isRegistered<AuthController>()) {
            final auth = Get.find<AuthController>();
            if (auth.currentProfile?.id == booking.customerId ||
                (booking.customerPhone != null && auth.currentProfile?.phone == booking.customerPhone)) {
              final curr = auth.currentProfile!;
              auth.updateCurrentProfile(
                curr.copyWith(
                  pointsBalance: curr.pointsBalance + booking.servicePoints,
                  lifetimePoints: curr.lifetimePoints + booking.servicePoints,
                ),
              );
            }
          }

          await loadSchedule();

          Get.snackbar(
            'Layanan Selesai',
            'Booking ${booking.code} telah diselesaikan. Transaksi & +${booking.servicePoints} poin berhasil dicatat!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: AppColors.paper,
            duration: const Duration(seconds: 4),
          );
        } catch (e) {
          Get.snackbar('Gagal', e.toString());
        }
      },
    );
  }
}
