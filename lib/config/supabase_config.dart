import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
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
        print('Info: File .env tidak ditemukan atau belum diisi ($e).');
      }
    }

    // 2. Periksa apakah kredensial valid dan bukan placeholder
    final bool hasValidCredentials = supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('YOUR_PROJECT_ID') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');

    if (hasValidCredentials) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
        );
        isConfigured = true;
        if (kDebugMode) {
          print('Supabase berhasil terhubung via .env.');
        }
      } catch (e) {
        isConfigured = false;
        if (kDebugMode) {
          print('Gagal inisialisasi Supabase, beralih ke local mock data: $e');
        }
      }
    } else {
      isConfigured = false;
      if (kDebugMode) {
        print('Kredensial Supabase di .env belum diisi nyata.');
        print('Aplikasi berjalan otomatis dalam mode Demo / Mock Data.');
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
