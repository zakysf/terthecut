import 'dart:math';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/booking.dart';
import '../models/barber.dart';
import 'auth_service.dart';
import 'local_database_helper.dart';

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
  // In-memory cache & fallback storage untuk demo luring / offline
  static final List<Booking> _inMemoryBookings = [];

  static bool _isUuid(String? str) {
    if (str == null) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
  }

  /// Mengambil riwayat booking milik pelanggan tertentu
  Future<List<Booking>> fetchCustomerBookings(String customerId, {String? customerPhone}) async {
    final client = SupabaseConfig.client;
    final List<Booking> remoteList = [];

    String? resolvedId = _isUuid(customerId) ? customerId : null;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        if (resolvedId == null && customerPhone != null && customerPhone.isNotEmpty) {
          final normPhone = AuthService.normalizePhone(customerPhone);
          final p = await client.from('profiles').select('id').eq('phone', normPhone).maybeSingle();
          if (p != null) resolvedId = p['id'].toString();
        }

        var query = client
            .from('bookings')
            .select('*, profiles(name, phone), branches(name, address), barbers(name)');

        if (resolvedId != null) {
          final data = await query.eq('customer_id', resolvedId).order('starts_at', ascending: false);
          remoteList.addAll((data as List).map((e) => Booking.fromJson(e)).toList());
        }
      } catch (e) {
        // Fallback jika query gagal
      }
    }

    // 1. Ambil data lokal dari SQLite (Offline-First)
    List<Booking> localList = [];
    try {
      localList = await LocalDatabaseHelper.instance.getBookingsForCustomer(
        customerId,
        customerPhone: customerPhone,
      );
    } catch (_) {}

    // Merge dengan in-memory bookings dan data lokal SQLite
    final Map<String, Booking> merged = {};
    for (final b in localList) {
      merged[b.code] = b;
    }
    for (final b in _inMemoryBookings) {
      final matchesId = b.customerId == customerId || (resolvedId != null && b.customerId == resolvedId);
      final matchesPhone = (customerPhone != null && customerPhone.isNotEmpty && b.customerPhone == customerPhone);

      if (matchesId || matchesPhone) {
        merged[b.code] = b;
      }
    }
    for (final b in remoteList) {
      merged[b.code] = b;
      // Simpan data remote ke SQLite sebagai background cache lokal
      try {
        LocalDatabaseHelper.instance.upsertBooking(b, syncStatus: 'synced');
      } catch (_) {}
    }

    final results = merged.values.toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return results;
  }

  /// Mengambil booking aktif pada cabang dan tanggal tertentu untuk kalkulasi ketersediaan slot
  Future<List<Booking>> fetchActiveBookings(String branchId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final client = SupabaseConfig.client;
    final List<Booking> remoteList = [];

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('bookings')
            .select()
            .eq('branch_id', branchId)
            .inFilter('status', ['confirmed', 'arrived'])
            .gte('starts_at', startOfDay.toIso8601String())
            .lte('starts_at', endOfDay.toIso8601String());

        remoteList.addAll((data as List).map((e) => Booking.fromJson(e)).toList());
      } catch (e) {
        // Fallback ke mock
      }
    }

    final Map<String, Booking> merged = {};
    final localMatches = _inMemoryBookings.where((b) {
      final matchesBranch = b.branchId == branchId;
      final isActive = b.status == 'confirmed' || b.status == 'arrived';
      final isSameDate = b.startsAt.year == date.year &&
          b.startsAt.month == date.month &&
          b.startsAt.day == date.day;
      return matchesBranch && isActive && isSameDate;
    });

    for (final b in localMatches) {
      merged[b.code] = b;
    }
    for (final b in remoteList) {
      merged[b.code] = b;
    }

    return merged.values.toList();
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

    // Simpan ke database lokal SQLite (Offline-First)
    try {
      await LocalDatabaseHelper.instance.upsertBooking(newBooking, syncStatus: 'pending');
    } catch (_) {}

    // Simpan ke Supabase jika terhubung
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        // Validasi dan resolusi UUID untuk Supabase
        String validCustomerId = customerId;
        if (!_isUuid(validCustomerId) && customerPhone != null && customerPhone.isNotEmpty) {
          final normPhone = AuthService.normalizePhone(customerPhone);
          final p = await client.from('profiles').select('id').eq('phone', normPhone).maybeSingle();
          if (p != null) validCustomerId = p['id'].toString();
        }
        if (!_isUuid(validCustomerId)) {
          final p = await client.from('profiles').select('id').eq('role', 'customer').limit(1).maybeSingle();
          if (p != null) validCustomerId = p['id'].toString();
        }

        String validBranchId = branchId;
        if (!_isUuid(validBranchId)) {
          final b = await client.from('branches').select('id').limit(1).maybeSingle();
          if (b != null) validBranchId = b['id'].toString();
        }

        String validBarberId = assignedBarberId;
        if (!_isUuid(validBarberId)) {
          final bar = await client.from('barbers').select('id').eq('branch_id', validBranchId).limit(1).maybeSingle();
          if (bar != null) {
            validBarberId = bar['id'].toString();
          } else {
            final anyBar = await client.from('barbers').select('id').limit(1).maybeSingle();
            if (anyBar != null) validBarberId = anyBar['id'].toString();
          }
        }

        String validServiceId = serviceId;
        if (!_isUuid(validServiceId)) {
          final s = await client.from('services').select('id').limit(1).maybeSingle();
          if (s != null) validServiceId = s['id'].toString();
        }

        final validHairstyleId = _isUuid(hairstyleId) ? hairstyleId : null;

        final payload = {
          'code': newBooking.code,
          'customer_id': validCustomerId,
          'branch_id': validBranchId,
          'barber_id': validBarberId,
          'barber_pref': newBooking.barberPref == 'chosen' ? 'chosen' : 'auto',
          'service_id': validServiceId,
          'hairstyle_id': validHairstyleId,
          'service_name': newBooking.serviceName,
          'service_price': newBooking.servicePrice,
          'service_points': newBooking.servicePoints,
          'duration_hours': newBooking.durationHours,
          'starts_at': newBooking.startsAt.toIso8601String(),
          'ends_at': newBooking.endsAt.toIso8601String(),
          'status': 'confirmed',
        };

        final response = await client
            .from('bookings')
            .insert(payload)
            .select('*, profiles(name, phone), branches(name, address), barbers(name)')
            .single();

        final created = Booking.fromJson(response).copyWith(
          branchName: branchName,
          branchAddress: branchAddress,
          barberName: assignedBarberName,
          customerName: customerName,
          customerPhone: customerPhone,
        );
        _inMemoryBookings.insert(0, created);
        // Tandai status sync SQLite menjadi synced
        try {
          await LocalDatabaseHelper.instance.upsertBooking(created, syncStatus: 'synced');
        } catch (_) {}
        return created;
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('exclude') ||
            errorMsg.contains('overlap') ||
            errorMsg.contains('slot_taken') ||
            errorMsg.contains('23p01')) {
          throw Exception('Jadwal ini baru saja diambil orang lain. Silakan pilih jam lain.');
        }
        // Fallback simpan ke in-memory jika error non-bentrok
        debugPrint('Catatan simpan Supabase (akan aktif di cloud setelah RLS dibuka): $e');
      }
    }

    // Simpan ke in-memory
    _inMemoryBookings.insert(0, newBooking);
    return newBooking;
  }

  /// Membatalkan booking (US-10). Admin dapat membatalkan tanpa batas waktu 2 jam via [bypassTimeLimit].
  Future<bool> cancelBooking({
    required Booking booking,
    required String reason,
    bool bypassTimeLimit = false,
  }) async {
    if (!bypassTimeLimit && !booking.canCancel) {
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
        // Fallback update in-memory
      }
    }

    // Update in in-memory cache
    final index = _inMemoryBookings.indexWhere((b) => b.id == booking.id || b.code == booking.code);
    if (index != -1) {
      _inMemoryBookings[index] = _inMemoryBookings[index].copyWith(
        status: 'cancelled',
        cancelReason: reason,
        cancelledAt: DateTime.now(),
      );
    }

    // Update di database lokal SQLite
    try {
      await LocalDatabaseHelper.instance.updateBookingStatus(
        booking.id,
        'cancelled',
        cancelReason: reason,
        cancelledAt: DateTime.now(),
      );
    } catch (_) {}

    return true;
  }

  /// Mengambil jadwal harian admin per cabang dan tanggal (US-18)
  Future<List<Booking>> fetchAdminDailySchedule({
    String? branchId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final client = SupabaseConfig.client;
    final List<Booking> remoteList = [];

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        var query = client
            .from('bookings')
            .select('*, profiles(name, phone), branches(name, address), barbers(name)')
            .gte('starts_at', startOfDay.toIso8601String())
            .lte('starts_at', endOfDay.toIso8601String());

        if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
          query = query.eq('branch_id', branchId);
        }

        final data = await query.order('starts_at', ascending: true);
        remoteList.addAll((data as List).map((e) => Booking.fromJson(e)).toList());
      } catch (e) {
        // Fallback ke in-memory
      }
    }

    final Map<String, Booking> merged = {};
    final localMatches = _inMemoryBookings.where((b) {
      final matchesBranch =
          (branchId == null || branchId.isEmpty || branchId == 'all') || b.branchId == branchId;
      final isSameDate = b.startsAt.year == targetDate.year &&
          b.startsAt.month == targetDate.month &&
          b.startsAt.day == targetDate.day;
      return matchesBranch && isSameDate;
    });

    for (final b in localMatches) {
      merged[b.code] = b;
    }
    for (final b in remoteList) {
      merged[b.code] = b;
    }

    final results = merged.values.toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return results;
  }

  /// Admin/Kasir menandai pelanggan Datang / Hadir (US-19)
  Future<bool> markBookingArrived(String bookingId) async {
    final now = DateTime.now();
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('bookings').update({
          'status': 'arrived',
          'arrived_at': now.toIso8601String(),
        }).eq('id', bookingId);
      } catch (e) {
        // Fallback update in-memory
      }
    }

    final index = _inMemoryBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _inMemoryBookings[index] = _inMemoryBookings[index].copyWith(
        status: 'arrived',
        arrivedAt: now,
      );
    }
    // Update di database lokal SQLite
    try {
      await LocalDatabaseHelper.instance.updateBookingStatus(
        bookingId,
        'arrived',
        arrivedAt: now,
      );
    } catch (_) {}
    return true;
  }

  /// Admin/Kasir menyelesaikan booking & mencatat transaksi + poin otomatis via RPC complete_booking (US-19)
  Future<Booking> completeBooking({required Booking booking}) async {
    final now = DateTime.now();
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        // 1. Update status booking
        if (_isUuid(booking.id)) {
          await client.from('bookings').update({
            'status': 'completed',
            'completed_at': now.toIso8601String(),
          }).eq('id', booking.id);
        }

        // 2. Insert transaksi jika booking.id dan customer_id valid UUID
        if (_isUuid(booking.id) && _isUuid(booking.customerId)) {
          await client.from('transactions').insert({
            'booking_id': booking.id,
            'customer_id': booking.customerId,
            'branch_id': booking.branchId,
            'service_name': booking.serviceName,
            'amount': booking.servicePrice,
            'points_earned': booking.servicePoints,
            'occurred_at': now.toIso8601String(),
          });
        }

        // 3. Tambah poin di profiles
        if (_isUuid(booking.customerId)) {
          final userRes = await client
              .from('profiles')
              .select('points_balance, lifetime_points')
              .eq('id', booking.customerId)
              .maybeSingle();

          if (userRes != null) {
            final currentPoints = (userRes['points_balance'] as num?)?.toInt() ?? 0;
            final currentLifetime = (userRes['lifetime_points'] as num?)?.toInt() ?? 0;

            await client.from('profiles').update({
              'points_balance': currentPoints + booking.servicePoints,
              'lifetime_points': currentLifetime + booking.servicePoints,
              'last_visit_at': now.toIso8601String(),
            }).eq('id', booking.customerId);
          }

          // 4. Catat ke point_ledger
          await client.from('point_ledger').insert({
            'customer_id': booking.customerId,
            'delta': booking.servicePoints,
            'reason': 'visit',
            'note': booking.serviceName,
          });
        }
      } catch (e) {
        // Fallback proses in-memory
        debugPrint('Catatan complete Supabase: $e');
      }
    }

    // Update in-memory
    AuthService.creditMockPoints(booking.customerId, booking.servicePoints);
    if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) {
      AuthService.creditMockPoints(booking.customerPhone!, booking.servicePoints);
    }

    final index = _inMemoryBookings.indexWhere((b) => b.id == booking.id || b.code == booking.code);
    Booking updated = booking.copyWith(
      status: 'completed',
      completedAt: now,
    );
    if (index != -1) {
      _inMemoryBookings[index] = updated;
    }

    // Update di database lokal SQLite
    try {
      await LocalDatabaseHelper.instance.updateBookingStatus(
        booking.id,
        'completed',
        completedAt: now,
      );
    } catch (_) {}

    return updated;
  }
}

