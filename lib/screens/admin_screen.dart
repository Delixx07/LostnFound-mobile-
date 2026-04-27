import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'auth_screen.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';

// RUBRIK: Firebase Auth - Layar khusus admin (email: admin@gmail.com)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0; // 0: Semua Laporan, 1: Perlu Ditangani

  // ── LOGOUT ────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Admin Panel',
            style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin keluar?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<app_auth.AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  // ── HAPUS LAPORAN ─────────────────────────────────────────────────
  Future<void> _deleteItem(String docId, String namaBarang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Laporan',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus laporan "$namaBarang" secara permanen?',
          style: const TextStyle(color: Colors.white70),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('lost_items')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan "$namaBarang" berhasil dihapus.'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── TANDAI SUDAH DIAMBIL ──────────────────────────────────────────
  Future<void> _markAsTaken(String docId, String namaBarang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tandai "$namaBarang" sudah diserahkan ke pemiliknya?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Ya, Sudah Diambil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseFirestore.instance
          .collection('lost_items')
          .doc(docId)
          .update({'isAvailable': false});
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: _currentIndex == 0
                ? _buildAllReportsFeed()
                : _buildPendingFeed(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_add_item_btn',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        backgroundColor: const Color(0xFFFF6D00),
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1B2A4A),
        selectedItemColor: const Color(0xFFFF6D00),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Semua Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            activeIcon: Icon(Icons.pending_actions),
            label: 'Perlu Ditangani',
          ),
        ],
      ),
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
            '🛡️ Admin Panel',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentIndex == 0 ? 'Semua Laporan Masuk' : 'Laporan Belum Selesai',
            style: const TextStyle(color: Color(0xFFFF6D00), fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          onPressed: _logout,
          tooltip: 'Keluar',
        ),
      ],
    );
  }

  // ── STATS BAR ─────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final available = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['isAvailable'] == true;
        }).length;
        final taken = total - available;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2A4A), Color(0xFF152238)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total', total.toString(), Icons.inventory_2_outlined, Colors.blue),
              _divider(),
              _statItem('Menunggu', available.toString(), Icons.hourglass_top_rounded, Colors.orange),
              _divider(),
              _statItem('Selesai', taken.toString(), Icons.check_circle_outline, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(
      height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1));

  // ── SEMUA LAPORAN ─────────────────────────────────────────────────
  Widget _buildAllReportsFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .orderBy('dilaporkanPada', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmpty('Belum ada laporan masuk', Icons.inbox_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildAdminCard(data, docs[index].id);
          },
        );
      },
    );
  }

  // ── PERLU DITANGANI ───────────────────────────────────────────────
  Widget _buildPendingFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .where('isAvailable', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6D00)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmpty('Semua laporan sudah ditangani!', Icons.task_alt);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildAdminCard(data, docs[index].id);
          },
        );
      },
    );
  }

  // ── ADMIN CARD ────────────────────────────────────────────────────
  Widget _buildAdminCard(Map<String, dynamic> data, String docId) {
    final namaBarang = data['namaBarang'] ?? 'Tanpa Nama';
    final deskripsi = data['deskripsi'] ?? '';
    final lokasi = data['lokasi'] ?? '-';
    final kategori = data['kategori'] ?? '';
    final userId = data['userId'] ?? '';
    final bool isAvailable = data['isAvailable'] ?? true;

    String displayTime = '';
    final timeRaw = data['dilaporkanPada'] ?? '';
    if (timeRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(timeRaw).toLocal();
        displayTime =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        displayTime = timeRaw;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF1B2A4A)
            : const Color(0xFF1B2A4A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFFFF6D00).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemData: data, isDraft: false),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFFF6D00).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAvailable ? Icons.search_rounded : Icons.check_circle_rounded,
                color: isAvailable ? const Color(0xFFFF6D00) : Colors.green,
                size: 26,
              ),
            ),
            title: Text(
              namaBarang,
              style: TextStyle(
                color: isAvailable ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                decoration: isAvailable ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(deskripsi,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (kategori.isNotEmpty)
                      _chip(Icons.category_outlined, kategori, const Color(0xFF9C27B0)),
                    _chip(Icons.map_outlined, lokasi, const Color(0xFF21CBF3)),
                    if (displayTime.isNotEmpty)
                      _chip(Icons.access_time, displayTime, Colors.white38),
                  ],
                ),
                const SizedBox(height: 4),
                // User ID info untuk admin
                Text(
                  'UID: ${userId.length > 16 ? '${userId.substring(0, 16)}…' : userId}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFFF6D00).withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFFF6D00).withValues(alpha: 0.5)
                        : Colors.green.withValues(alpha: 0.5)),
              ),
              child: Text(
                isAvailable ? 'AKTIF' : 'SELESAI',
                style: TextStyle(
                  color: isAvailable ? const Color(0xFFFF6D00) : Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Action buttons for admin
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                if (isAvailable)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsTaken(docId, namaBarang),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Tandai Selesai', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                if (isAvailable) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteItem(docId, namaBarang),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: BorderSide(
                          color: const Color(0xFFE53935).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
        ],
      ),
    );
  }
}
