import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

// RUBRIK: Notifications - Service untuk mengelola notifikasi menggunakan awesome_notifications
class NotificationService {
  static const String _channelKey = 'campus_lost_found_channel';
  static const String _channelName = 'Lost & Found Sinkronisasi';
  static const String _channelDescription =
      'Notifikasi untuk sinkronisasi data barang hilang/ditemukan';

  /// Inisialisasi awesome_notifications - dipanggil di main.dart
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // null = gunakan icon default aplikasi
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );
  }

  /// Meminta izin notifikasi dari pengguna
  static Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  // RUBRIK: Notifications - Notifikasi "Sinkronisasi Berhasil"
  /// Menampilkan notifikasi sukses setelah data berhasil disinkronisasi ke server
  static Future<void> showSyncSuccessNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: _channelKey,
          title: '✅ Sinkronisasi Berhasil!',
          body:
              'Draft laporan Anda telah dibagikan ke server kampus. Data Anda kini tersedia secara online.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          autoDismissible: true,
        ),
      );
    } catch (e) {
      // Gagal mengirim notifikasi tidak boleh mengganggu alur utama aplikasi
      debugPrint('Peringatan: Gagal menampilkan notifikasi: $e');
    }
  }

  /// Menampilkan notifikasi error saat sinkronisasi gagal
  static Future<void> showSyncErrorNotification(String errorMessage) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: _channelKey,
          title: '❌ Sinkronisasi Gagal',
          body: 'Terjadi kesalahan: $errorMessage. Coba lagi saat koneksi tersedia.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Error,
        ),
      );
    } catch (e) {
      debugPrint('Peringatan: Gagal menampilkan notifikasi error: $e');
    }
  }
}
