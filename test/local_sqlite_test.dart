import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:terthecut/models/booking.dart';
import 'package:terthecut/models/branch.dart';
import 'package:terthecut/services/local_database_helper.dart';

void main() {
  // Inisialisasi FFI SQLite untuk eksekusi unit test di lingkungan Desktop (Windows/Mac/Linux)
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database inMemoryDb;

  setUp(() async {
    // Gunakan in-memory database path agar setiap test terisolasi dan bersih
    inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    // Buat skema tabel SQLite sesuai helper
    await inMemoryDb.execute('''
      CREATE TABLE ${LocalDatabaseHelper.tableBookings} (
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

    await inMemoryDb.execute('''
      CREATE TABLE ${LocalDatabaseHelper.tableBranches} (
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

    // Suntikkan instance database pengujian ke LocalDatabaseHelper
    LocalDatabaseHelper.instance.setDatabaseForTesting(inMemoryDb);
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  group('LocalDatabaseHelper (SQLite) CRUD & Offline Persistence', () {
    test('Menyimpan booking baru dan membacanya kembali dari SQLite', () async {
      final booking = Booking(
        id: 'bk-test-1',
        code: 'TTC-123456',
        customerId: 'user-1',
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        branchId: 'br-1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Prof. DR. Soepomo SH No. 55',
        barberId: 'barber-1a',
        barberName: 'Bagas',
        serviceId: 'srv-1',
        serviceName: 'Gentleman Cut',
        servicePrice: 45000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: DateTime(2026, 11, 26, 14, 0),
        endsAt: DateTime(2026, 11, 26, 15, 0),
        status: 'confirmed',
      );

      // Simpan ke SQLite
      final insertResult = await LocalDatabaseHelper.instance.upsertBooking(booking, syncStatus: 'pending');
      expect(insertResult, greaterThan(0));

      // Cek jumlah data
      final count = await LocalDatabaseHelper.instance.countBookings();
      expect(count, equals(1));

      // Ambil riwayat booking pelanggan
      final customerBookings = await LocalDatabaseHelper.instance.getBookingsForCustomer('user-1');
      expect(customerBookings.length, equals(1));
      expect(customerBookings.first.code, equals('TTC-123456'));
      expect(customerBookings.first.barberName, equals('Bagas'));
      expect(customerBookings.first.servicePrice, equals(45000));
    });

    test('Memperbarui status booking di SQLite (misal pembatalan)', () async {
      final booking = Booking(
        id: 'bk-test-2',
        code: 'TTC-999888',
        customerId: 'user-2',
        branchId: 'br-5',
        branchName: 'Cabang Mrican 2',
        branchAddress: 'Jl. Tantular No. 440',
        barberId: 'barber-5a',
        barberName: 'Bayu',
        serviceId: 'srv-1',
        serviceName: 'Gentleman Cut',
        servicePrice: 45000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: DateTime(2026, 11, 27, 10, 0),
        endsAt: DateTime(2026, 11, 27, 11, 0),
        status: 'confirmed',
      );

      await LocalDatabaseHelper.instance.upsertBooking(booking);

      // Update status menjadi cancelled
      final updateRows = await LocalDatabaseHelper.instance.updateBookingStatus(
        'bk-test-2',
        'cancelled',
        cancelReason: 'Ada urusan mendadak',
        cancelledAt: DateTime(2026, 11, 26, 10, 0),
      );
      expect(updateRows, equals(1));

      // Verifikasi pembacaan
      final list = await LocalDatabaseHelper.instance.getBookingsForCustomer('user-2');
      expect(list.first.status, equals('cancelled'));
      expect(list.first.cancelReason, equals('Ada urusan mendadak'));
    });

    test('Menyimpan cache cabang dan koordinat LBS ke SQLite', () async {
      final branches = [
        Branch(
          id: 'br-1',
          name: 'Cabang Warungboto',
          address: 'Jl. Prof. DR. Soepomo SH No. 55',
          city: 'Kota Yogyakarta',
          latitude: -7.8115,
          longitude: 110.3925,
        ),
        Branch(
          id: 'br-5',
          name: 'Cabang Mrican 2',
          address: 'Jl. Tantular No. 440',
          city: 'Sleman',
          latitude: -7.7712,
          longitude: 110.3934,
        ),
      ];

      // Cache cabang ke SQLite
      await LocalDatabaseHelper.instance.cacheBranches(branches);

      // Ambil kembali cache dari SQLite
      final cached = await LocalDatabaseHelper.instance.getCachedBranches();
      expect(cached.length, equals(2));
      expect(cached[0].name, equals('Cabang Warungboto'));
      expect(cached[0].latitude, equals(-7.8115));
      expect(cached[1].name, equals('Cabang Mrican 2'));
      expect(cached[1].longitude, equals(110.3934));
    });
  });
}
