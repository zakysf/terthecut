import 'package:flutter/foundation.dart';
import '../models/in_app_notification.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

/// Singleton controller Notifikasi In-App Pelanggan (US-21).
class NotificationController extends ChangeNotifier {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  final NotificationService _notificationService = NotificationService();

  List<InAppNotification> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Memuat notifikasi untuk user yang sedang aktif.
  Future<void> loadNotifications() async {
    try {
      isLoading = true;
      notifyListeners();

      final userId = AuthController().currentProfile?.id ?? 'mock-customer-1';
      final list = await _notificationService.getNotifications(userId);
      notifications = list;
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Menandai satu notifikasi sudah dibaca.
  Future<void> markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifyListeners();
    }
  }

  /// Menandai seluruh notifikasi telah dibaca.
  Future<void> markAllAsRead() async {
    final userId = AuthController().currentProfile?.id ?? 'mock-customer-1';
    await _notificationService.markAllAsRead(userId);

    for (final n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  /// Menerbitkan notifikasi in-app otomatis saat event transaksi / reservasi.
  Future<void> notify({
    required String title,
    required String message,
    required String type,
  }) async {
    final userId = AuthController().currentProfile?.id ?? 'mock-customer-1';
    final notif = await _notificationService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
    notifications = [notif, ...notifications];
    notifyListeners();
  }

  void clearSession() {
    notifications = [];
    notifyListeners();
  }
}
