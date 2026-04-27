import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/item_provider.dart';
import '../models/item_model.dart';
import '../services/firestore_listener_service.dart';
import 'auth_screen.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

// RUBRIK: CRUD SQLite + Firebase Firestore - Layar utama daftar draft & sinkronisasi
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Draft Lokal, 1: Laporan Saya, 2: Daftar Publik
  final FirestoreListenerService _listenerService = FirestoreListenerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadDrafts();
      // RUBRIK: Relational Database - Muat data kategori dari tabel categories
      context.read<ItemProvider>().loadCategories();

      // RUBRIK: Notifications - Mulai listen perubahan status barang user ini di Firestore
      final authProvider = context.read<app_auth.AuthProvider>();
      final userId = authProvider.currentUser?.uid;
      if (userId != null) {
        _listenerService.startListening(userId);
      }
    });
  }

  @override
  void dispose() {
    // RUBRIK: Notifications - Stop listening saat screen ditutup
    _listenerService.stopListening();
    super.dispose();
  }

  // RUBRIK: Firebase Auth - Logout dari AppBar
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Yakin ingin keluar? Draft lokal Anda tidak akan terhapus.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<app_auth.AuthProvider>().logout();
        navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()));
      } catch (e) {
        messenger.showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFE53935)));
      }
    }
  }

  // RUBRIK: Firebase Firestore - Sinkronisasi data ke Firestore
  Future<void> _syncToFirebase() async {
    final itemProvider = context.read<ItemProvider>();

    if (itemProvider.draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Tidak ada draft untuk disinkronisasi.'),
          ]),
          backgroundColor: Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await itemProvider.syncToFirebase();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Sinkronisasi berhasil! Cek tab "Laporan Saya".'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Tab 1 = Laporan Saya (laporan user yang sudah tersinkronisasi)
        setState(() => _currentIndex = 1);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: _buildAppBar(),
      body: _currentIndex == 0
          ? Consumer<ItemProvider>(
              builder: (context, itemProvider, _) {
                if (itemProvider.isLoading) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2196F3)));
                }
                if (itemProvider.draftItems.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildDraftList(itemProvider);
              },
            )
          : _currentIndex == 1
              ? _buildMyReportsFeed()
              : _buildPublicFeed(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B2A4A),
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined),
            activeIcon: Icon(Icons.note_alt),
            label: 'Draft Lokal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Laporan Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Daftar Publik',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'add_item_btn',
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const AddItemScreen()))
                        .then((_) {
                      if (context.mounted) {
                        context.read<ItemProvider>().loadDrafts();
                      }
                    });
                  },
                  backgroundColor: const Color(0xFF152238),
                  elevation: 8,
                  mini: true,
                  child:
                      const Icon(Icons.add_rounded, color: Color(0xFF2196F3)),
                ),
                const SizedBox(height: 16),
                _buildSyncFAB(),
              ],
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D1B2A),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lost & Found Kampus',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentIndex == 0
                ? 'Draft Laporan Lokal'
                : _currentIndex == 1
                    ? 'Laporan Yang Saya Buat'
                    : 'Laporan Global',
            style: const TextStyle(color: Color(0xFF2196F3), fontSize: 12),
          ),
        ],
      ),
      actions: [
        Consumer<app_auth.AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.currentUser;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _logout,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1B2A4A),
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.logout_rounded,
                        color: Colors.white54, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2A4A),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  width: 2),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 56, color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Laporan Draft',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk tombol + untuk melaporkan barang\nyang hilang atau Anda temukan.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftList(ItemProvider itemProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.storage_rounded,
                  color: Colors.white.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 8),
              Text(
                '${itemProvider.draftItems.length} laporan menunggu sinkronisasi',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
              const Spacer(),
              const Text(
                'Offline Mode',
                style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: itemProvider.draftItems.length,
            itemBuilder: (context, index) {
              final item = itemProvider.draftItems[index];
              return _buildDraftCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(Item item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B2A4A),
            const Color(0xFF1B2A4A).withValues(alpha: 0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                  itemData: item.toFirestoreMap(), isDraft: true),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.fotoPath.isNotEmpty
              ? Image.file(
                  File(item.fotoPath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
                )
              : _photoPlaceholder(),
        ),
        title: Text(
          item.namaBarang,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.deskripsi,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // RUBRIK: Relational Database - Badge kategori dari JOIN query
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 13, color: Color(0xFF9C27B0)),
                const SizedBox(width: 4),
                Text(
                  item.categoryName,
                  style: const TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 13, color: Color(0xFF21CBF3)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.lokasi,
                    style:
                        const TextStyle(color: Color(0xFF21CBF3), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.4)),
              ),
              child: const Text('Draft',
                  style: TextStyle(
                      color: Color(0xFFFFA000),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            // RUBRIK: CRUD SQLite UPDATE - Tombol Edit draft
            InkWell(
              onTap: () {
                final itemProvider = context.read<ItemProvider>();
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => AddItemScreen(editItem: item)))
                    .then((_) {
                  if (!context.mounted) return;
                  itemProvider.loadDrafts();
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 11, color: Color(0xFF2196F3)),
                    SizedBox(width: 3),
                    Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF152238),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF2196F3), size: 28),
    );
  }

  Widget _buildSyncFAB() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, _) {
        return FloatingActionButton.extended(
          onPressed: itemProvider.isSyncing ? null : _syncToFirebase,
          backgroundColor: itemProvider.isSyncing
              ? const Color(0xFF1565C0)
              : const Color(0xFF2196F3),
          elevation: 8,
          icon: itemProvider.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
          label: Text(
            itemProvider.isSyncing ? 'Menyinkronkan...' : 'Sinkronisasi',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  // ── LAPORAN SAYA (MY REPORTS - filter by current user) ─────────────

  Widget _buildMyReportsFeed() {
    final currentUser = context.read<app_auth.AuthProvider>().currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Tidak ada sesi login.', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('Gagal memuat laporan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A4A),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.2), width: 2),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined,
                      size: 48, color: Color(0xFF2196F3)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Laporan Tersinkronisasi',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat laporan di tab Draft, lalu tekan\ntombol Sinkronisasi untuk mengunggah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.6),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_outlined,
                      color: Colors.white.withValues(alpha: 0.5), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${docs.length} laporan Anda di server',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  return _buildPublicCard(context, data, docId);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── DAFTAR PUBLIK (GLOBAL FEED) ──────────────────────────────────

  Widget _buildPublicFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .orderBy('dilaporkanPada', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat data publik.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public_off,
                    size: 52, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'Belum ada laporan dari siapapun',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildPublicCard(context, data, docId);
          },
        );
      },
    );
  }

  Widget _buildPublicCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
    final deskripsi = data['deskripsi'] ?? '';
    final lokasi = data['lokasi'] ?? 'Lokasi tidak diketahui';
    final kategori = data['kategori'] ?? '';
    final bool isAvailable = data['isAvailable'] ?? true;

    final currentUser = context.read<app_auth.AuthProvider>().currentUser;
    final bool isOwner = currentUser?.uid == data['userId'];
    final bool isAdmin = currentUser?.email == 'admin@gmail.com';
    final bool canEdit = isOwner || isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF1B2A4A)
            : const Color(0xFF1B2A4A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ItemDetailScreen(itemData: data, isDraft: false),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
              opacity: isAvailable ? 1.0 : 0.3, child: _photoPlaceholder()),
        ),
        title: Text(
          namaBarang,
          style: TextStyle(
            color: isAvailable ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            decoration: isAvailable ? null : TextDecoration.lineThrough,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              deskripsi,
              style: TextStyle(
                  color: isAvailable
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white30,
                  fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (kategori.isNotEmpty)
              Row(children: [
                const Icon(Icons.category_outlined,
                    size: 13, color: Color(0xFF9C27B0)),
                const SizedBox(width: 4),
                Text(kategori,
                    style: const TextStyle(
                        color: Color(0xFF9C27B0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            if (kategori.isNotEmpty) const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.map_outlined,
                    size: 13,
                    color:
                        isAvailable ? const Color(0xFF21CBF3) : Colors.white30),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lokasi,
                    style: TextStyle(
                        color: isAvailable
                            ? const Color(0xFF21CBF3)
                            : Colors.white30,
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isAvailable && canEdit) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1B2A4A),
                      title: const Text('Konfirmasi',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Apakah benar barang ini sudah diserahkan kepada pemiliknya?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal',
                              style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50)),
                          child: const Text('Ya, Sudah Diambil',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  if (!context.mounted) return;

                  try {
                    await context.read<ItemProvider>().markItemAsTaken(docId);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: const Color(0xFFE53935)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  elevation: 0,
                  side: BorderSide(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF4CAF50), size: 16),
                label: const Text('Tandai Sudah Diambil',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isAvailable
                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isAvailable
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                    : Colors.white30),
          ),
          child: Text(
            isAvailable ? 'Online' : 'SUDAH DIAMBIL',
            style: TextStyle(
              color: isAvailable ? const Color(0xFF4CAF50) : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
