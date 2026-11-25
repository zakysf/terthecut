import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../config/supabase_config.dart';
import '../models/in_app_notification.dart';

/// Layanan Notifikasi Perangkat (Local Notification sesuai Modul 7) dan Riwayat In-App (US-21).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'terthecut_channel';
  static const String _channelName = 'Ter The Cut Notifikasi';
  static const String _channelDescription =
      'Pemberitahuan status reservasi, pengingat jadwal, dan poin loyalitas.';

  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isPluginInitialized = false;
  int _nextNotificationId = 100;

  static final List<InAppNotification> _inMemoryNotifications = [];

  /// Inisialisasi Local Notification & timezone perangkat (Modul 7).
  Future<void> init() async {
    if (_isPluginInitialized || kIsWeb) return;

    try {
      // 1. Inisialisasi timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      // 2. Konfigurasi Android & iOS/Darwin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      await notificationPlugin.initialize(initSettings);

      // 3. Request permission & buat Notification Channel (Android 8+)
      final androidPlatform = notificationPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlatform?.requestNotificationsPermission();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await androidPlatform?.createNotificationChannel(channel);

      _isPluginInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Inisialisasi local notification dilewati: $e');
      }
    }
  }

  NotificationDetails _buildNotificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  /// Immediate notification: muncul langsung di bar status/banner perangkat saat dipanggil.
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_isPluginInitialized) return;
    try {
      await notificationPlugin.show(
        _nextNotificationId++,
        title,
        body,
        _buildNotificationDetails(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menampilkan notifikasi perangkat: $e');
      }
    }
  }

  /// Scheduled notification: muncul otomatis di waktu yang ditentukan (Modul 7).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isPluginInitialized) return;
    if (!scheduledTime.isAfter(DateTime.now())) return;

    try {
      await notificationPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime(
          tz.local,
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day,
          scheduledTime.hour,
          scheduledTime.minute,
          scheduledTime.second,
        ),
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menjadwalkan notifikasi perangkat: $e');
      }
    }
  }

  /// Membatalkan notifikasi terjadwal (misalnya ketika booking dibatalkan admin).
  Future<void> cancelScheduledNotification(int id) async {
    if (!_isPluginInitialized) return;
    try {
      await notificationPlugin.cancel(id);
    } catch (_) {}
  }

  /// Mengambil daftar notifikasi untuk user tertentu.
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

    // Fallback: ambil data in-memory untuk user yang bersangkutan
    final userNotifs = _inMemoryNotifications
        .where((n) => n.userId == userId)
        .toList();
    userNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(userNotifs);
  }

  /// Menandai satu notifikasi sudah dibaca.
  Future<void> markAsRead(String id) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('id', id);
      } catch (_) {}
    }

    final index = _inMemoryNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _inMemoryNotifications[index].isRead = true;
    }
  }

  /// Menandai seluruh notifikasi user sebagai terbaca.
  Future<void> markAllAsRead(String userId) async {
    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
      } catch (_) {}
    }

    for (final n in _inMemoryNotifications) {
      if (n.userId == userId) {
        n.isRead = true;
      }
    }
  }

  /// Membuat notifikasi in-app sekaligus menampilkan notifikasi asli pada perangkat mobile.
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

    _inMemoryNotifications.insert(0, notif);
    await showInstantNotification(title: title, body: message);
    return notif;
  }
}
