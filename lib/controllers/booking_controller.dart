import 'package:flutter/foundation.dart';
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

/// Singleton controller wizard reservasi 6 langkah dan daftar booking pelanggan.
class BookingController extends ChangeNotifier {
  static final BookingController _instance = BookingController._internal();
  factory BookingController() => _instance;
  BookingController._internal();

  final BookingService _bookingService = BookingService();
  final BranchService _branchService = BranchService();
  final LoyaltyService _loyaltyService = LoyaltyService();

  // Step Wizard: 0 = Cabang, 1 = Kapster, 2 = Layanan, 3 = Gaya Rambut, 4 = Waktu, 5 = Konfirmasi
  int currentStep = 0;

  // Pilihan Pengguna
  Branch? selectedBranch;
  Barber? selectedBarber;
  bool isAutoAssign = false;
  ServiceItem? selectedService;
  Hairstyle? selectedHairstyle;
  DateTime selectedDate = DateTime.now();
  TimeSlot? selectedSlot;

  // State Voucher Diskon
  RewardRedemption? appliedVoucher;
  List<RewardRedemption> usableVouchers = [];
  bool isLoadingVouchers = false;

  /// Nilai diskon dari voucher yang dipilih.
  int get discountAmount {
    final voucher = appliedVoucher;
    final service = selectedService;
    if (voucher == null || service == null) return 0;

    final name = voucher.rewardName.toLowerCase();
    if (name.contains('10.000') || name.contains('10k')) {
      return service.price >= 10000 ? 10000 : service.price;
    } else if (name.contains('gratis') || name.contains('free')) {
      return service.price;
    }
    return 10000 > service.price ? service.price : 10000;
  }

  /// Total harga layanan setelah potongan voucher diskon.
  int get finalPrice {
    final orig = selectedService?.price ?? 0;
    final disc = discountAmount;
    final res = orig - disc;
    return res > 0 ? res : 0;
  }

  // State Kapster & Slot
  List<Barber> branchBarbers = [];
  bool isLoadingBarbers = false;
  List<TimeSlot> availableSlots = [];
  bool isLoadingSlots = false;

  // State Proses & Riwayat
  bool isSubmitting = false;
  String errorMessage = '';
  List<Booking> myBookings = [];
  bool isLoadingBookings = false;

  // Pemesanan terakhir yang baru dibuat
  Booking? lastCreatedBooking;

  /// Daftar 5 hari ke depan (H+0 sampai H+4) sesuai US-08.
  List<DateTime> get availableDates {
    final now = DateTime.now();
    return List.generate(5, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }

  /// Memfilter booking yang berstatus akan datang (Upcoming).
  List<Booking> get upcomingBookings {
    return myBookings.where((b) => b.status == 'confirmed' || b.status == 'arrived').toList();
  }

  /// Memfilter booking yang sudah selesai atau dibatalkan (History).
  List<Booking> get historyBookings {
    return myBookings.where((b) => b.status == 'completed' || b.status == 'cancelled').toList();
  }

  /// Inisialisasi wizard booking baru.
  void initWizard({
    Branch? initialBranch,
    ServiceItem? initialService,
    Hairstyle? initialHairstyle,
  }) {
    currentStep = 0;
    selectedBranch = initialBranch;
    selectedBarber = null;
    isAutoAssign = false;
    selectedService = initialService;
    selectedHairstyle = initialHairstyle;
    selectedDate = DateTime.now();
    selectedSlot = null;
    appliedVoucher = null;
    usableVouchers = [];
    errorMessage = '';
    branchBarbers = [];
    availableSlots = [];

    if (initialBranch != null) {
      currentStep = 1; // Lompat ke pilih kapster jika cabang sudah dipilih
      loadBranchBarbers(initialBranch.id);
    }
    notifyListeners();
  }

  /// Memilih Cabang dan memuat kapster bertugas.
  Future<void> selectBranch(Branch branch) async {
    selectedBranch = branch;
    selectedBarber = null;
    isAutoAssign = false;
    selectedSlot = null;
    notifyListeners();

    await loadBranchBarbers(branch.id);
    currentStep = 1;
    notifyListeners();
  }

  /// Memuat 2 kapster spesifik cabang.
  Future<void> loadBranchBarbers(String branchId) async {
    isLoadingBarbers = true;
    notifyListeners();
    try {
      branchBarbers = await _branchService.fetchBarbersByBranch(branchId);
    } finally {
      isLoadingBarbers = false;
      notifyListeners();
    }
  }

  /// Memilih Kapster atau opsi Auto-Assign.
  void selectBarber(Barber? barber, {bool auto = false}) {
    if (auto) {
      isAutoAssign = true;
      selectedBarber = null;
    } else {
      isAutoAssign = false;
      selectedBarber = barber;
    }
    selectedSlot = null;
    currentStep = 2; // Lanjut ke pilih layanan
    notifyListeners();
  }

  /// Memilih Layanan.
  void selectService(ServiceItem service) {
    selectedService = service;
    selectedSlot = null;
    currentStep = 3; // Lanjut ke inspirasi rambut (opsional)
    notifyListeners();
  }

  /// Memilih Gaya Rambut (opsional).
  void selectHairstyle(Hairstyle? hairstyle) {
    selectedHairstyle = hairstyle;
    currentStep = 4; // Lanjut ke pilih tanggal & jam
    notifyListeners();
    loadAvailableSlots();
  }

  /// Lewati pemilihan gaya rambut.
  void skipHairstyle() {
    selectedHairstyle = null;
    currentStep = 4;
    notifyListeners();
    loadAvailableSlots();
  }

  /// Memilih Tanggal (H+0 s/d H+4).
  void selectDate(DateTime date) {
    selectedDate = date;
    selectedSlot = null;
    notifyListeners();
    loadAvailableSlots();
  }

  /// Memilih Slot Waktu.
  void selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    selectedSlot = slot;
    notifyListeners();
  }

  /// Menghitung ketersediaan slot jam 1 jam bulat (10:00 - 21:00).
  Future<void> loadAvailableSlots() async {
    final branch = selectedBranch;
    final service = selectedService;
    if (branch == null || service == null) return;

    isLoadingSlots = true;
    errorMessage = '';
    notifyListeners();

    try {
      availableSlots = await _bookingService.calculateAvailableSlots(
        branchId: branch.id,
        branchBarbers: branchBarbers,
        selectedBarberId: isAutoAssign ? null : selectedBarber?.id,
        durationHours: service.durationHours,
        date: selectedDate,
      );
    } catch (e) {
      errorMessage = 'Gagal memuat slot jadwal: $e';
    } finally {
      isLoadingSlots = false;
      notifyListeners();
    }
  }

  /// Lanjut ke ringkasan konfirmasi. Mengembalikan `false` jika slot belum dipilih.
  bool proceedToSummary() {
    if (selectedSlot == null) {
      errorMessage = 'Silakan tentukan jam jadwal potong rambut terlebih dahulu.';
      notifyListeners();
      return false;
    }
    errorMessage = '';
    loadUsableVouchers();
    currentStep = 5;
    notifyListeners();
    return true;
  }

  /// Memuat voucher aktif yang dapat digunakan pelanggan.
  Future<void> loadUsableVouchers() async {
    final customerId = AuthController().currentProfile?.id;
    if (customerId == null) return;

    isLoadingVouchers = true;
    notifyListeners();
    try {
      final list = await _loyaltyService.fetchCustomerVouchers(customerId);
      usableVouchers = list.where((v) => v.isUsable).toList();
    } catch (_) {
      usableVouchers = [];
    } finally {
      isLoadingVouchers = false;
      notifyListeners();
    }
  }

  /// Memilih / menerapkan voucher diskon.
  void applyVoucher(RewardRedemption? voucher) {
    appliedVoucher = voucher;
    notifyListeners();
  }

  /// Membatalkan voucher diskon terpilih.
  void removeVoucher() {
    appliedVoucher = null;
    notifyListeners();
  }

  /// Navigasi kembali satu langkah pada wizard.
  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  /// Eksekusi Konfirmasi Booking (US-09). Mengembalikan [Booking] jika sukses, `null` jika gagal.
  Future<Booking?> confirmBooking() async {
    final branch = selectedBranch;
    final service = selectedService;
    final slot = selectedSlot;

    if (branch == null || service == null || slot == null) {
      errorMessage = 'Data pemesanan belum lengkap.';
      notifyListeners();
      return null;
    }

    final currentProfile = AuthController().currentProfile;
    final customerId = currentProfile?.id ?? 'demo-user-1';
    final customerName = currentProfile?.name ?? 'Pelanggan Ter The Cut';
    final customerPhone = currentProfile?.phone ?? '';

    final slotDate = selectedDate;
    final startsAt = DateTime(slotDate.year, slotDate.month, slotDate.day, slot.hour, 0, 0);

    isSubmitting = true;
    errorMessage = '';
    notifyListeners();

    try {
      final booking = await _bookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        branchId: branch.id,
        branchName: branch.name,
        branchAddress: branch.address,
        branchBarbers: branchBarbers,
        selectedBarberId: isAutoAssign ? null : selectedBarber?.id,
        serviceId: service.id,
        serviceName: service.name,
        servicePrice: finalPrice,
        servicePoints: service.points,
        durationHours: service.durationHours,
        hairstyleId: selectedHairstyle?.id,
        hairstyleName: selectedHairstyle?.name,
        startsAt: startsAt,
      );

      // Tandai voucher telah digunakan jika ada voucher diskon yang diterapkan
      final usedVoucher = appliedVoucher;
      if (usedVoucher != null) {
        await _loyaltyService.useVoucher(usedVoucher.voucherCode);
        appliedVoucher = null;
      }

      lastCreatedBooking = booking;
      await loadMyBookings();

      // Terbitkan notifikasi in-app ke pelanggan (US-21)
      NotificationService().createNotification(
        userId: customerId,
        title: 'Reservasi Berhasil (${booking.code})',
        message:
            'Jadwal Anda di ${booking.branchName} (${booking.formattedTimeRange}) telah terkonfirmasi.',
        type: 'booking',
      );

      return booking;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      // Jika terjadi bentrok, refresh slot agar slot yang terisi segera ter-update
      loadAvailableSlots();
      notifyListeners();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Memuat riwayat booking milik pengguna yang sedang login.
  Future<void> loadMyBookings() async {
    final profile = AuthController().currentProfile;
    final customerId = profile?.id ?? 'demo-user-1';
    final customerPhone = profile?.phone;

    isLoadingBookings = true;
    notifyListeners();
    try {
      myBookings = await _bookingService.fetchCustomerBookings(
        customerId,
        customerPhone: customerPhone,
      );
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }

  /// Eksekusi pembatalan reservasi (US-10) setelah dikonfirmasi oleh pengguna.
  Future<bool> executeCancelBooking(
    Booking booking, {
    String reason = 'Dibatalkan oleh pelanggan',
  }) async {
    if (!booking.canCancel) {
      errorMessage =
          'Sesuai ketentuan, pembatalan jadwal hanya dapat dilakukan minimal 2 jam (120 menit) sebelum waktu reservasi dimulai.';
      notifyListeners();
      return false;
    }

    try {
      errorMessage = '';
      await _bookingService.cancelBooking(booking: booking, reason: reason);
      await loadMyBookings();

      NotificationService().createNotification(
        userId: booking.customerId,
        title: 'Reservasi Dibatalkan',
        message:
            'Reservasi ${booking.code} di ${booking.branchName} telah berhasil dibatalkan.',
        type: 'booking',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearSession() {
    myBookings = [];
    lastCreatedBooking = null;
    usableVouchers = [];
    appliedVoucher = null;
    errorMessage = '';
    notifyListeners();
  }
}
