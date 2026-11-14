import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';
import '../models/feedback_item.dart';
import '../services/feedback_service.dart';
import 'auth_controller.dart';

/// Controller Manajemen Kritik & Saran Pelanggan & Admin (US-14, US-15)
class FeedbackController extends GetxController {
  final FeedbackService _feedbackService = FeedbackService();

  final RxList<FeedbackItem> feedbacks = <FeedbackItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxString selectedCategory = 'Pelayanan'.obs;
  final RxInt selectedRating = 5.obs;

  final List<String> categories = const [
    'Pelayanan',
    'Kebersihan',
    'Kapster',
    'Aplikasi',
    'Lainnya',
  ];

  @override
  void onInit() {
    super.onInit();
    loadFeedbacks();
  }

  /// Memuat riwayat kritik & saran untuk admin
  Future<void> loadFeedbacks() async {
    try {
      isLoading.value = true;
      final list = await _feedbackService.getFeedbacks();
      feedbacks.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengirim kritik & saran dari sisi pelanggan (US-14)
  Future<bool> submitFeedback({required String message}) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Harap tuliskan masukan atau saran Anda terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.paper,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.paper),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    try {
      isSubmitting.value = true;

      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController(), permanent: true);

      final profile = auth.currentProfile;
      final userId = profile?.id ?? 'guest';
      final userName = profile?.name ?? 'Pelanggan';
      final userPhone = profile?.phone ?? '-';

      final item = await _feedbackService.submitFeedback(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        category: selectedCategory.value,
        message: cleanMessage,
        rating: selectedRating.value,
      );

      feedbacks.insert(0, item);
      isSubmitting.value = false;
      return true;
    } catch (e) {
      isSubmitting.value = false;
      final errorMsg = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Gagal Mengirim',
        errorMsg.isNotEmpty
            ? errorMsg
            : 'Terjadi kendala teknis saat mengirim saran. Silakan coba kembali.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.paper,
        icon: const Icon(Icons.error_outline, color: AppColors.paper),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }
}
