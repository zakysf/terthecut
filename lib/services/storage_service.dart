import 'dart:typed_data';
import '../config/supabase_config.dart';

class StorageService {
  // Nama bucket utama di Supabase Storage
  static const String bucketName = 'images';

  // Subfolder di dalam bucket 'images'
  static const String folderBranches = 'branches';
  static const String folderBarbers = 'barbers';
  static const String folderServices = 'services';
  static const String folderHairstyles = 'hairstyles';
  static const String folderPromos = 'promos';
  static const String folderRewards = 'rewards';

  /// Mendapatkan URL publik foto dari Supabase Storage
  static String getPublicUrl({
    required String folder,
    required String fileName,
  }) {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      final path = '$folder/$fileName';
      return client.storage.from(bucketName).getPublicUrl(path);
    }
    // Fallback URL jika belum terhubung
    return 'https://via.placeholder.com/600x400.png?text=$fileName';
  }

  /// Mengunggah file foto ke bucket Supabase (untuk admin)
  static Future<String?> uploadImage({
    required String folder,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final client = SupabaseConfig.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      throw Exception('Supabase belum terhubung.');
    }

    try {
      final path = '$folder/$fileName';
      await client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
          );
      return client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      throw Exception('Gagal mengunggah foto ke storage: $e');
    }
  }
}

