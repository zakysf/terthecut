import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  // In-memory cache jika Supabase belum terhubung / luring
  static final List<Profile> _inMemoryProfiles = [];

  static Profile? _currentSessionProfile;

  /// Normalisasi nomor telepon: hanya digit angka (misal 081234567890)
  static String normalizePhone(String raw) {
    var digits = raw.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('628')) {
      digits = '0${digits.substring(2)}';
    } else if (digits.startsWith('62')) {
      digits = '0${digits.substring(2)}';
    }
    return digits;
  }

  /// LOGIN PORTAL TUNGGAL: Mencocokkan nomor telepon dan kata sandi di database
  Future<Profile> login({
    required String identifier, // Nomor telepon
    required String password,
  }) async {
    final phone = normalizePhone(identifier);

    if (phone.length < 10) {
      throw Exception('Nomor telepon minimal 10 digit angka.');
    }
    if (password.length < 6) {
      throw Exception('Kata sandi minimal 6 karakter.');
    }

    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final query = client
            .from('profiles')
            .select()
            .eq('phone', phone)
            .eq('password', password);

        final data = await query.maybeSingle();

        if (data == null) {
          throw Exception('Nomor telepon atau kata sandi salah.');
        }

        final profile = Profile.fromJson(data);
        _currentSessionProfile = profile;
        return profile;
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception:', '').trim());
      }
    } else {
      // Fallback Mode (luring / test)
      await Future.delayed(const Duration(milliseconds: 50));
      final found = _inMemoryProfiles.cast<Profile?>().firstWhere(
            (p) => p?.phone == phone,
            orElse: () => null,
          );

      if (found != null) {
        _currentSessionProfile = found;
        return found;
      }

      throw Exception('Nomor telepon atau kata sandi tidak ditemukan.');
    }
  }

  /// REGISTER SEDERHANA: Simpan nama, no telp, dan password langsung ke tabel profiles
  Future<Profile> register({
    required String name,
    required String identifier, // Nomor telepon
    required String password,
  }) async {
    final phone = normalizePhone(identifier);

    if (name.trim().isEmpty) {
      throw Exception('Nama lengkap wajib diisi.');
    }
    if (phone.length < 10) {
      throw Exception('Nomor telepon minimal 10 digit angka.');
    }
    if (password.length < 6) {
      throw Exception('Kata sandi minimal 6 karakter.');
    }

    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        // 1. Cek apakah nomor sudah ada di database
        final existing = await client
            .from('profiles')
            .select('id')
            .eq('phone', phone)
            .maybeSingle();

        if (existing != null) {
          throw Exception('Nomor telepon sudah terdaftar. Silakan langsung masuk.');
        }

        // 2. Simpan user baru langsung ke tabel profiles
        final data = await client.from('profiles').insert({
          'phone': phone,
          'name': name.trim(),
          'password': password,
          'role': 'customer',
          'points_balance': 0,
          'lifetime_points': 0,
        }).select().single();

        final profile = Profile.fromJson(data);
        _currentSessionProfile = profile;
        return profile;
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception:', '').trim());
      }
    } else {
      // Fallback Mode (luring / test)
      await Future.delayed(const Duration(milliseconds: 50));
      final existing = _inMemoryProfiles.any((p) => p.phone == phone);
      if (existing) {
        throw Exception('Nomor telepon sudah terdaftar. Silakan langsung masuk.');
      }

      final profile = Profile(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        role: 'customer',
        name: name.trim(),
        phone: phone,
        pointsBalance: 0,
        lifetimePoints: 0,
      );
      _inMemoryProfiles.add(profile);
      _currentSessionProfile = profile;
      return profile;
    }
  }

  Future<void> logout() async {
    _currentSessionProfile = null;
  }

  /// Pencarian Cepat Data Pelanggan oleh Kasir (US-20)
  Future<List<Profile>> searchCustomers(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('profiles')
            .select()
            .eq('role', 'customer')
            .or('name.ilike.%$cleanQuery%,phone.ilike.%$cleanQuery%')
            .limit(10);

        final list = (data as List)
            .map((p) => Profile.fromJson(p as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    // Fallback In-Memory Profiles
    return _inMemoryProfiles.where((p) {
      if (p.role != 'customer') return false;
      final nameMatch = (p.name ?? '').toLowerCase().contains(cleanQuery);
      final phoneMatch = (p.phone ?? '').contains(cleanQuery);
      return nameMatch || phoneMatch;
    }).toList();
  }

  /// Memperbarui profil terbaru dari database Supabase atau in-memory
  Future<Profile?> getProfile(String idOrPhone) async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final query = client.from('profiles').select();
        final data = idOrPhone.startsWith('08') || idOrPhone.startsWith('62')
            ? await query.eq('phone', normalizePhone(idOrPhone)).maybeSingle()
            : await query.eq('id', idOrPhone).maybeSingle();

        if (data != null) {
          final profile = Profile.fromJson(data);
          if (_currentSessionProfile?.id == profile.id || _currentSessionProfile?.phone == profile.phone) {
            _currentSessionProfile = profile;
          }
          return profile;
        }
      } catch (_) {}
    }

    return _inMemoryProfiles.cast<Profile?>().firstWhere(
          (p) => p?.id == idOrPhone || p?.phone == normalizePhone(idOrPhone),
          orElse: () => _currentSessionProfile,
        );
  }

  /// Menambahkan poin di cache memori agar sinkron luring
  static void creditMockPoints(String customerIdOrPhone, int points) {
    final normPhone = normalizePhone(customerIdOrPhone);
    final index = _inMemoryProfiles.indexWhere(
      (p) => p.id == customerIdOrPhone || p.phone == normPhone,
    );
    if (index != -1) {
      final curr = _inMemoryProfiles[index];
      _inMemoryProfiles[index] = curr.copyWith(
        pointsBalance: curr.pointsBalance + points,
        lifetimePoints: curr.lifetimePoints + points,
        lastVisitAt: DateTime.now(),
      );
    }

    if (_currentSessionProfile != null &&
        (_currentSessionProfile!.id == customerIdOrPhone || _currentSessionProfile!.phone == normPhone)) {
      _currentSessionProfile = _currentSessionProfile!.copyWith(
        pointsBalance: _currentSessionProfile!.pointsBalance + points,
        lifetimePoints: _currentSessionProfile!.lifetimePoints + points,
        lastVisitAt: DateTime.now(),
      );
    }
  }

  Profile? get currentProfile => _currentSessionProfile;

  void restoreSessionProfile(Profile? profile) {
    _currentSessionProfile = profile;
  }
}
