import 'dart:math';
import '../config/supabase_config.dart';
import '../models/booking.dart';
import '../models/barber.dart';

class TimeSlot {
  final int hour; // 10..21
  final String label; // "10:00", "11:00", dsb.
  final bool isAvailable;
  final bool isPast;
  final String? reason; // Alasan jika tidak tersedia (misal "Penuh", "Tutup", "Waktu Lewat")

  TimeSlot({
    required this.hour,
    required this.label,
    required this.isAvailable,
    this.isPast = false,
    this.reason,
  });

  String get displayRange {
    final endHour = (hour + 1).toString().padLeft(2, '0');
    final startHour = hour.toString().padLeft(2, '0');
    return '$startHour:00 - $endHour:00';
  }
}

class BookingService {
  // In-memory cache & fallback storage untuk demo luring / tes
  static final List<Booking> _mockBookings = [];

  /// Mengambil riwayat booking milik pelanggan tertentu
  Future<List<Booking>> fetchCustomerBookings(String customerId) async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('bookings')
            .select()
            .eq('customer_id', customerId)
            .order('starts_at', ascending: false);

        final list = (data as List).map((e) => Booking.fromJson(e)).toList();
        return list;
      } catch (e) {
        // Fallback ke mock jika query gagal
      }
    }

    // Filter dari mock bookings
    final results = _mockBookings
        .where((b) => b.customerId == customerId)
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return results;
  }

  /// Mengambil booking aktif pada cabang dan tanggal tertentu untuk kalkulasi ketersediaan slot
  Future<List<Booking>> fetchActiveBookings(String branchId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('bookings')
            .select()
            .eq('branch_id', branchId)
            .inFilter('status', ['confirmed', 'arrived'])
            .gte('starts_at', startOfDay.toIso8601String())
            .lte('starts_at', endOfDay.toIso8601String());

        return (data as List).map((e) => Booking.fromJson(e)).toList();
      } catch (e) {
        // Fallback ke mock
      }
    }

    return _mockBookings.where((b) {
      final matchesBranch = b.branchId == branchId;
      final isActive = b.status == 'confirmed' || b.status == 'arrived';
      final isSameDate = b.startsAt.year == date.year &&
          b.startsAt.month == date.month &&
          b.startsAt.day == date.day;
      return matchesBranch && isActive && isSameDate;
    }).toList();
  }

  /// Menghitung slot waktu 1 jam bulat (10:00 - 21:00) sesuai aturan US-08:
  /// - Jam operasional 10:00 - 22:00
  /// - Layanan durasi D jam butuh slot berurutan D jam hingga <= 22:00
  /// - Waktu yang sudah lewat di hari H+0 ditandai disabled
  /// - Memeriksa bentrok dengan kapster terpilih atau kapster cabang (jika auto)
  Future<List<TimeSlot>> calculateAvailableSlots({
    required String branchId,
    required List<Barber> branchBarbers,
    required String? selectedBarberId, // null jika auto-assign
    required int durationHours, // 1, 2, atau 3
    required DateTime date,
  }) async {
    final activeBookings = await fetchActiveBookings(branchId, date);
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    final List<TimeSlot> slots = [];

    // Jam mulai operasional 10:00 s/d 21:00 (karena tutup 22:00)
    for (int hour = 10; hour <= 21; hour++) {
      final slotStart = DateTime(date.year, date.month, date.day, hour, 0, 0);
      final slotEnd = slotStart.add(Duration(hours: durationHours));
      final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

      // 1. Cek batas jam tutup cabang (maksimal selesai jam 22:00)
      if (hour + durationHours > 22) {
        slots.add(TimeSlot(
          hour: hour,
          label: hourLabel,
          isAvailable: false,
          reason: 'Melebihi jam tutup (22:00)',
        ));
        continue;
      }

      // 2. Cek apakah jam sudah terlewat untuk hari ini
      if (isToday && slotStart.isBefore(now)) {
        slots.add(TimeSlot(
          hour: hour,
          label: hourLabel,
          isAvailable: false,
          isPast: true,
          reason: 'Waktu telah lewat',
        ));
        continue;
      }

      // 3. Cek ketersediaan kapster
      if (selectedBarberId != null && selectedBarberId.isNotEmpty) {
        // Kapster spesifik dipilih
        final isClashing = _isBarberClashing(
          barberId: selectedBarberId,
          start: slotStart,
          end: slotEnd,
          bookings: activeBookings,
        );

        slots.add(TimeSlot(
          hour: hour,
          label: hourLabel,
          isAvailable: !isClashing,
          reason: isClashing ? 'Kapster sedang ada jadwal' : null,
        ));
      } else {
        // Auto-assign: slot tersedia jika ADA minimal 1 kapster cabang yang kosong di rentang waktu ini
        final availableBarbers = branchBarbers.where((barber) {
          return !_isBarberClashing(
            barberId: barber.id,
            start: slotStart,
            end: slotEnd,
            bookings: activeBookings,
          );
        }).toList();

        final hasAvailable = availableBarbers.isNotEmpty;
        slots.add(TimeSlot(
          hour: hour,
          label: hourLabel,
          isAvailable: hasAvailable,
          reason: hasAvailable ? null : 'Semua kapster terisi',
        ));
      }
    }

    return slots;
  }

  /// Cek apakah kapster memiliki bentrok jadwal
  bool _isBarberClashing({
    required String barberId,
    required DateTime start,
    required DateTime end,
    required List<Booking> bookings,
  }) {
    for (final b in bookings) {
      if (b.barberId == barberId) {
        // Overlap condition: start < b.endsAt && end > b.startsAt
        if (start.isBefore(b.endsAt) && end.isAfter(b.startsAt)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Algoritma Auto-Assign Kapster (US-09):
  /// Memilih kapster cabang yang kosong dan memiliki beban jadwal paling sedikit pada tanggal tsb
  Barber selectBestBarberForAutoAssign({
    required List<Barber> branchBarbers,
    required DateTime start,
    required DateTime end,
    required List<Booking> activeBookings,
  }) {
    // 1. Filter kapster yang benar-benar kosong di jam tersebut
    final freeBarbers = branchBarbers.where((b) {
      return !_isBarberClashing(
        barberId: b.id,
        start: start,
        end: end,
        bookings: activeBookings,
      );
    }).toList();

    if (freeBarbers.isEmpty) {
      throw Exception('SLOT_TAKEN: Tidak ada kapster yang tersedia di jam ini.');
    }

    // 2. Hitung jumlah booking setiap kapster pada hari tersebut
    freeBarbers.sort((a, b) {
      final countA = activeBookings.where((bk) => bk.barberId == a.id).length;
      final countB = activeBookings.where((bk) => bk.barberId == b.id).length;
      if (countA != countB) {
        return countA.compareTo(countB); // Pilih yang paling sedikit jadwalnya
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return freeBarbers.first;
  }

  /// Membuat booking baru dengan verifikasi anti-double booking (US-09)
  Future<Booking> createBooking({
    required String customerId,
    String? customerName,
    String? customerPhone,
    required String branchId,
    required String branchName,
    required String branchAddress,
    required List<Barber> branchBarbers,
    String? selectedBarberId, // null bila auto-assign
    required String serviceId,
    required String serviceName,
    required int servicePrice,
    required int servicePoints,
    required int durationHours,
    String? hairstyleId,
    String? hairstyleName,
    required DateTime startsAt,
  }) async {
    final endsAt = startsAt.add(Duration(hours: durationHours));

    // Verifikasi jam operasional
    if (startsAt.hour < 10 || endsAt.hour > 22 || (endsAt.hour == 22 && endsAt.minute > 0)) {
      throw Exception('Jam pemesanan harus berada dalam rentang 10:00 - 22:00 WIB.');
    }

    // Ambil data booking aktif untuk cek concurrency
    final activeBookings = await fetchActiveBookings(branchId, startsAt);

    // Tentukan kapster yang bertugas
    String assignedBarberId;
    String assignedBarberName;
    String barberPref;

    if (selectedBarberId != null && selectedBarberId.isNotEmpty) {
      barberPref = 'chosen';
      assignedBarberId = selectedBarberId;
      final barber = branchBarbers.firstWhere(
        (b) => b.id == selectedBarberId,
        orElse: () => Barber(id: selectedBarberId, branchId: branchId, name: 'Kapster Ter The Cut'),
      );
      assignedBarberName = barber.name;

      // Cek bentrok kapster pilihan
      if (_isBarberClashing(
        barberId: assignedBarberId,
        start: startsAt,
        end: endsAt,
        bookings: activeBookings,
      )) {
        throw Exception('Jadwal ini baru saja diambil orang lain. Silakan pilih jam lain.');
      }
    } else {
      barberPref = 'auto';
      final bestBarber = selectBestBarberForAutoAssign(
        branchBarbers: branchBarbers,
        start: startsAt,
        end: endsAt,
        activeBookings: activeBookings,
      );
      assignedBarberId = bestBarber.id;
      assignedBarberName = bestBarber.name;
    }

    // Generate kode unik TTC-XXXXXX
    final randomHex = (100000 + Random().nextInt(900000)).toString();
    final code = 'TTC-$randomHex';
    final id = 'bk-${DateTime.now().millisecondsSinceEpoch}';

    final newBooking = Booking(
      id: id,
      code: code,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      branchId: branchId,
      branchName: branchName,
      branchAddress: branchAddress,
      barberId: assignedBarberId,
      barberName: assignedBarberName,
      barberPref: barberPref,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      servicePoints: servicePoints,
      durationHours: durationHours,
      hairstyleId: hairstyleId,
      hairstyleName: hairstyleName,
      startsAt: startsAt,
      endsAt: endsAt,
      status: 'confirmed',
      createdAt: DateTime.now(),
    );

    // Simpan ke Supabase jika terhubung
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final payload = {
          'code': newBooking.code,
          'customer_id': newBooking.customerId,
          'branch_id': newBooking.branchId,
          'barber_id': newBooking.barberId,
          'barber_pref': newBooking.barberPref,
          'service_id': newBooking.serviceId,
          'hairstyle_id': newBooking.hairstyleId,
          'service_name': newBooking.serviceName,
          'service_price': newBooking.servicePrice,
          'service_points': newBooking.servicePoints,
          'duration_hours': newBooking.durationHours,
          'starts_at': newBooking.startsAt.toIso8601String(),
          'ends_at': newBooking.endsAt.toIso8601String(),
          'status': 'confirmed',
        };

        final response = await client.from('bookings').insert(payload).select().single();
        final created = Booking.fromJson(response).copyWith(
          branchName: branchName,
          branchAddress: branchAddress,
          barberName: assignedBarberName,
          customerName: customerName,
        );
        _mockBookings.insert(0, created);
        return created;
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('exclude') ||
            errorMsg.contains('overlap') ||
            errorMsg.contains('slot_taken') ||
            errorMsg.contains('23p01')) {
          throw Exception('Jadwal ini baru saja diambil orang lain. Silakan pilih jam lain.');
        }
        // Fallback simpan ke mock jika error non-bentrok (misal tabel belum ada di cloud)
      }
    }

    // Simpan ke mock
    _mockBookings.insert(0, newBooking);
    return newBooking;
  }

  /// Membatalkan booking dengan verifikasi minimal 2 jam (US-10)
  Future<bool> cancelBooking({
    required Booking booking,
    required String reason,
  }) async {
    if (!booking.canCancel) {
      throw Exception('Pembatalan hanya dapat dilakukan minimal 2 jam sebelum waktu reservasi.');
    }

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('bookings').update({
          'status': 'cancelled',
          'cancel_reason': reason,
          'cancelled_at': DateTime.now().toIso8601String(),
        }).eq('id', booking.id);
      } catch (e) {
        // Fallback update mock
      }
    }

    // Update in mock cache
    final index = _mockBookings.indexWhere((b) => b.id == booking.id || b.code == booking.code);
    if (index != -1) {
      _mockBookings[index] = _mockBookings[index].copyWith(
        status: 'cancelled',
        cancelReason: reason,
        cancelledAt: DateTime.now(),
      );
    }

    return true;
  }
}

