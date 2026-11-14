import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/promotion.dart';

/// Layanan Pengelolaan Promo & Segmen (US-16, US-17)
class PromotionService {
  static final List<Promotion> _mockPromotions = [
    Promotion(
      id: 'promo-01',
      title: 'Diskon Akhir Pekan 20%',
      description: 'Potongan 20% untuk semua layanan paket Gentlemen Cut & Grooming di seluruh 11 cabang.',
      discountPercent: 20,
      targetTier: 'all',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      isActive: true,
    ),
    Promotion(
      id: 'promo-02',
      title: 'Apresiasi Member Gold 25%',
      description: 'Khusus member Gold: Nikmati diskon istimewa 25% untuk Hair Spa Treatment.',
      discountPercent: 25,
      targetTier: 'gold',
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      isActive: true,
    ),
    Promotion(
      id: 'promo-03',
      title: 'Privilege Platinum 30%',
      description: 'Penawaran eksklusif kasta tertinggi Platinum: Diskon 30% dan bebas antrean reservasi.',
      discountPercent: 30,
      targetTier: 'platinum',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    ),
  ];

  /// Mengambil promo aktif yang sesuai dengan tier pelanggan (US-16)
  Future<List<Promotion>> getActivePromotions({String? userTier}) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('promos')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((item) => Promotion.fromJson(item as Map<String, dynamic>))
            .where((p) => p.isEligibleForTier(userTier))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promos fetch error, using local fallback: $e');
        }
      }
    }

    return _mockPromotions.where((p) => p.isActive && p.isEligibleForTier(userTier)).toList();
  }

  /// Mengambil seluruh promo untuk admin (US-17)
  Future<List<Promotion>> getAllPromotions() async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('promos')
            .select()
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((item) => Promotion.fromJson(item as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase all promos error, fallback to mock: $e');
        }
      }
    }

    return List.from(_mockPromotions);
  }

  /// Membuat promo baru oleh admin (US-17)
  Future<Promotion> createPromotion({
    required String title,
    required String description,
    required int discountPercent,
    required String targetTier,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final promo = Promotion(
      id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      discountPercent: discountPercent,
      targetTier: targetTier,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('promos').insert(promo.toJson());
        _mockPromotions.insert(0, promo);
        return promo;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promo insert error, fallback: $e');
        }
      }
    }

    _mockPromotions.insert(0, promo);
    return promo;
  }

  /// Memperbarui promo yang ada (Update)
  Future<bool> updatePromotion(Promotion promo) async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('promos').update(promo.toJson()).eq('id', promo.id);
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promo update error, fallback to mock: $e');
        }
      }
    }

    final index = _mockPromotions.indexWhere((p) => p.id == promo.id);
    if (index != -1) {
      _mockPromotions[index] = promo;
      return true;
    }
    return true;
  }

  /// Menghapus promo berdasarkan ID (Delete)
  Future<bool> deletePromotion(String promoId) async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('promos').delete().eq('id', promoId);
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promo delete error, fallback to mock: $e');
        }
      }
    }

    _mockPromotions.removeWhere((p) => p.id == promoId);
    return true;
  }
}
