import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/feedback_item.dart';

/// Layanan Pengelolaan Kritik & Saran (US-14, US-15)
class FeedbackService {
  // Cache in-memory untuk runtime fallback saat luring / offline
  static final List<FeedbackItem> _inMemoryFeedbacks = [];

  /// Mengirim kritik dan saran pelanggan (US-14)
  Future<FeedbackItem> submitFeedback({
    required String userId,
    required String userName,
    required String userPhone,
    required String category,
    required String message,
    int rating = 5,
  }) async {
    final client = SupabaseConfig.client;

    final feedback = FeedbackItem(
      id: 'fb-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      category: category,
      message: message,
      rating: rating,
      createdAt: DateTime.now(),
    );

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('feedbacks').insert(feedback.toJson());
        _inMemoryFeedbacks.insert(0, feedback);
        return feedback;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase feedback insert error, using local fallback: $e');
        }
      }
    }

    _inMemoryFeedbacks.insert(0, feedback);
    return feedback;
  }

  /// Membaca seluruh feedback pelanggan untuk admin secara kronologis terbalik (US-15)
  Future<List<FeedbackItem>> getFeedbacks() async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('feedbacks')
            .select()
            .order('created_at', ascending: false);

        final items = (data as List)
            .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
            .toList();

        return items;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase feedbacks fetch error, using local fallback: $e');
        }
      }
    }

    // Fallback luring
    _inMemoryFeedbacks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(_inMemoryFeedbacks);
  }
}
