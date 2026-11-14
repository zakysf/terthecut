import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/feedback_item.dart';

/// Layanan Pengelolaan Kritik & Saran (US-14, US-15)
class FeedbackService {
  static final List<FeedbackItem> _mockFeedbacks = [
    FeedbackItem(
      id: 'fb-01',
      userId: 'mock-customer-1',
      userName: 'Bagas Pratama',
      userPhone: '081234567890',
      category: 'Pelayanan',
      message: 'Kapster sangat ramah dan detail dalam memberikan potongan taper fade. Tempatnya bersih dan wangi!',
      rating: 5,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    FeedbackItem(
      id: 'fb-02',
      userId: 'mock-customer-2',
      userName: 'Dimas Setiawan',
      userPhone: '085712345678',
      category: 'Aplikasi',
      message: 'Alur booking sangat praktis. Harap tambahkan opsi pengingat otomatis di kalender HP.',
      rating: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FeedbackItem(
      id: 'fb-03',
      userId: 'mock-customer-3',
      userName: 'Reza Fauzi',
      userPhone: '081399887766',
      category: 'Kebersihan',
      message: 'Area tunggu di cabang Seturan sangat nyaman, musiknya juga asik. Rekomendasi buat cukur santai.',
      rating: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

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
        _mockFeedbacks.insert(0, feedback);
        return feedback;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase feedback insert error, using local fallback: $e');
        }
      }
    }

    _mockFeedbacks.insert(0, feedback);
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

        if (items.isNotEmpty) {
          return items;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Supabase feedbacks fetch error, using local fallback: $e');
        }
      }
    }

    // Urutkan terbaru di atas
    _mockFeedbacks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(_mockFeedbacks);
  }
}
