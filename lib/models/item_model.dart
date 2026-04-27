// RUBRIK: Relational Database - Model item yang memiliki foreign key ke tabel categories
class Item {
  final int? id;
  final String namaBarang;
  final String deskripsi;
  final String fotoPath;
  final String lokasi;
  final String userId;
  final int isSynced; // 0 = belum sync (draft), 1 = sudah sync
  // RUBRIK: Relational Database - Foreign Key ke tabel 'categories'
  final int categoryId;
  final String categoryName; // Denormalized untuk display, diisi saat join query

  const Item({
    this.id,
    required this.namaBarang,
    required this.deskripsi,
    required this.fotoPath,
    required this.lokasi,
    required this.userId,
    this.isSynced = 0, // Default: belum disinkronisasi
    this.categoryId = 1,
    this.categoryName = 'Lainnya',
  });

  /// Konversi Item ke Map untuk keperluan SQLite INSERT/UPDATE
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'namaBarang': namaBarang,
      'deskripsi': deskripsi,
      'fotoPath': fotoPath,
      'lokasi': lokasi,
      'userId': userId,
      'isSynced': isSynced,
      // RUBRIK: Relational Database - Menyimpan foreign key ke tabel categories
      'category_id': categoryId,
    };
  }

  /// Konversi Map dari SQLite ke objek Item
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      namaBarang: map['namaBarang'] as String,
      deskripsi: map['deskripsi'] as String,
      fotoPath: map['fotoPath'] as String,
      lokasi: map['lokasi'] as String,
      userId: map['userId'] as String,
      isSynced: map['isSynced'] as int? ?? 0,
      // RUBRIK: Relational Database - Baca foreign key dan nama kategori dari JOIN result
      categoryId: map['category_id'] as int? ?? 1,
      categoryName: map['categoryName'] as String? ?? 'Lainnya',
    );
  }

  /// Konversi ke Map untuk Firestore (tanpa field SQLite-specific)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'namaBarang': namaBarang,
      'deskripsi': deskripsi,
      'fotoPath': fotoPath,
      'lokasi': lokasi,
      'userId': userId,
      'kategori': categoryName, // Simpan nama kategori ke Firestore agar mudah dibaca
      'dilaporkanPada': DateTime.now().toIso8601String(),
      'isAvailable': true,
    };
  }

  /// CopyWith untuk membuat salinan dengan beberapa field yang diubah
  Item copyWith({
    int? id,
    String? namaBarang,
    String? deskripsi,
    String? fotoPath,
    String? lokasi,
    String? userId,
    int? isSynced,
    int? categoryId,
    String? categoryName,
  }) {
    return Item(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoPath: fotoPath ?? this.fotoPath,
      lokasi: lokasi ?? this.lokasi,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, namaBarang: $namaBarang, isSynced: $isSynced)';
  }
}
