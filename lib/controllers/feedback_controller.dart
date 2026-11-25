import 'package:flutter/foundation.dart';
import '../models/feedback_item.dart';
import '../services/feedback_service.dart';
import 'auth_controller.dart';

/// Singleton controller Manajemen Kritik & Saran Pelanggan & Admin (US-14, US-15).
class FeedbackController extends ChangeNotifier {
  static final FeedbackController _instance = FeedbackController._internal();
  factory FeedbackController() => _instance;
  FeedbackController._internal();

  final FeedbackService _feedbackService = FeedbackService();

  List<FeedbackItem> feedbacks = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String errorMessage = '';

  String selectedCategory = 'Pelayanan';
  int selectedRating = 5;

  final List<String> categories = const [
    'Pelayanan',
    'Kebersihan',
    'Kapster',
    'Aplikasi',
    'Lainnya',
  ];

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setRating(int rating) {
    selectedRating = rating;
    notifyListeners();
  }

  /// Memuat riwayat kritik & saran untuk admin.
  Future<void> loadFeedbacks() async {
    try {
      isLoading = true;
      notifyListeners();

      final list = await _feedbackService.getFeedbacks();
      feedbacks = list;
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Mengirim kritik & saran dari sisi pelanggan (US-14).
  Future<bool> submitFeedback({required String message}) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      errorMessage = 'Harap tuliskan masukan atau saran Anda terlebih dahulu.';
      notifyListeners();
      return false;
    }

    try {
      isSubmitting = true;
      errorMessage = '';
      notifyListeners();

      final profile = AuthController().currentProfile;
      final userId = profile?.id ?? 'guest';
      final userName = profile?.name ?? 'Pelanggan';
      final userPhone = profile?.phone ?? '-';

      final item = await _feedbackService.submitFeedback(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        category: selectedCategory,
        message: cleanMessage,
        rating: selectedRating,
      );

      feedbacks = [item, ...feedbacks];
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSubmitting = false;
      final rawMsg = e.toString().replaceAll('Exception:', '').trim();
      errorMessage = rawMsg.isNotEmpty
          ? rawMsg
          : 'Terjadi kendala teknis saat mengirim saran. Silakan coba kembali.';
      notifyListeners();
      return false;
    }
  }
}
