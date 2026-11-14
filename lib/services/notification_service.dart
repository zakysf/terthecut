import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/in_app_notification.dart';

/// Layanan Notifikasi In-App Pelanggan (US-21)
class NotificationService {
  static final List<InAppNotification> _mockNotifications = [
    InAppNotification(
      id: 'notif-01',
      userId: 'mock-customer-1',
      title: 'Selamat Bergabung di Ter The Cut!',
      message: 'Akun membership Anda telah aktif. Kumpulkan poin di setiap kunjungan potong rambut untuk ditukar dengan reward eksklusif.',
      type: 'general',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    InAppNotification(
      id: 'notif-02',
      userId: 'mock-customer-1',
      title: 'Reservasi Jadwal Berhasil',
      message: 'Reservasi Anda di Cabang Seturan telah terkonfirmasi. Tunjukkan kode reservasi kepada kasir saat tiba.',
      type: 'booking',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    InAppNotification(
      id: 'notif-03',
      userId: 'mock-customer-1',
      title: '+10 Poin Loyalitas Diterima',
      message: 'Transaksi cukur rambut Anda telah selesai. Saldo poin Anda otomatis bertambah +10 poin.',
      type: 'points',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
  ];

  /// Mengambil daftar notifikasi untuk user tertentu
  Future<List<InAppNotification>> getNotifications(String userId) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((item) => InAppNotification.fromJson(item as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase notifications fetch error: $e');
        }
      }
    }

    // Fallback: ambil mock yang sesuai atau umum
    final userNotifs = _mockNotifications.where((n) => n.userId == userId || n.userId == 'mock-customer-1').toList();
    userNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(userNotifs);
  }

  /// Menandai satu notifikasi sudah dibaca
  Future<void> markAsRead(String id) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('id', id);
      } catch (_) {}
    }

    final found = _mockNotifications.firstWhere((n) => n.id == id, orElse: () => _mockNotifications.first);
    found.isRead = true;
  }

  /// Menandai seluruh notifikasi user sebagai terbaca
  Future<void> markAllAsRead(String userId) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
      } catch (_) {}
    }

    for (var n in _mockNotifications) {
      if (n.userId == userId || n.userId == 'mock-customer-1') {
        n.isRead = true;
      }
    }
  }

  /// Membuat notifikasi in-app baru saat terjadi event di aplikasi
  Future<InAppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final notif = InAppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('notifications').insert(notif.toJson());
      } catch (_) {}
    }

    _mockNotifications.insert(0, notif);
    return notif;
  }
}
