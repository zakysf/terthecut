import 'package:get/get.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import 'auth_controller.dart';

/// Controller Manajemen Promo & Diskon Segmen (US-16, US-17)
class PromotionController extends GetxController {
  final PromotionService _promotionService = PromotionService();

  final RxList<Promotion> activePromotions = <Promotion>[].obs;
  final RxList<Promotion> allPromotions = <Promotion>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromotions();
  }

  /// Memuat promo aktif untuk pelanggan berdasarkan tier keanggotaan
  Future<void> loadPromotions() async {
    try {
      isLoading.value = true;
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController(), permanent: true);

      final userTier = auth.currentProfile?.tier;

      final active = await _promotionService.getActivePromotions(userTier: userTier);
      final all = await _promotionService.getAllPromotions();

      activePromotions.assignAll(active);
      allPromotions.assignAll(all);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Menambahkan promo baru oleh admin (US-17)
  Future<bool> createPromotion({
    required String title,
    required String description,
    required int discountPercent,
    required String targetTier,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Harap isi judul dan deskripsi promo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSubmitting.value = true;
      final promo = await _promotionService.createPromotion(
        title: title.trim(),
        description: description.trim(),
        discountPercent: discountPercent,
        targetTier: targetTier,
        startDate: startDate,
        endDate: endDate,
      );

      allPromotions.insert(0, promo);
      activePromotions.insert(0, promo);
      isSubmitting.value = false;

      Get.snackbar(
        'Promo Diterbitkan',
        'Promo "$title" berhasil dibuat untuk segmen $targetTier.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      isSubmitting.value = false;
      Get.snackbar(
        'Gagal Membuat Promo',
        e.toString().replaceAll('Exception:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Memperbarui promo yang sudah ada (US-17 CRUD - Update)
  Future<bool> updatePromotion(Promotion promo) async {
    if (promo.title.trim().isEmpty || promo.description.trim().isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Harap isi judul dan deskripsi promo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSubmitting.value = true;
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
        activePromotions.insert(0, promo);
      }

      isSubmitting.value = false;
      Get.snackbar(
        'Promo Diperbarui',
        'Promo "${promo.title}" berhasil diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      isSubmitting.value = false;
      Get.snackbar(
        'Gagal Memperbarui Promo',
        e.toString().replaceAll('Exception:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Menghapus promo dari sistem (US-17 CRUD - Delete)
  Future<bool> deletePromotion(String promoId) async {
    try {
      await _promotionService.deletePromotion(promoId);
      allPromotions.removeWhere((p) => p.id == promoId);
      activePromotions.removeWhere((p) => p.id == promoId);

      Get.snackbar(
        'Promo Dihapus',
        'Promo berhasil dihapus dari sistem.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Menghapus Promo',
        e.toString().replaceAll('Exception:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
