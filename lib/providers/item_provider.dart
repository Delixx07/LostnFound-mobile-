import 'package:flutter/foundation.dart' hide Category;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';
import '../services/sqlite_service.dart';
import '../services/notification_service.dart';

// RUBRIK: CRUD SQLite + Firebase Firestore - Provider untuk manajemen item laporan
class ItemProvider extends ChangeNotifier {
  final SqliteService _sqliteService = SqliteService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Item> _draftItems = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  List<Item> get draftItems => List.unmodifiable(_draftItems);
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // RUBRIK: CRUD SQLite - READ (load dari SQLite menggunakan JOIN)
  Future<void> loadDrafts() async {
    _setLoading(true);
    _clearError();
    try {
      _draftItems = await _sqliteService.getUnsyncedItems();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat data draft: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // RUBRIK: Relational Database - READ categories
  Future<void> loadCategories() async {
    try {
      _categories = await _sqliteService.getAllCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat kategori: $e');
    }
  }

  // RUBRIK: CRUD SQLite - INSERT (simpan draft baru)
  Future<void> addItemToDraft(Item item) async {
    _setLoading(true);
    _clearError();
    try {
      await _sqliteService.insertItem(item);
      await loadDrafts();
    } catch (e) {
      _errorMessage = 'Gagal menyimpan draft: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // RUBRIK: CRUD SQLite - UPDATE (edit draft yang sudah ada)
  Future<void> updateDraft(Item item) async {
    _setLoading(true);
    _clearError();
    try {
      await _sqliteService.updateItem(item);
      await loadDrafts();
    } catch (e) {
      _errorMessage = 'Gagal memperbarui draft: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // RUBRIK: Firebase Firestore - Sinkronisasi draft ke Firestore
  /// Mensinkronisasi semua draft ke Firebase Firestore
  /// Setelah sukses upload setiap item, hapus dari SQLite dan list lokal
  /// Jika semua selesai tanpa error, tampilkan notifikasi sukses
  Future<void> syncToFirebase() async {
    if (_draftItems.isEmpty) {
      throw 'Tidak ada draft untuk disinkronisasi.';
    }

    _setSyncing(true);
    _clearError();

    // Buat salinan list untuk iterasi (agar aman saat modifikasi)
    final List<Item> itemsToSync = List.from(_draftItems);
    int syncedCount = 0;
    List<String> errorMessages = [];

    for (final item in itemsToSync) {
      try {
        // RUBRIK: Firebase Firestore - Upload ke collection 'lost_items' tanpa Storage
        await _firestore
            .collection('lost_items')
            .add(item.toFirestoreMap());

        // RUBRIK: CRUD SQLite - DELETE setelah berhasil upload
        if (item.id != null) {
          await _sqliteService.deleteItem(item.id!);
          // Hapus dari list lokal
          _draftItems.removeWhere((d) => d.id == item.id);
        }

        syncedCount++;
        notifyListeners();
      } catch (e) {
        // Jika satu item gagal, lanjutkan ke item berikutnya
        errorMessages.add('• ${item.namaBarang}: ${e.toString()}');
        debugPrint('Gagal sync item ${item.id}: $e');
      }
    }

    _setSyncing(false);

    // RUBRIK: Notifications - Tampilkan notifikasi jika semua berhasil
    if (errorMessages.isEmpty && syncedCount > 0) {
      await NotificationService.showSyncSuccessNotification();
    } else if (errorMessages.isNotEmpty) {
      // Jika ada yang gagal, lempar exception agar UI bisa menampilkan error
      final failureInfo = errorMessages.join('\n');
      throw 'Beberapa item gagal disinkronisasi:\n$failureInfo';
    }
  }

  // RUBRIK: Update Firestore Status
  /// Menandai dokumen barang di Firestore bahwa sudah selesai/diambil
  Future<void> markItemAsTaken(String firestoreDocId) async {
    try {
      await _firestore
          .collection('lost_items')
          .doc(firestoreDocId)
          .update({'isAvailable': false});
    } catch (e) {
      throw 'Gagal memperbarui status laporan: $e';
    }
  }
}
