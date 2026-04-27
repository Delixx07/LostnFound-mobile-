# 🔍 Overview Proyek: Lost & Found Kampus (PeBeBe)

Selamat datang di *source code* aplikasi **Lost & Found Kampus (PeBeBe)**! Aplikasi ini dirancang agar mahasiswa bisa dengan mudah melaporkan barang yang hilang atau ditemukan di sekitar kampus.

Di balik antarmukanya, aplikasi ini menggunakan kombinasi penyimpanan lokal dan *cloud* agar bisa berjalan dengan lancar (mendukung *offline-first*). Berikut adalah teknologi dan fitur yang ada di dalamnya:

---

## 🌟 Fitur Utama & Teknologi

1. **Penyimpanan Lokal (Offline-First) dengan SQLite**
   Agar user tetap bisa membuat draft laporan saat tidak ada internet, aplikasi ini menggunakan database relasional lokal (SQLite). Semua operasi **CRUD** (Create, Read, Update, Delete) berjalan lancar di sini. Bahkan, struktur datanya berelasi antara tabel laporan dan tabel kategori (*Foreign Key*).

2. **Sistem Akun Terintegrasi (Firebase Auth)**
   Setiap pengguna memiliki data yang aman. Aplikasi ini menggunakan **Firebase Authentication** untuk fitur login dan registrasi berbasis email. Sesi pengguna juga dipertahankan secara otomatis, ditambah adanya sistem *Role-Based Access* untuk email `admin@gmail.com` yang bisa mengakses panel khusus admin.

3. **Sinkronisasi Data ke Cloud (Firestore)**
   Setelah laporan selesai dibuat secara lokal, pengguna bisa mengunggahnya ke server global. Di sini, **Firebase Firestore** (NoSQL) bertugas menyimpan dan mendistribusikan data laporan tersebut secara *real-time* ke semua mahasiswa lain di kampus melalui fitur "Daftar Publik".

4. **Notifikasi Pintar (Real-time Notifications)**
   Aplikasi ini memiliki sebuah *background listener* yang selalu mengecek status laporan pengguna di Firestore. Begitu ada barang yang statusnya berubah menjadi "Sudah Diambil", sistem langsung menembakkan **Local Push Notification** (lengkap dengan suara pop-up) menggunakan package *Awesome Notifications* untuk memberi tahu si pelapor.

5. **Pemanfaatan Fitur HP (Kamera & Galeri)**
   Sebuah laporan barang tentu butuh foto. Aplikasi ini memanfaatkan sumber daya *hardware smartphone* menggunakan *Image Picker*, di mana pengguna bisa langsung memotret barang memakai **Kamera** secara langsung atau mengambil gambar dari **Galeri** ponsel.

---

## 🧩 Arsitektur Program (MVC)

Aplikasi ini menggunakan pola desain **Model-View-Controller (MVC)** untuk memisahkan tampilan, logika, dan database:
```text
lib/
├── models/         # (Model) Struktur data & skema database
├── screens/        # (View) Tampilan UI menggunakan Flutter Widgets
├── providers/      # (Controller) Logika bisnis & State Management
└── services/       # Komunikasi dengan database (SQLite, Firebase, dsb)
```

## 🌳 Gambaran Flutter Widget Tree

Berikut adalah struktur dasar *Widget Tree* yang menyusun kerangka antarmuka aplikasi ini:

```text
MyApp (Root)
 └── MultiProvider (Menyuntikkan AuthProvider & ItemProvider)
      └── MaterialApp
           └── AuthScreen (Jika belum login) / HomeScreen (Jika sudah login)
                │
                ├── HomeScreen (Scaffold)
                │    ├── AppBar (Header & Tombol Logout)
                │    ├── Body (Tergantung Tab yang dipilih)
                │    │    ├── Tab 0: Consumer<ItemProvider> (List Draft SQLite)
                │    │    ├── Tab 1: StreamBuilder (List Laporan Saya - Firestore)
                │    │    └── Tab 2: StreamBuilder (List Publik - Firestore)
                │    │
                │    ├── BottomNavigationBar (Navigasi Antar Tab)
                │    │
                │    └── FloatingActionButton (Tombol Tambah Laporan)
                │         └── Navigasi ke AddItemScreen
                │
                └── AdminScreen (Khusus akun Admin)
                     ├── StreamBuilder (Dashboard Statistik)
                     └── ListView (Manajemen laporan publik)
```

**Kesimpulan:** Seluruh sistem dari depan (UI) hingga ke belakang (Database & Server) sudah terhubung sepenuhnya! Aplikasi siap digunakan dan didemokan.
