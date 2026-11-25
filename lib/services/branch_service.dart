import '../config/supabase_config.dart';
import '../models/branch.dart';
import '../models/barber.dart';
import 'local_database_helper.dart';

class BranchService {
  // Master Seed Fallback untuk 11 Cabang (Alamat lengkap Google Maps & Koordinat GPS Yogyakarta)
  static final List<Branch> _seedBranches = [
    Branch(
      id: 'br-1',
      name: 'Cabang Warungboto',
      address: 'Jl. Prof. DR. Soepomo SH No. 55, Warungboto, Kec. Umbulharjo',
      city: 'Kota Yogyakarta',
      sortOrder: 1,
      latitude: -7.8115,
      longitude: 110.3925,
    ),
    Branch(
      id: 'br-2',
      name: 'Cabang Tajem (Maguwoharjo)',
      address: 'Jl. Stadion No. 34 / Jl. Raya Tajem, Denokan, Maguwoharjo, Kec. Depok',
      city: 'Sleman',
      sortOrder: 2,
      latitude: -7.7554,
      longitude: 110.4289,
    ),
    Branch(
      id: 'br-3',
      name: 'Cabang Soragan',
      address: 'Jl. Soragan No. 80, Cungkuk, Ngestiharjo, Kec. Kasihan',
      city: 'Bantul',
      sortOrder: 3,
      latitude: -7.7942,
      longitude: 110.3421,
    ),
    Branch(
      id: 'br-4',
      name: 'Cabang Palagan',
      address: 'Jl. Palagan Tentara Pelajar No. 88, Mudal, Sariharjo, Kec. Ngaglik',
      city: 'Sleman',
      sortOrder: 4,
      latitude: -7.7328,
      longitude: 110.3789,
    ),
    Branch(
      id: 'br-5',
      name: 'Cabang Mrican 2 (Pringwulung)',
      address: 'Jl. Tantular No. 440, Pringwulung, Condongcatur, Kec. Depok',
      city: 'Sleman',
      sortOrder: 5,
      latitude: -7.7712,
      longitude: 110.3934,
    ),
    Branch(
      id: 'br-6',
      name: 'Cabang Mrican 1 (Demangan)',
      address: 'Jl. Brojomusti, Jl. Pringgodani No. 3, Demangan / Caturtunggal, Kec. Depok',
      city: 'Sleman',
      sortOrder: 6,
      latitude: -7.7785,
      longitude: 110.3912,
    ),
    Branch(
      id: 'br-7',
      name: 'Cabang Godean',
      address: 'Jl. Godean Km. 4.5 (Jl. Sidoarum - Bantulan No. 43), Bantulan, Sidoarum, Kec. Godean',
      city: 'Sleman',
      sortOrder: 7,
      latitude: -7.7761,
      longitude: 110.3347,
    ),
    Branch(
      id: 'br-8',
      name: 'Cabang Gedongkiwo',
      address: 'Jl. Bantul No. 74B, Gedongkiwo, Kec. Mantrijeron',
      city: 'Kota Yogyakarta',
      sortOrder: 8,
      latitude: -7.8184,
      longitude: 110.3592,
    ),
    Branch(
      id: 'br-9',
      name: 'Cabang Gamping',
      address: 'Jl. Pasir No. 1 / Jl. Wates Km. 5, Ambarketawang, Kec. Gamping',
      city: 'Sleman',
      sortOrder: 9,
      latitude: -7.8016,
      longitude: 110.3235,
    ),
    Branch(
      id: 'br-10',
      name: 'Cabang Concat (Condongcatur)',
      address: 'Jl. Nusa Indah / Jl. Anggajaya, Condongcatur, Kec. Depok',
      city: 'Sleman',
      sortOrder: 10,
      latitude: -7.7578,
      longitude: 110.4012,
    ),
    Branch(
      id: 'br-11',
      name: 'Cabang Candi Gebang',
      address: 'Jl. Candi Gebang No. 5, Jetis, Wedomartani, Kec. Ngemplak',
      city: 'Sleman',
      sortOrder: 11,
      latitude: -7.7472,
      longitude: 110.4183,
    ),
  ];

  // Master Seed Fallback untuk Kapster (2 Kapster per Cabang)
  static final List<Barber> _seedBarbers = [
    Barber(id: 'barber-1a', branchId: 'br-1', name: 'Bagas', sortOrder: 1),
    Barber(id: 'barber-1b', branchId: 'br-1', name: 'Rian', sortOrder: 2),
    Barber(id: 'barber-2a', branchId: 'br-2', name: 'Fajar', sortOrder: 1),
    Barber(id: 'barber-2b', branchId: 'br-2', name: 'Dimas', sortOrder: 2),
    Barber(id: 'barber-3a', branchId: 'br-3', name: 'Doni', sortOrder: 1),
    Barber(id: 'barber-3b', branchId: 'br-3', name: 'Gilang', sortOrder: 2),
    Barber(id: 'barber-4a', branchId: 'br-4', name: 'Hendra', sortOrder: 1),
    Barber(id: 'barber-4b', branchId: 'br-4', name: 'Satria', sortOrder: 2),
    Barber(id: 'barber-5a', branchId: 'br-5', name: 'Bayu', sortOrder: 1),
    Barber(id: 'barber-5b', branchId: 'br-5', name: 'Angga', sortOrder: 2),
    Barber(id: 'barber-6a', branchId: 'br-6', name: 'Reza', sortOrder: 1),
    Barber(id: 'barber-6b', branchId: 'br-6', name: 'Ilham', sortOrder: 2),
    Barber(id: 'barber-7a', branchId: 'br-7', name: 'Wahyu', sortOrder: 1),
    Barber(id: 'barber-7b', branchId: 'br-7', name: 'Pandu', sortOrder: 2),
    Barber(id: 'barber-8a', branchId: 'br-8', name: 'Yusuf', sortOrder: 1),
    Barber(id: 'barber-8b', branchId: 'br-8', name: 'Tegar', sortOrder: 2),
    Barber(id: 'barber-9a', branchId: 'br-9', name: 'Aris', sortOrder: 1),
    Barber(id: 'barber-9b', branchId: 'br-9', name: 'Bima', sortOrder: 2),
    Barber(id: 'barber-10a', branchId: 'br-10', name: 'Aldi', sortOrder: 1),
    Barber(id: 'barber-10b', branchId: 'br-10', name: 'Farhan', sortOrder: 2),
    Barber(id: 'barber-11a', branchId: 'br-11', name: 'Rio', sortOrder: 1),
    Barber(id: 'barber-11b', branchId: 'br-11', name: 'Danang', sortOrder: 2),
  ];

  Future<List<Branch>> fetchBranches() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client
            .from('branches')
            .select()
            .order('sort_order', ascending: true);
        final list = (data as List).map((e) {
          final b = Branch.fromJson(e as Map<String, dynamic>);
          // Jika di database Supabase kolom latitude/longitude belum terisi, padukan dengan seed koordinat
          if (b.latitude == null || b.longitude == null) {
            final seed = _seedBranches.firstWhere(
              (s) => s.name.toLowerCase() == b.name.toLowerCase() || s.sortOrder == b.sortOrder,
              orElse: () => _seedBranches.first,
            );
            return b.copyWith(latitude: seed.latitude, longitude: seed.longitude);
          }
          return b;
        }).toList();

        // Caching ke database lokal SQLite
        try {
          await LocalDatabaseHelper.instance.cacheBranches(list);
        } catch (_) {}

        return list;
      } catch (e) {
        // Fallback coba ambil dari cache SQLite lokal
        try {
          final cached = await LocalDatabaseHelper.instance.getCachedBranches();
          if (cached.isNotEmpty) return cached;
        } catch (_) {}
        return _seedBranches;
      }
    }

    // Mode Offline / First-Run: Coba baca dari SQLite
    try {
      final cached = await LocalDatabaseHelper.instance.getCachedBranches();
      if (cached.isNotEmpty) return cached;
      // Inisialisasi awal SQLite dengan master seed
      await LocalDatabaseHelper.instance.cacheBranches(_seedBranches);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));
    return _seedBranches;
  }

  Future<List<Barber>> fetchBarbersByBranch(String branchId) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client
            .from('barbers')
            .select()
            .eq('branch_id', branchId)
            .order('sort_order', ascending: true);
        return (data as List).map((e) => Barber.fromJson(e)).toList();
      } catch (e) {
        return _seedBarbers.where((b) => b.branchId == branchId).toList();
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _seedBarbers.where((b) => b.branchId == branchId).toList();
  }
}

