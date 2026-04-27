import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/item_provider.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';

// RUBRIK: Hardware Resources - Layar tambah / edit laporan barang: Kamera + Galeri
class AddItemScreen extends StatefulWidget {
  // Jika editItem diisi, layar berjalan dalam mode EDIT (UPDATE SQLite)
  final Item? editItem;

  const AddItemScreen({super.key, this.editItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();

  // RUBRIK: Hardware Resources - State untuk foto
  File? _selectedImage;
  bool _isSubmitting = false;

  // RUBRIK: Relational Database - Pilihan kategori
  Category? _selectedCategory;
  String? _existingImagePath; // Untuk mode edit, simpan path lama

  bool get _isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    // Jika mode EDIT - isi semua field dengan data yang sudah ada
    if (_isEditMode) {
      final item = widget.editItem!;
      _namaController.text = item.namaBarang;
      _deskripsiController.text = item.deskripsi;
      _lokasiController.text = item.lokasi;
      _existingImagePath = item.fotoPath;
      // Kategori akan diset setelah categories provider dimuat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = context.read<ItemProvider>().categories;
        final match = categories.where((c) => c.id == item.categoryId).firstOrNull;
        if (match != null && mounted) {
          setState(() => _selectedCategory = match);
        }
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  // RUBRIK: Hardware Resources - Akses Kamera menggunakan image_picker
  Future<void> _openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Kompresi 80% untuk efisiensi storage
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: ${e.toString()}'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  // RUBRIK: Hardware Resources - Akses Galeri
  Future<void> _openGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka galeri: ${e.toString()}'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  // RUBRIK: CRUD SQLite - Submit form dan simpan ke database lokal
  Future<void> _submitForm() async {
    // Validasi form input teks
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // RUBRIK: Hardware Resources - Validasi ketat: Foto wajib ada (kecuali sedang edit dan sudah ada foto lama)
    final bool hasFoto = _selectedImage != null || (_isEditMode && (_existingImagePath?.isNotEmpty ?? false));
    if (!hasFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white),
              SizedBox(width: 10),
              Text('Foto barang wajib diambil terlebih dahulu!'),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // RUBRIK: Validasi ketat: Lokasi wajib diisi
    if (_lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Text('Lokasi kehilangan/penemuan wajib diisi!'),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Simpan referensi sebelum async gap
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final authProvider = context.read<app_auth.AuthProvider>();
      final itemProvider = context.read<ItemProvider>();

      final selectedCat = _selectedCategory;
      final newItem = Item(
        id: _isEditMode ? widget.editItem!.id : null,
        namaBarang: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        // Gunakan foto baru jika dipilih, jika tidak pakai foto lama (mode edit)
        fotoPath: _selectedImage?.path ?? _existingImagePath ?? '',
        lokasi: _lokasiController.text.trim(),
        userId: authProvider.currentUser?.uid ?? 'unknown',
        isSynced: 0,
        categoryId: selectedCat?.id ?? 1,
        categoryName: selectedCat?.name ?? 'Lainnya',
      );

      // RUBRIK: CRUD SQLite - INSERT atau UPDATE
      if (_isEditMode) {
        await itemProvider.updateDraft(newItem);
      } else {
        await itemProvider.addItemToDraft(newItem);
      }

      // Auto-sync untuk admin
      final isAdmin = authProvider.currentUser?.email == 'admin@gmail.com';
      if (isAdmin) {
        await itemProvider.syncToFirebase();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.save_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Text(isAdmin 
                  ? 'Laporan berhasil disimpan dan diunggah!'
                  : (_isEditMode ? 'Draft berhasil diperbarui!' : 'Draft laporan berhasil disimpan!')),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan draft: ${e.toString()}'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Laporan Draft' : 'Tambah Laporan Baru',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RUBRIK: Hardware Resources - Seksi Kamera
              _buildSectionTitle('📷 Foto Barang', 'Wajib di-isi'),
              const SizedBox(height: 12),
              _buildCameraSection(),
              const SizedBox(height: 24),

              // RUBRIK: Hardware Resources - Seksi Lokasi (Manual String)
              _buildSectionTitle('📍 Lokasi Ditemukan/Hilang', 'Wajib di-isi'),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _lokasiController,
                label: 'Lokasi (Gedung/Ruangan)',
                hint: 'Contoh: Departemen Informatika Kelas 105',
                icon: Icons.map_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lokasi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Seksi Informasi Barang
              _buildSectionTitle('📝 Informasi Barang', null),
              const SizedBox(height: 12),
              _buildInfoSection(),
              const SizedBox(height: 32),

              // Tombol Submit
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? badge) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
            ),
            child: const Text(
              'Wajib',
              style: TextStyle(
                  color: Color(0xFFEF9A9A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // RUBRIK: Hardware Resources - Widget area kamera dan preview foto
  Widget _buildCameraSection() {
    return GestureDetector(
      onTap: _openCamera,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _selectedImage != null
                ? const Color(0xFF2196F3).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: _selectedImage != null
            // RUBRIK: Hardware Resources - Preview gambar dari kamera
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _openCamera,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _openGallery,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.photo_library,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _openCamera,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF2196F3), size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Buka Kamera',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _openGallery,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.photo_library_outlined,
                              color: Colors.orange, size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pilih di Galeri',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        // Field Nama Barang
        _buildInputField(
          controller: _namaController,
          label: 'Nama Barang',
          hint: 'Contoh: Dompet hitam, Koper merah...',
          icon: Icons.inventory_2_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama barang wajib diisi';
            }
            if (val.trim().length < 3) {
              return 'Nama barang minimal 3 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildCategoryDropdown(),
        const SizedBox(height: 16),

        // Field Deskripsi
        _buildInputField(
          controller: _deskripsiController,
          label: 'Deskripsi Detail',
          hint: 'Jelaskan ciri-ciri barang, di mana ditemukan/hilang...',
          icon: Icons.description_outlined,
          maxLines: 4,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Deskripsi wajib diisi';
            }
            if (val.trim().length < 10) {
              return 'Deskripsi minimal 10 karakter';
            }
            return null;
          },
        ),
      ],
    );
  }

  // RUBRIK: Relational Database - Dropdown untuk memilih kategori yang di-load dari SQLite
  Widget _buildCategoryDropdown() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, _) {
        final categories = itemProvider.categories;
        
        if (categories.isEmpty) {
          return const SizedBox.shrink(); // Hide jika data belum siap
        }

        return DropdownButtonFormField<Category>(
          initialValue: _selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          decoration: InputDecoration(
            labelText: 'Kategori Barang',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.category_outlined, color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
            ),
          ),
          dropdownColor: const Color(0xFF1B2A4A),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: categories.map((Category cat) {
            return DropdownMenuItem<Category>(
              value: cat,
              child: Text(cat.name),
            );
          }).toList(),
          onChanged: (Category? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Kategori wajib dipilih';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: const Color(0xFF2196F3).withValues(alpha: 0.5),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.save_rounded, size: 22),
        label: Text(
          _isSubmitting ? 'Menyimpan Draft...' : 'Simpan sebagai Draft',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
