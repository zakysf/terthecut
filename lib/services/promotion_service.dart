import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/promotion.dart';

/// Layanan Pengelolaan Promo & Segmen (US-16, US-17)
class PromotionService {
  // Cache in-memory untuk runtime fallback saat luring / offline
  static final List<Promotion> _inMemoryPromotions = [];

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

        return list;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promos fetch error, using local fallback: $e');
        }
      }
    }

    return _inMemoryPromotions.where((p) => p.isActive && p.isEligibleForTier(userTier)).toList();
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

        return list;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase all promos error, fallback: $e');
        }
      }
    }

    return List.from(_inMemoryPromotions);
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
        _inMemoryPromotions.insert(0, promo);
        return promo;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase promo insert error, fallback: $e');
        }
      }
    }

    _inMemoryPromotions.insert(0, promo);
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
          print('Supabase promo update error, fallback: $e');
        }
      }
    }

    final index = _inMemoryPromotions.indexWhere((p) => p.id == promo.id);
    if (index != -1) {
      _inMemoryPromotions[index] = promo;
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
          print('Supabase promo delete error, fallback: $e');
        }
      }
    }

    _inMemoryPromotions.removeWhere((p) => p.id == promoId);
    return true;
  }
}
