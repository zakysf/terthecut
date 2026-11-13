import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  // In-memory mock jika Supabase belum terhubung
  static final List<Profile> _mockProfiles = [
    Profile(
      id: 'mock-admin-1',
      role: 'admin',
      phone: '081999888777',
      name: 'Admin Utama Ter The Cut',
      pointsBalance: 0,
      lifetimePoints: 0,
    ),
    Profile(
      id: 'mock-customer-1',
      role: 'customer',
      phone: '081234567890',
      name: 'Bagas Pratama',
      pointsBalance: 120,
      lifetimePoints: 120,
      lastVisitAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

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

  /// LOGIN SEDERHANA: Langsung mencocokkan nomor telepon dan kata sandi di database
  Future<Profile> login({
    required String identifier, // Nomor telepon
    required String password,
    bool asAdmin = false,
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

        if (asAdmin && !profile.isAdmin) {
          throw Exception('Akun ini bukan akun staf admin.');
        }

        _currentSessionProfile = profile;
        return profile;
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception:', '').trim());
      }
    } else {
      // Mock Fallback Mode
      await Future.delayed(const Duration(milliseconds: 500));
      final found = _mockProfiles.cast<Profile?>().firstWhere(
            (p) => p?.phone == phone,
            orElse: () => null,
          );

      if (found != null) {
        if (asAdmin && !found.isAdmin) {
          throw Exception('Akun ini bukan akun staf admin.');
        }
        _currentSessionProfile = found;
        return found;
      }

      final newMock = Profile(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        role: asAdmin ? 'admin' : 'customer',
        phone: phone,
        name: asAdmin ? 'Admin Ter The Cut' : 'Pelanggan Ter The Cut',
      );
      _mockProfiles.add(newMock);
      _currentSessionProfile = newMock;
      return newMock;
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
      // Mock Fallback Mode
      await Future.delayed(const Duration(milliseconds: 500));
      final existing = _mockProfiles.any((p) => p.phone == phone);
      if (existing) {
        throw Exception('Nomor telepon sudah terdaftar. Silakan langsung masuk.');
      }

      final profile = Profile(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        role: 'customer',
        name: name.trim(),
        phone: phone,
        pointsBalance: 0,
        lifetimePoints: 0,
      );
      _mockProfiles.add(profile);
      _currentSessionProfile = profile;
      return profile;
    }
  }

  Future<void> logout() async {
    _currentSessionProfile = null;
  }

  Profile? get currentProfile => _currentSessionProfile;
}
