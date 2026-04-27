import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// RUBRIK: Notifications - Service untuk listen real-time perubahan status barang di Firestore
class FirestoreListenerService {
  static final FirestoreListenerService _instance =
      FirestoreListenerService._internal();
  factory FirestoreListenerService() => _instance;
  FirestoreListenerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  /// Mulai listen ke perubahan barang yang dilaporkan oleh user ini
  /// Jika status isAvailable berubah dari true → false, tampilkan notifikasi
  Future<void> startListening(String userId) async {
    // Hentikan listener lama jika ada
    await stopListening();

    try {
      // RUBRIK: Notifications - Query barang yang dilaporkan oleh user ini
      _subscription = _firestore
          .collection('lost_items')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) {
          // Proses perubahan setiap dokumen
          for (var change in snapshot.docChanges) {
            final doc = change.doc;
            final data = doc.data() as Map<String, dynamic>;

            // RUBRIK: Notifications - Cek jika barang berubah status menjadi "diambil"
            if (change.type == DocumentChangeType.modified) {
              final isAvailable = data['isAvailable'] as bool? ?? true;
              final namaBarang = data['namaBarang'] as String? ?? 'Barang Anda';

              // Jika status dari available menjadi tidak available = ada yang ngambil
              if (!isAvailable) {
                _sendNotification(namaBarang, doc.id);
              }
            }
          }
        },
        onError: (e) {
          debugPrint('Error listening to lost_items: $e');
        },
      );

      debugPrint('✓ Firestore listener started untuk userId: $userId');
    } catch (e) {
      debugPrint('Error starting firestore listener: $e');
    }
  }

  /// Kirim notifikasi lokal saat barang diambil
  Future<void> _sendNotification(String namaBarang, String docId) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: docId.hashCode.abs(), // Unique ID berdasarkan doc ID, abs() agar tidak negatif
          channelKey: 'campus_lost_found_channel', // WAJIB sama dengan yang didaftarkan di NotificationService.initialize()
          title: '🎉 Barang Ditemukan!',
          body: '$namaBarang sudah diambil/diklaim.',
          summary: 'Status laporan barang Anda berubah',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          autoDismissible: false,
          payload: {
            'docId': docId,
            'barang': namaBarang,
          },
        ),
      );
      debugPrint('✓ Notifikasi dikirim: $namaBarang');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Hentikan listening
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    debugPrint('✓ Firestore listener stopped');
  }
}
