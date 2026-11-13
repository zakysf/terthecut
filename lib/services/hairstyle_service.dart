import '../config/supabase_config.dart';
import '../models/hairstyle.dart';

class HairstyleService {
  // 8 Koleksi Gaya Rambut Populer dengan Gambar Berkualitas Tinggi dari Internet
  static final List<Hairstyle> _seedHairstyles = [
    Hairstyle(
      id: 'hs-1',
      name: 'Classic Side Part',
      description: 'Belah samping klasik rapi dengan gradasi taper bersih. Cocok untuk acara formal maupun kantor.',
      photoUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-2',
      name: 'Textured French Crop',
      description: 'Bagian atas bertekstur acak natural dengan poni tumpul dipadukan high fade di sisi samping.',
      photoUrl: 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-3',
      name: 'Korean Two-Block Perm',
      description: 'Gaya ikal Korea bervolume lembut di bagian atas dengan sisi samping dipotong rapi.',
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-4',
      name: 'Low Fade Pompadour',
      description: 'Jambul mengembang bervolume tinggi dengan gradasi fade rendah yang bersih dan elegan.',
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-5',
      name: 'Modern Buzz Cut',
      description: 'Potongan cepak minimalis seragam yang mempertegas bentuk rahang dan kontur wajah maskulin.',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-6',
      name: 'Modern Drop Fade Mullet',
      description: 'Gaya kontemporer dengan bagian belakang lebih tebal dan sisi pelipis fade tipis berkarakter.',
      photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-7',
      name: 'Comma Hair (Curtain)',
      description: 'Gaya poni melengkung menyerupai tanda koma khas Korea yang santai namun tetap rapi.',
      photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&auto=format&fit=crop&q=80',
    ),
    Hairstyle(
      id: 'hs-8',
      name: 'Curly Taper Fade',
      description: 'Mempertahankan tekstur ikal atau keriting alami di atas kepala dengan transisi taper halus di samping.',
      photoUrl: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=600&auto=format&fit=crop&q=80',
    ),
  ];

  Future<List<Hairstyle>> fetchHairstyles() async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client.from('hairstyles').select();
        final list = (data as List).map((e) => Hairstyle.fromJson(e)).toList();
        // Jika di Supabase tabel hairstyles masih kosong, gunakan koleksi gambar internet
        if (list.isEmpty) {
          return _seedHairstyles;
        }
        return list;
      } catch (e) {
        return _seedHairstyles;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return _seedHairstyles;
  }

  Future<bool> toggleFavorite(String hairstyleId) async {
    final item = _seedHairstyles.firstWhere(
      (element) => element.id == hairstyleId,
      orElse: () => Hairstyle(id: hairstyleId, name: ''),
    );
    item.isFavorite = !item.isFavorite;
    return item.isFavorite;
  }
}
