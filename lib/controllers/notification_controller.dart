import 'package:get/get.dart';
import '../models/in_app_notification.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

/// Controller Notifikasi In-App Pelanggan (US-21)
class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();

  final RxList<InAppNotification> notifications = <InAppNotification>[].obs;
  final RxBool isLoading = false.obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// Memuat notifikasi untuk user yang sedang aktif
  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController(), permanent: true);

      final userId = auth.currentProfile?.id ?? 'mock-customer-1';
      final list = await _notificationService.getNotifications(userId);
      notifications.assignAll(list);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Menandai satu notifikasi sudah dibaca
  Future<void> markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  /// Menandai seluruh notifikasi telah dibaca
  Future<void> markAllAsRead() async {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final userId = auth.currentProfile?.id ?? 'mock-customer-1';
    await _notificationService.markAllAsRead(userId);

    for (var n in notifications) {
      n.isRead = true;
    }
    notifications.refresh();
  }

  /// Menerbitkan notifikasi in-app otomatis saat event transaksi / reservasi
  Future<void> notify({
    required String title,
    required String message,
    required String type,
  }) async {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final userId = auth.currentProfile?.id ?? 'mock-customer-1';
    final notif = await _notificationService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
    notifications.insert(0, notif);
  }
}
