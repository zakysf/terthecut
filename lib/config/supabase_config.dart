import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String fallbackUrl = 'https://tdbetcjkqeihudihsjlq.supabase.co';
  static const String fallbackAnonKey = 'sb_publishable_1tBjL_d4dLJW7c0twHPzDw_rP6JsjNP';

  static String supabaseUrl = '';
  static String supabaseAnonKey = '';
  static bool isConfigured = false;

  static Future<void> initialize() async {
    // 1. Muat environment variable dari file .env secara aman
    try {
      await dotenv.load(fileName: '.env');
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('Info: File .env tidak terbaca ($e). Menggunakan konfigurasi cloud bawaan.');
      }
    }

    // Gunakan fallback kredensial nyata jika .env tidak tersedia (misal di Web / build)
    if (supabaseUrl.isEmpty || supabaseUrl.contains('YOUR_PROJECT_ID')) {
      supabaseUrl = fallbackUrl;
    }
    if (supabaseAnonKey.isEmpty || supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY')) {
      supabaseAnonKey = fallbackAnonKey;
    }

    // 2. Inisialisasi Supabase resmi sebagai Single Source of Truth
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      isConfigured = true;
      if (kDebugMode) {
        print('Supabase berhasil terhubung: $supabaseUrl');
      }
    } catch (e) {
      isConfigured = false;
      if (kDebugMode) {
        print('Gagal inisialisasi Supabase: $e');
      }
    }
  }

  static SupabaseClient? get client {
    if (isConfigured) {
      return Supabase.instance.client;
    }
    return null;
  }
}
