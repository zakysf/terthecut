import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/barber.dart';
import '../models/service_item.dart';
import '../models/hairstyle.dart';
import '../models/reward_redemption.dart';
import '../services/booking_service.dart';
import '../services/branch_service.dart';
import '../services/loyalty_service.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

class BookingController extends GetxController {
  final BookingService _bookingService = BookingService();
  final BranchService _branchService = BranchService();
  final LoyaltyService _loyaltyService = LoyaltyService();

  // Step Wizard: 0 = Cabang, 1 = Kapster, 2 = Layanan, 3 = Gaya Rambut, 4 = Waktu, 5 = Konfirmasi
  final RxInt currentStep = 0.obs;

  // Pilihan Pengguna
  final Rxn<Branch> selectedBranch = Rxn<Branch>();
  final Rxn<Barber> selectedBarber = Rxn<Barber>();
  final RxBool isAutoAssign = false.obs;
  final Rxn<ServiceItem> selectedService = Rxn<ServiceItem>();
  final Rxn<Hairstyle> selectedHairstyle = Rxn<Hairstyle>();
  final Rx<DateTime> selectedDate = Rx<DateTime>(DateTime.now());
  final Rxn<TimeSlot> selectedSlot = Rxn<TimeSlot>();

  // State Voucher Diskon
  final Rxn<RewardRedemption> appliedVoucher = Rxn<RewardRedemption>();
  final RxList<RewardRedemption> usableVouchers = <RewardRedemption>[].obs;
  final RxBool isLoadingVouchers = false.obs;

  /// Nilai diskon dari voucher yang dipilih
  int get discountAmount {
    final voucher = appliedVoucher.value;
    final service = selectedService.value;
    if (voucher == null || service == null) return 0;

    final name = voucher.rewardName.toLowerCase();
    if (name.contains('10.000') || name.contains('10k')) {
      return service.price >= 10000 ? 10000 : service.price;
    } else if (name.contains('gratis') || name.contains('free')) {
      return service.price;
    }
    return 10000 > service.price ? service.price : 10000;
  }

  /// Total harga layanan setelah potongan voucher diskon
  int get finalPrice {
    final orig = selectedService.value?.price ?? 0;
    final disc = discountAmount;
    final res = orig - disc;
    return res > 0 ? res : 0;
  }

  // State Kapster & Slot
  final RxList<Barber> branchBarbers = <Barber>[].obs;
  final RxBool isLoadingBarbers = false.obs;
  final RxList<TimeSlot> availableSlots = <TimeSlot>[].obs;
  final RxBool isLoadingSlots = false.obs;

  // State Proses & Riwayat
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Booking> myBookings = <Booking>[].obs;
  final RxBool isLoadingBookings = false.obs;

  // Pemesanan terakhir yang baru dibuat
  final Rxn<Booking> lastCreatedBooking = Rxn<Booking>();

  /// Daftar 5 hari ke depan (H+0 sampai H+4) sesuai US-08
  List<DateTime> get availableDates {
    final now = DateTime.now();
    return List.generate(5, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }

  /// Memfilter booking yang berstatus akan datang (Upcoming)
  List<Booking> get upcomingBookings {
    return myBookings.where((b) => b.status == 'confirmed' || b.status == 'arrived').toList();
  }

  /// Memfilter booking yang sudah selesai atau dibatalkan (History)
  List<Booking> get historyBookings {
    return myBookings.where((b) => b.status == 'completed' || b.status == 'cancelled').toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadMyBookings();
  }

  /// Inisialisasi wizard booking baru
  void initWizard({
    Branch? initialBranch,
    ServiceItem? initialService,
    Hairstyle? initialHairstyle,
  }) {
    currentStep.value = 0;
    selectedBranch.value = initialBranch;
    selectedBarber.value = null;
    isAutoAssign.value = false;
    selectedService.value = initialService;
    selectedHairstyle.value = initialHairstyle;
    selectedDate.value = DateTime.now();
    selectedSlot.value = null;
    appliedVoucher.value = null;
    usableVouchers.clear();
    errorMessage.value = '';
    branchBarbers.clear();
    availableSlots.clear();

    if (initialBranch != null) {
      loadBranchBarbers(initialBranch.id);
      currentStep.value = 1; // Lompat ke pilih kapster jika cabang sudah dipilih
    }
  }

  /// Memilih Cabang dan memuat kapster bertugas
  Future<void> selectBranch(Branch branch) async {
    selectedBranch.value = branch;
    selectedBarber.value = null;
    isAutoAssign.value = false;
    selectedSlot.value = null;
    await loadBranchBarbers(branch.id);
    currentStep.value = 1;
  }

  /// Memuat 2 kapster spesifik cabang
  Future<void> loadBranchBarbers(String branchId) async {
    isLoadingBarbers.value = true;
    try {
      final barbers = await _branchService.fetchBarbersByBranch(branchId);
      branchBarbers.assignAll(barbers);
    } finally {
      isLoadingBarbers.value = false;
    }
  }

  /// Memilih Kapster atau opsi Auto-Assign
  void selectBarber(Barber? barber, {bool auto = false}) {
    if (auto) {
      isAutoAssign.value = true;
      selectedBarber.value = null;
    } else {
      isAutoAssign.value = false;
      selectedBarber.value = barber;
    }
    selectedSlot.value = null;
    currentStep.value = 2; // Lanjut ke pilih layanan
  }

  /// Memilih Layanan
  void selectService(ServiceItem service) {
    selectedService.value = service;
    selectedSlot.value = null;
    currentStep.value = 3; // Lanjut ke inspirasi rambut (opsional)
  }

  /// Memilih Gaya Rambut (opsional)
  void selectHairstyle(Hairstyle? hairstyle) {
    selectedHairstyle.value = hairstyle;
    currentStep.value = 4; // Lanjut ke pilih tanggal & jam
    loadAvailableSlots();
  }

  /// Lewati pemilihan gaya rambut
  void skipHairstyle() {
    selectedHairstyle.value = null;
    currentStep.value = 4;
    loadAvailableSlots();
  }

  /// Memilih Tanggal (H+0 s/d H+4)
  void selectDate(DateTime date) {
    selectedDate.value = date;
    selectedSlot.value = null;
    loadAvailableSlots();
  }

  /// Memilih Slot Waktu
  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    selectedSlot.value = slot;
  }

  /// Menghitung ketersediaan slot jam 1 jam bulat (10:00 - 21:00)
  Future<void> loadAvailableSlots() async {
    final branch = selectedBranch.value;
    final service = selectedService.value;
    if (branch == null || service == null) return;

    isLoadingSlots.value = true;
    errorMessage.value = '';

    try {
      final slots = await _bookingService.calculateAvailableSlots(
        branchId: branch.id,
        branchBarbers: branchBarbers,
        selectedBarberId: isAutoAssign.value ? null : selectedBarber.value?.id,
        durationHours: service.durationHours,
        date: selectedDate.value,
      );
      availableSlots.assignAll(slots);
    } catch (e) {
      errorMessage.value = 'Gagal memuat slot jadwal: $e';
    } finally {
      isLoadingSlots.value = false;
    }
  }

  /// Lanjut ke ringkasan konfirmasi
  void proceedToSummary() {
    if (selectedSlot.value == null) {
      Get.snackbar(
        'Pilih Jam',
        'Silakan tentukan jam jadwal potong rambut terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.ink,
        colorText: AppColors.paper,
      );
      return;
    }
    loadUsableVouchers();
    currentStep.value = 5;
  }

  /// Memuat voucher aktif yang dapat digunakan pelanggan
  Future<void> loadUsableVouchers() async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final customerId = authController.currentProfile?.id;
    if (customerId == null) return;

    isLoadingVouchers.value = true;
    try {
      final list = await _loyaltyService.fetchCustomerVouchers(customerId);
      usableVouchers.assignAll(list.where((v) => v.isUsable).toList());
    } catch (_) {
      usableVouchers.clear();
    } finally {
      isLoadingVouchers.value = false;
    }
  }

  /// Memilih / menerapkan voucher diskon
  void applyVoucher(RewardRedemption? voucher) {
    appliedVoucher.value = voucher;
  }

  /// Membatalkan voucher diskon terpilih
  void removeVoucher() {
    appliedVoucher.value = null;
  }

  /// Navigasi kembali satu langkah pada wizard
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  /// Eksekusi Konfirmasi Booking (US-09)
  Future<void> confirmBooking() async {
    final branch = selectedBranch.value;
    final service = selectedService.value;
    final slot = selectedSlot.value;

    if (branch == null || service == null || slot == null) {
      Get.snackbar('Perhatian', 'Data pemesanan belum lengkap.');
      return;
    }

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final currentProfile = authController.currentProfile;
    final customerId = currentProfile?.id ?? 'demo-user-1';
    final customerName = currentProfile?.name ?? 'Pelanggan Ter The Cut';
    final customerPhone = currentProfile?.phone ?? '';

    final slotDate = selectedDate.value;
    final startsAt = DateTime(slotDate.year, slotDate.month, slotDate.day, slot.hour, 0, 0);

    isSubmitting.value = true;
    errorMessage.value = '';

    try {
      final booking = await _bookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        branchId: branch.id,
        branchName: branch.name,
        branchAddress: branch.address,
        branchBarbers: branchBarbers,
        selectedBarberId: isAutoAssign.value ? null : selectedBarber.value?.id,
        serviceId: service.id,
        serviceName: service.name,
        servicePrice: finalPrice,
        servicePoints: service.points,
        durationHours: service.durationHours,
        hairstyleId: selectedHairstyle.value?.id,
        hairstyleName: selectedHairstyle.value?.name,
        startsAt: startsAt,
      );

      // Tandai voucher telah digunakan jika ada voucher diskon yang diterapkan
      final usedVoucher = appliedVoucher.value;
      if (usedVoucher != null) {
        await _loyaltyService.useVoucher(usedVoucher.voucherCode);
        appliedVoucher.value = null;
      }

      lastCreatedBooking.value = booking;
      await loadMyBookings();

      // Terbitkan notifikasi in-app ke pelanggan (US-21)
      NotificationService().createNotification(
        userId: customerId,
        title: 'Reservasi Berhasil (${booking.code})',
        message:
            'Jadwal Anda di ${booking.branchName} (${booking.formattedTimeRange}) telah terkonfirmasi.',
        type: 'booking',
      );

      // Tampilkan dialog berhasil dengan estetika Editorial
      Get.dialog(
        Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppColors.accent, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  'RESERVASI BERHASIL',
                  style: Theme.of(Get.context!).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kode Booking Anda:',
                  style: Theme.of(Get.context!).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.code,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: AppColors.paper,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${booking.branchName}\n${booking.formattedDate}\n${booking.formattedTimeRange}',
                  textAlign: TextAlign.center,
                  style: Theme.of(Get.context!).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Get.back(); // Tutup dialog
                    Get.offNamed('/booking-detail', arguments: booking);
                  },
                  child: const Text('LIHAT DETAIL TIKET'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.offAllNamed('/home');
                  },
                  child: const Text('KEMBALI KE BERANDA'),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      errorMessage.value = msg;
      Get.snackbar(
        'Pemesanan Gagal',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.paper,
        duration: const Duration(seconds: 4),
      );
      // Jika terjadi bentrok, refresh slot agar slot yang terisi segera ter-update
      loadAvailableSlots();
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Memuat riwayat booking milik pengguna yang sedang login
  Future<void> loadMyBookings() async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final customerId = authController.currentProfile?.id ?? 'demo-user-1';
    final customerPhone = authController.currentProfile?.phone;

    isLoadingBookings.value = true;
    try {
      final list = await _bookingService.fetchCustomerBookings(
        customerId,
        customerPhone: customerPhone,
      );
      myBookings.assignAll(list);
    } finally {
      isLoadingBookings.value = false;
    }
  }

  /// Membatalkan reservasi (US-10)
  Future<void> cancelBooking(Booking booking, {String reason = 'Dibatalkan oleh pelanggan'}) async {
    if (!booking.canCancel) {
      Get.defaultDialog(
        title: 'Pembatalan Ditolak',
        middleText:
            'Sesuai ketentuan, pembatalan jadwal hanya dapat dilakukan minimal 2 jam (120 menit) sebelum waktu reservasi dimulai.',
        textConfirm: 'Mengerti',
        confirmTextColor: AppColors.paper,
        buttonColor: AppColors.ink,
        onConfirm: () => Get.back(),
      );
      return;
    }

    // Konfirmasi dialog
    Get.defaultDialog(
      title: 'Batalkan Reservasi?',
      middleText:
          'Apakah Anda yakin ingin membatalkan jadwal di ${booking.branchName} pada ${booking.formattedTimeRange}?',
      textConfirm: 'Ya, Batalkan',
      textCancel: 'Tidak',
      confirmTextColor: AppColors.paper,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await _bookingService.cancelBooking(booking: booking, reason: reason);
          await loadMyBookings();

          // Terbitkan notifikasi in-app pembatalan (US-21)
          NotificationService().createNotification(
            userId: booking.customerId,
            title: 'Reservasi Dibatalkan',
            message:
                'Reservasi ${booking.code} di ${booking.branchName} telah berhasil dibatalkan.',
            type: 'booking',
          );
          Get.snackbar(
            'Berhasil Dibatalkan',
            'Reservasi ${booking.code} telah berhasil dibatalkan.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.ink,
            colorText: AppColors.paper,
          );
        } catch (e) {
          Get.snackbar('Gagal Membatalkan', e.toString().replaceAll('Exception: ', ''));
        }
      },
    );
  }
}

