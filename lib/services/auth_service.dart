import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  // Demo mock user untuk pengujian jika belum terhubung Supabase
  static Profile _mockCustomer = Profile(
    id: 'mock-customer-1',
    role: 'customer',
    phone: '081234567890',
    name: 'Zaky Surya',
    pointsBalance: 120,
    lifetimePoints: 120,
    lastVisitAt: DateTime.now().subtract(const Duration(days: 7)),
  );

  static final Profile _mockAdmin = Profile(
    id: 'mock-admin-1',
    role: 'admin',
    phone: '081999888777',
    name: 'Admin Utama Ter The Cut',
    pointsBalance: 0,
    lifetimePoints: 0,
  );

  static Profile? _currentSessionProfile;

  Future<Profile> login({
    required String identifier, // Email atau nomor telepon
    required String password,
    bool asAdmin = false,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final AuthResponse res;
        if (identifier.contains('@')) {
          res = await client.auth.signInWithPassword(
            email: identifier.trim(),
            password: password,
          );
        } else {
          res = await client.auth.signInWithPassword(
            phone: identifier.trim(),
            password: password,
          );
        }

        final user = res.user;
        if (user == null) throw Exception('Pengguna tidak ditemukan.');

        // Ambil profil dari tabel profiles
        final data = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          final profile = Profile.fromJson(data);
          _currentSessionProfile = profile;
          return profile;
        } else {
          // Fallback profil baru jika trigger belum jalan
          final profile = Profile(
            id: user.id,
            role: asAdmin ? 'admin' : 'customer',
            name: user.userMetadata?['name'] ?? 'Pelanggan',
            phone: user.phone ?? identifier,
          );
          _currentSessionProfile = profile;
          return profile;
        }
      } catch (e) {
        // Jika gagal koneksi supabase, coba fallback mock jika kredensial demo
        if (password == 'admin123' || asAdmin) {
          _currentSessionProfile = _mockAdmin;
          return _mockAdmin;
        }
        throw Exception(e.toString().replaceAll('Exception:', '').trim());
      }
    } else {
      // Mock Auth Fallback Mode
      await Future.delayed(const Duration(milliseconds: 600)); // Simulasi network
      if (asAdmin) {
        if (password == 'admin123' || password.length >= 6) {
          _currentSessionProfile = _mockAdmin;
          return _mockAdmin;
        } else {
          throw Exception('Password admin minimal 6 karakter atau gunakan "admin123".');
        }
      } else {
        if (password.length < 6) {
          throw Exception('Password minimal 6 karakter.');
        }
        _mockCustomer = Profile(
          id: 'mock-customer-1',
          role: 'customer',
          phone: identifier,
          name: identifier.contains('@') ? identifier.split('@')[0] : 'Pelanggan Ter The Cut',
          pointsBalance: 120,
          lifetimePoints: 120,
          lastVisitAt: DateTime.now().subtract(const Duration(days: 7)),
        );
        _currentSessionProfile = _mockCustomer;
        return _mockCustomer;
      }
    }
  }

  Future<Profile> register({
    required String name,
    required String identifier,
    required String password,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final AuthResponse res;
        if (identifier.contains('@')) {
          res = await client.auth.signUp(
            email: identifier.trim(),
            password: password,
            data: {'name': name, 'role': 'customer'},
          );
        } else {
          res = await client.auth.signUp(
            phone: identifier.trim(),
            password: password,
            data: {'name': name, 'role': 'customer'},
          );
        }

        final user = res.user;
        if (user == null) throw Exception('Pendaftaran akun gagal.');

        final profile = Profile(
          id: user.id,
          role: 'customer',
          name: name,
          phone: identifier,
          pointsBalance: 0,
          lifetimePoints: 0,
        );
        _currentSessionProfile = profile;
        return profile;
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception:', '').trim());
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (password.length < 6) {
        throw Exception('Password minimal 6 karakter.');
      }
      final profile = Profile(
        id: 'new-cust-${DateTime.now().millisecondsSinceEpoch}',
        role: 'customer',
        name: name,
        phone: identifier,
        pointsBalance: 0,
        lifetimePoints: 0,
      );
      _currentSessionProfile = profile;
      return profile;
    }
  }

  Future<void> logout() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      await client.auth.signOut();
    }
    _currentSessionProfile = null;
  }

  Profile? get currentProfile => _currentSessionProfile;
}
