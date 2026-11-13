import '../config/supabase_config.dart';
import '../models/hairstyle.dart';

class HairstyleService {
  static final List<Hairstyle> _seedHairstyles = [
    Hairstyle(
      id: 'hs-1',
      name: 'Classic Side Part',
      description: 'Potongan belah samping klasik dengan gradasi taper rapi dan kesan profesional.',
      photoUrl: 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=600',
    ),
    Hairstyle(
      id: 'hs-2',
      name: 'Modern Textured Crop',
      description: 'Bagian atas bertekstur acak alami dengan fade tipis di sisi samping.',
      photoUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600',
    ),
    Hairstyle(
      id: 'hs-3',
      name: 'Korean Wavy Perm',
      description: 'Gelombang rambut ikal lembut gaya Korea dengan volume natural di bagian poni.',
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600',
    ),
    Hairstyle(
      id: 'hs-4',
      name: 'Low Fade Quiff',
      description: 'Jambul depan bervolume dipadukan dengan fade rendah yang bersih dan tegas.',
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
    ),
    Hairstyle(
      id: 'hs-5',
      name: 'Buzz Cut Minimalist',
      description: 'Potongan sangat pendek seragam yang menonjolkan struktur rahang dan kepala.',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
    ),
    Hairstyle(
      id: 'hs-6',
      name: 'Mullet Modern Drop Fade',
      description: 'Gaya edgy dengan bagian belakang lebih panjang dan sisi samping fade tipis.',
      photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600',
    ),
  ];

  Future<List<Hairstyle>> fetchHairstyles() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client.from('hairstyles').select();
        return (data as List).map((e) => Hairstyle.fromJson(e)).toList();
      } catch (e) {
        return _seedHairstyles;
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _seedHairstyles;
  }

  Future<bool> toggleFavorite(String hairstyleId) async {
    // Simulasi atau update ke customer_hairstyles
    final item = _seedHairstyles.firstWhere((element) => element.id == hairstyleId);
    item.isFavorite = !item.isFavorite;
    return item.isFavorite;
  }
}

