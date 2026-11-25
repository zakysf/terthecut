import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/booking.dart';
import '../models/branch.dart';

/// ============================================================================
/// LocalDatabaseHelper (SQLite Service)
/// ============================================================================
/// Kelas pembantu (helper) untuk mengelola database lokal SQLite pada perangkat.
/// Menggunakan pola Singleton (hanya 1 instance database yang aktif di seluruh app).
///
/// Keuntungan bagi pemula:
/// 1. Data tiket booking tersimpan permanen di memori fisik HP (file .db).
/// 2. Bekerja secara Offline-First: tetap bisa buka tiket saat tidak ada sinyal.
/// 3. Tabel SQL relasional standar dengan kolom bertipe TEXT, INTEGER, dan REAL.
class LocalDatabaseHelper {
  // Pola Singleton: private constructor dan static instance
  LocalDatabaseHelper._internal();
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._internal();

  static const String _dbName = 'terthecut_local.db';
  static const int _dbVersion = 1;

  // Nama-nama tabel lokal
  static const String tableBookings = 'local_bookings';
  static const String tableBranches = 'local_branches';

  Database? _db;

  /// Getter untuk mengakses objek database SQLite.
  /// Jika belum dibuka, otomatis memanggil [_initDb].
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  /// Membuka dan menginisialisasi database SQLite di direktori dokumen aplikasi
  Future<Database> _initDb() async {
    // getDatabasesPath() mengambil direktori aman bawaan OS (Android/iOS)
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Callback yang dijalankan sekali saat database SQLite pertama kali dibuat
  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. Buat Tabel local_bookings
    await db.execute('''
      CREATE TABLE $tableBookings (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        branch_id TEXT NOT NULL,
        branch_name TEXT NOT NULL,
        branch_address TEXT,
        barber_id TEXT NOT NULL,
        barber_name TEXT NOT NULL,
        barber_pref TEXT DEFAULT 'chosen',
        service_id TEXT NOT NULL,
        service_name TEXT NOT NULL,
        service_price INTEGER NOT NULL,
        service_points INTEGER DEFAULT 10,
        duration_hours INTEGER DEFAULT 1,
        hairstyle_id TEXT,
        hairstyle_name TEXT,
        starts_at TEXT NOT NULL,
        ends_at TEXT NOT NULL,
        status TEXT DEFAULT 'confirmed',
        cancel_reason TEXT,
        arrived_at TEXT,
        completed_at TEXT,
        cancelled_at TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 2. Buat Tabel local_branches (Cache Cabang & Koordinat LBS)
    await db.execute('''
      CREATE TABLE $tableBranches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT DEFAULT 'Yogyakarta',
        photo_url TEXT,
        open_time TEXT DEFAULT '10:00',
        close_time TEXT DEFAULT '22:00',
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  // ===========================================================================
  // OPERASI CRUD TABEL BOOKINGS (local_bookings)
  // ===========================================================================

  /// Menyimpan atau memperbarui data booking ke database lokal SQLite.
  /// Parameter [syncStatus] menandai apakah data sudah tersinkron ke cloud ('synced')
  /// atau masih antre offline ('pending').
  Future<int> upsertBooking(Booking booking, {String syncStatus = 'synced'}) async {
    final db = await database;
    final row = <String, dynamic>{
      'id': booking.id,
      'code': booking.code,
      'customer_id': booking.customerId,
      'customer_name': booking.customerName,
      'customer_phone': booking.customerPhone,
      'branch_id': booking.branchId,
      'branch_name': booking.branchName,
      'branch_address': booking.branchAddress,
      'barber_id': booking.barberId,
      'barber_name': booking.barberName,
      'barber_pref': booking.barberPref,
      'service_id': booking.serviceId,
      'service_name': booking.serviceName,
      'service_price': booking.servicePrice,
      'service_points': booking.servicePoints,
      'duration_hours': booking.durationHours,
      'hairstyle_id': booking.hairstyleId,
      'hairstyle_name': booking.hairstyleName,
      'starts_at': booking.startsAt.toIso8601String(),
      'ends_at': booking.endsAt.toIso8601String(),
      'status': booking.status,
      'cancel_reason': booking.cancelReason,
      'arrived_at': booking.arrivedAt?.toIso8601String(),
      'completed_at': booking.completedAt?.toIso8601String(),
      'cancelled_at': booking.cancelledAt?.toIso8601String(),
      'created_at': booking.createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };

    // ConflictAlgorithm.replace: Jika ID atau kode sudah ada, lakukan UPDATE otomatis
    return await db.insert(
      tableBookings,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil daftar riwayat booking milik pelanggan tertentu dari SQLite lokal
  Future<List<Booking>> getBookingsForCustomer(String customerId, {String? customerPhone}) async {
    final db = await database;

    List<Map<String, dynamic>> maps;
    if (customerPhone != null && customerPhone.isNotEmpty) {
      maps = await db.query(
        tableBookings,
        where: 'customer_id = ? OR customer_phone = ?',
        whereArgs: [customerId, customerPhone],
        orderBy: 'starts_at DESC',
      );
    } else {
      maps = await db.query(
        tableBookings,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'starts_at DESC',
      );
    }

    return maps.map((map) => _mapToBooking(map)).toList();
  }

  /// Mengambil semua booking lokal (digunakan untuk kasir / admin offline)
  Future<List<Booking>> getAllBookings() async {
    final db = await database;
    final maps = await db.query(
      tableBookings,
      orderBy: 'starts_at DESC',
    );
    return maps.map((map) => _mapToBooking(map)).toList();
  }

  /// Mengambil booking aktif pada cabang dan tanggal tertentu (untuk cek bentrok slot offline)
  Future<List<Booking>> getActiveBookingsForBranchDate(String branchId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      tableBookings,
      where: 'branch_id = ? AND status IN (?, ?) AND starts_at >= ? AND starts_at <= ?',
      whereArgs: [branchId, 'confirmed', 'arrived', startOfDay, endOfDay],
    );

    return maps.map((map) => _mapToBooking(map)).toList();
  }

  /// Memperbarui status booking (misal saat dibatalkan atau diselesaikan oleh kasir)
  Future<int> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? cancelReason,
    DateTime? arrivedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'status': newStatus,
    };

    if (cancelReason != null) values['cancel_reason'] = cancelReason;
    if (arrivedAt != null) values['arrived_at'] = arrivedAt.toIso8601String();
    if (completedAt != null) values['completed_at'] = completedAt.toIso8601String();
    if (cancelledAt != null) values['cancelled_at'] = cancelledAt.toIso8601String();

    return await db.update(
      tableBookings,
      values,
      where: 'id = ? OR code = ?',
      whereArgs: [bookingId, bookingId],
    );
  }

  /// Konversi row Map dari SQLite menjadi objek [Booking]
  Booking _mapToBooking(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Booking(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      branchId: map['branch_id']?.toString() ?? '',
      branchName: map['branch_name']?.toString() ?? 'Cabang Ter The Cut',
      branchAddress: map['branch_address']?.toString() ?? '',
      barberId: map['barber_id']?.toString() ?? '',
      barberName: map['barber_name']?.toString() ?? 'Kapster Ter The Cut',
      barberPref: map['barber_pref']?.toString() ?? 'chosen',
      serviceId: map['service_id']?.toString() ?? '',
      serviceName: map['service_name']?.toString() ?? 'Layanan Ter The Cut',
      servicePrice: (map['service_price'] as num?)?.toInt() ?? 0,
      servicePoints: (map['service_points'] as num?)?.toInt() ?? 10,
      durationHours: (map['duration_hours'] as num?)?.toInt() ?? 1,
      hairstyleId: map['hairstyle_id']?.toString(),
      hairstyleName: map['hairstyle_name']?.toString(),
      startsAt: parseDate(map['starts_at']),
      endsAt: parseDate(map['ends_at']),
      status: map['status']?.toString() ?? 'confirmed',
      cancelReason: map['cancel_reason']?.toString(),
      arrivedAt: map['arrived_at'] != null ? parseDate(map['arrived_at']) : null,
      completedAt: map['completed_at'] != null ? parseDate(map['completed_at']) : null,
      cancelledAt: map['cancelled_at'] != null ? parseDate(map['cancelled_at']) : null,
      createdAt: parseDate(map['created_at']),
    );
  }

  // ===========================================================================
  // OPERASI CRUD TABEL BRANCHES (local_branches Cache)
  // ===========================================================================

  /// Menyimpan sekumpulan cabang ke SQLite (caching data master dan koordinat LBS)
  Future<void> cacheBranches(List<Branch> branches) async {
    final db = await database;
    final batch = db.batch();

    for (final b in branches) {
      batch.insert(
        tableBranches,
        {
          'id': b.id,
          'name': b.name,
          'address': b.address,
          'city': b.city,
          'photo_url': b.photoUrl,
          'open_time': b.openTime,
          'close_time': b.closeTime,
          'is_active': b.isActive ? 1 : 0,
          'sort_order': b.sortOrder,
          'latitude': b.latitude,
          'longitude': b.longitude,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Mengambil seluruh data cabang yang tersimpan di SQLite lokal
  Future<List<Branch>> getCachedBranches() async {
    final db = await database;
    final maps = await db.query(
      tableBranches,
      orderBy: 'sort_order ASC',
    );

    return maps.map((map) {
      return Branch(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        city: map['city']?.toString() ?? 'Yogyakarta',
        photoUrl: map['photo_url']?.toString(),
        openTime: map['open_time']?.toString() ?? '10:00',
        closeTime: map['close_time']?.toString() ?? '22:00',
        isActive: (map['is_active'] as num?)?.toInt() == 1,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      );
    }).toList();
  }

  /// Menghitung total data booking di SQLite (berguna untuk testing atau pengecekan)
  Future<int> countBookings() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM $tableBookings');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Membersihkan isi tabel (berguna untuk reset sesi / testing)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableBookings);
    await db.delete(tableBranches);
  }

  /// Menutup koneksi database (dipanggil saat logout / dispose jika diperlukan)
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Setter khusus untuk pengujian unit test (memungkinkan injeksi mock / in-memory ffi database)
  void setDatabaseForTesting(Database testDb) {
    _db = testDb;
  }
}
