import 'dart:io';
import 'package:flutter/material.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final bool isDraft;

  const ItemDetailScreen({
    super.key,
    required this.itemData,
    this.isDraft = false,
  });

  Widget _buildImageHero(BuildContext context, String path) {
    if (path.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: const Color(0xFF152238),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.blue.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Tidak ada foto dilampirkan', 
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
          ],
        ),
      );
    }

    if (isDraft) {
      return Image.file(
        File(path),
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageHero(context, ''),
      );
    }

    // Untuk laporan publik, kita kembalikan ke placeholder biru karena Firebase Storage belum aktif
    return Container(
      height: 300,
      width: double.infinity,
      color: const Color(0xFF152238),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.blue.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Gambar Disembunyikan (Public Mode)', 
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final namaBarang = itemData['namaBarang'] ?? 'Tanpa Nama';
    final deskripsi = itemData['deskripsi'] ?? 'Tidak ada detail spesifik.';
    final lokasi = itemData['lokasi'] ?? 'Lokasi tidak diketahui';
    final fotoPath = itemData['fotoPath'] ?? '';
    final bool isAvailable = itemData['isAvailable'] ?? true;
    final String timeRaw = itemData['dilaporkanPada'] ?? '';
    
    // Konversi waktu
    String displayTime = 'Waktu tidak diketahui';
    if (timeRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(timeRaw).toLocal();
        displayTime = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        displayTime = timeRaw;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: const Color(0xFF0D1B2A),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageHero(context, fotoPath),
                  // Gradient shadow
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF0D1B2A)],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!isAvailable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TELAH DIAMBIL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Barang
                  Text(
                    namaBarang,
                    style: TextStyle(
                      color: isAvailable ? Colors.white : Colors.white70,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      decoration: isAvailable ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Board (Waktu dan Lokasi)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2A4A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.map_rounded, "Lokasi Penemuan", lokasi),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        _infoRow(Icons.access_time_rounded, "Waktu Laporkan", displayTime),
                        if (isDraft)
                          ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            _infoRow(Icons.cloud_off_rounded, "Status Unggah", "Data ini masih Lokal (Offline)"),
                          ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Narasi Deskripsi
                  const Text(
                    "Deskripsi Detail",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152238),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      deskripsi,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF21CBF3), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
