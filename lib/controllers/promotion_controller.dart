import 'package:flutter/foundation.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import 'auth_controller.dart';

/// Singleton controller Manajemen Promo & Diskon Segmen (US-16, US-17).
class PromotionController extends ChangeNotifier {
  static final PromotionController _instance = PromotionController._internal();
  factory PromotionController() => _instance;
  PromotionController._internal();

  final PromotionService _promotionService = PromotionService();

  List<Promotion> activePromotions = [];
  List<Promotion> allPromotions = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String errorMessage = '';

  /// Memuat promo aktif untuk pelanggan berdasarkan tier keanggotaan.
  Future<void> loadPromotions() async {
    try {
      isLoading = true;
      notifyListeners();

      final userTier = AuthController().currentProfile?.tier;
      final active = await _promotionService.getActivePromotions(userTier: userTier);
      final all = await _promotionService.getAllPromotions();

      activePromotions = active;
      allPromotions = all;
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan promo baru oleh admin (US-17).
  Future<bool> createPromotion({
    required String title,
    required String description,
    required int discountPercent,
    required String targetTier,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      errorMessage = 'Harap isi judul dan deskripsi promo.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = '';
      notifyListeners();

      final promo = await _promotionService.createPromotion(
        title: title.trim(),
        description: description.trim(),
        discountPercent: discountPercent,
        targetTier: targetTier,
        startDate: startDate,
        endDate: endDate,
      );

      allPromotions = [promo, ...allPromotions];
      activePromotions = [promo, ...activePromotions];
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSubmitting = false;
      errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui promo yang sudah ada (US-17 CRUD - Update).
  Future<bool> updatePromotion(Promotion promo) async {
    if (promo.title.trim().isEmpty || promo.description.trim().isEmpty) {
      errorMessage = 'Harap isi judul dan deskripsi promo.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = '';
      notifyListeners();

      await _promotionService.updatePromotion(promo);

      final allIdx = allPromotions.indexWhere((p) => p.id == promo.id);
      if (allIdx != -1) {
        allPromotions[allIdx] = promo;
      }
      final actIdx = activePromotions.indexWhere((p) => p.id == promo.id);
      if (actIdx != -1) {
        if (promo.isValidNow) {
          activePromotions[actIdx] = promo;
        } else {
          activePromotions.removeAt(actIdx);
        }
      } else if (promo.isValidNow) {
        activePromotions = [promo, ...activePromotions];
      }

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSubmitting = false;
      errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Menghapus promo dari sistem (US-17 CRUD - Delete).
  Future<bool> deletePromotion(String promoId) async {
    try {
      errorMessage = '';
      await _promotionService.deletePromotion(promoId);
      allPromotions.removeWhere((p) => p.id == promoId);
      activePromotions.removeWhere((p) => p.id == promoId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }
}
