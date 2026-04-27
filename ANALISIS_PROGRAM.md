# Analisis Pemenuhan Rubrik Penilaian & Arsitektur
**Nama Aplikasi:** Lost & Found Kampus (PeBeBe)

Aplikasi ini telah dikembangkan dengan arsitektur **Model-View-Controller (MVC)** yang bersih dan terstruktur untuk memisahkan logika antarmuka, manajemen status, dan akses basis data.

## 📂 Struktur Direktori (Architecture Tree)
Berikut adalah struktur folder `lib/` yang menunjukkan pemisahan komponen (MVC):
```text
lib
├── main.dart
├── firebase_options.dart
├── models (Model)
│   ├── category_model.dart
│   └── item_model.dart
├── providers (Controller / State Management)
│   ├── auth_provider.dart
│   └── item_provider.dart
├── screens (View)
│   ├── add_item_screen.dart
│   ├── admin_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   └── item_detail_screen.dart
└── services (Data Layer)
    ├── firestore_listener_service.dart
    ├── notification_service.dart
    └── sqlite_service.dart
```

**Penjelasan Arsitektur MVC:**
* **Model (`lib/models/`):** Mendefinisikan struktur data seperti `Item` dan `Category`, dilengkapi dengan *factory method* untuk konversi dari/ke map (SQLite dan Firestore).
* **View (`lib/screens/`):** Berisi antarmuka pengguna (UI) murni yang dibangun dengan Flutter widgets. Views mengambil data dengan mendengarkan (listening) ke *Providers*.
* **Controller / ViewModel (`lib/providers/`):** Bertindak sebagai perantara logika bisnis. `item_provider.dart` dan `auth_provider.dart` menangani logika aplikasi, memproses permintaan dari UI, berinteraksi dengan *services*, dan memperbarui state agar UI merender ulang (*notifyListeners*).
* **Data Layer / Services (`lib/services/`):** Menangani interaksi langsung dengan eksternal (SQLite, Firebase, Notifications) agar Controller tetap bersih.

---

## 🎯 Pemenuhan Rubrik Penilaian

### 1. CRUD with a Relational Database (10%)
Fungsionalitas CRUD diimplementasikan secara penuh menggunakan **SQLite** (`lib/services/sqlite_service.dart`) sebagai basis data relasional lokal (Offline-First).
* **Create:** Membuat "Draft Lokal" laporan yang disimpan ke tabel `items`.
* **Read:** Laporan dibaca pada tab "Draft Lokal" (`home_screen.dart`). Terdapat *Foreign Key* ke tabel `categories` (Join tabel).
* **Update:** Draft laporan dapat diedit bebas sebelum disinkronisasi ke server.
* **Delete:** Draft laporan dapat dihapus secara permanen.

### 2. Firebase Authentication (login, etc.) (5%)
Sistem autentikasi terintegrasi secara penuh menggunakan **Firebase Auth** (`lib/providers/auth_provider.dart`).
* **Register & Login:** Autentikasi dilakukan via *Email dan Password*.
* **State Persistence:** Sesi login pengguna dipertahankan menggunakan `Stream` sehingga tidak perlu login berulang kali (`main.dart`).
* **Role-Based Access (Admin):** Penggunaan email `admin@gmail.com` akan diarahkan otomatis ke halaman `admin_screen.dart` dengan *privilege* penuh (hapus/update semua laporan).

### 3. Storing data in Firebase (5%)
Aplikasi memanfaatkan **Cloud Firestore** sebagai penyimpanan data *real-time* berbasis NoSQL.
* **Sinkronisasi (Sync):** Metode `syncToFirebase()` di `item_provider.dart` memindahkan data dari SQLite lokal ke koleksi `lost_items` di Firestore.
* **Global Feed & My Reports:** Laporan publik ditampilkan untuk semua user, sedangkan laporan individu disaring khusus menggunakan klausa `.where('userId', isEqualTo: uid)`.

### 4. Notifications (5%)
Fitur notifikasi diimplementasikan menggunakan **Awesome Notifications** dan **Firestore Real-time Listeners** (`lib/services/firestore_listener_service.dart`).
* **Real-time Listener:** Background service berlangganan (*subscribe*) pada *snapshot* koleksi Firestore milik pengguna.
* **Notification Delivery:** Ketika status dokumen berubah (`isAvailable` menjadi `false` oleh Admin/Penemu), aplikasi memicu *Push Notification* (Local) yang muncul di atas layar (*Heads-up*) dengan bunyi.

### 5. Using one smartphone resource (Camera/Gallery) (5%)
Aplikasi memanggil sumber daya *hardware* melalui package **Image Picker** pada `add_item_screen.dart`.
* **Kamera:** Membuka fungsi Kamera secara langsung untuk memotret barang penemuan secara *real-time*.
* **Galeri:** Mengakses media penyimpanan (Galeri) ponsel. Gambar dikonversi dan disimpan ke dalam basis data sebagai format *base64 string* yang efisien, dan di-decode pada saat penayangan.

---
**Kesimpulan:** Aplikasi telah selesai secara komprehensif, aman, *offline-ready*, terintegrasi cloud, dan siap didemokan.
