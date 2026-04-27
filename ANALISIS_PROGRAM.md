# 🔍 Overview Proyek: Lost & Found Kampus (PeBeBe)

Selamat datang di *source code* aplikasi **Lost & Found Kampus (PeBeBe)**! Aplikasi ini dirancang untuk memecahkan masalah klasik di lingkungan kampus: barang yang hilang atau tertinggal. Dengan aplikasi ini, mahasiswa bisa dengan mudah melaporkan barang yang mereka temukan atau mencari barang mereka yang hilang.

Di balik antarmukanya yang sederhana, aplikasi ini menggunakan kombinasi penyimpanan lokal (*offline-first*) dan komputasi awan (*cloud*) agar bisa berjalan dengan responsif, handal, dan *real-time*. Berikut adalah rincian mendalam mengenai teknologi dan fitur yang ada di dalamnya:

---

## 🌟 Fitur Utama & Pemanfaatan Teknologi

### 1. Penyimpanan Lokal (Offline-First) dengan Relational Database (SQLite)
Aplikasi tidak selalu bergantung pada koneksi internet yang stabil. Untuk itu, kami merancang sistem **Offline-First**.
* **Konsep CRUD Utuh:** Semua operasi Create, Read, Update, dan Delete dilakukan di penyimpanan lokal ponsel (menggunakan *package* `sqflite`) terlebih dahulu.
* **Tabel Relasional:** Kami menerapkan konsep relasional antara tabel `items` (menyimpan detail laporan barang) dan tabel `categories` (menyimpan daftar kategori barang seperti Elektronik, Dokumen, dll). Ketika data ditampilkan, aplikasi melakukan *JOIN* agar id kategori berubah menjadi nama kategori yang mudah dibaca.
* **Drafting System:** Fitur ini membuat pengguna bisa menyiapkan laporan beserta foto di tab "Draft Lokal" tanpa menghabiskan kuota internet, dan bebas merevisinya sebelum dipublikasikan.

### 2. Sistem Autentikasi dan Manajemen Sesi (Firebase Auth)
Setiap pengguna yang berinteraksi dengan aplikasi ini memiliki identitas yang aman dan terverifikasi.
* **Keamanan Kredensial:** Aplikasi menggunakan **Firebase Authentication** untuk mengelola proses pendaftaran (Registrasi) dan Masuk (Login) menggunakan Email dan Password.
* **State Persistence:** Sesi pengguna dipertahankan menggunakan metode `Stream` dari FirebaseAuth. Artinya, jika pengguna menutup aplikasi dan membukanya kembali besok, mereka tidak perlu repot-repot login ulang.
* **Role-Based Access (Admin Panel):** Kami membuat jalur pintas otomatis khusus untuk peran admin. Jika ada yang *login* menggunakan kredensial `admin@gmail.com`, aplikasi akan langsung mengenalinya dan mengarahkan pengguna ke **Admin Panel**—sebuah layar khusus di mana admin memiliki kuasa penuh untuk melihat, menandai selesai, atau menghapus permanen setiap laporan yang ada di server.

### 3. Sinkronisasi Data Global & Real-Time (Cloud Firestore)
Setelah laporan selesai dibuat secara lokal, aplikasi mengizinkan pengguna untuk "menyinkronkan" (mengunggah) data tersebut ke server global.
* **Arsitektur NoSQL Firestore:** Data diunggah ke koleksi `lost_items` di Firestore. Kami memilih Firestore karena kemampuannya dalam memproses data secara *real-time* ke semua perangkat yang terkoneksi.
* **Pengkategorian Tampilan (Queries):** Di dalam aplikasi, data yang sudah di-sinkronisasi akan dihapus dari lokal, dan diklasifikasikan ke dua tempat menggunakan Query Firestore:
  * **Laporan Saya:** Menggunakan filter Query `where('userId', isEqualTo: uid)` untuk hanya menampilkan laporan yang diunggah oleh pengguna tersebut.
  * **Daftar Publik:** Menampilkan semua laporan barang dari semua pengguna, diurutkan berdasarkan waktu laporan agar informasi terbaru selalu berada di paling atas.

### 4. Sistem Notifikasi Latar Belakang (Real-time Notifications)
Bayangkan Anda melaporkan kehilangan dompet, dan keesokan harinya ada yang menemukannya. Bagaimana Anda bisa tahu tanpa harus mengecek aplikasi setiap saat?
* **Real-time Listener:** Kami membuat `FirestoreListenerService` yang berjalan di latar belakang aplikasi. Servis ini secara konstan berlangganan (*subscribe*) pada data laporan pengguna yang sedang login.
* **Trigger Otomatis:** Ketika ada barang yang statusnya diubah menjadi "Sudah Diambil" (`isAvailable: false`) oleh Admin atau Penemu, *listener* ini akan langsung menangkap perubahan data dari server seketika itu juga.
* **Local Push Notification:** Sebagai respons, aplikasi langsung menembakkan **Notifikasi Lokal** ke layar ponsel (*Heads-up notification* dengan suara) menggunakan *package* Awesome Notifications, memberi tahu Anda bahwa laporan Anda telah diselesaikan.

### 5. Pemanfaatan Hardware Smartphone (Kamera & Galeri)
Aplikasi pelaporan barang tentu tidak lengkap tanpa bukti visual (foto). Kami memanfaatkan sumber daya perangkat keras (Hardware) pada ponsel menggunakan *Image Picker*.
* **Akses Kamera Langsung:** Pengguna bisa langsung menyalakan **Kamera** dari dalam aplikasi untuk memotret dompet atau jam tangan yang baru saja mereka temukan di kelas.
* **Akses Memori Lokal (Galeri):** Selain kamera, pengguna diberikan kebebasan untuk mengakses Galeri foto yang sudah ada di memori internal ponsel.
* **Efisiensi Penyimpanan:** Agar beban aplikasi tetap ringan, gambar yang diambil dikompres dan dikonversi menjadi format *Base64 String* (teks murni) lalu disimpan langsung ke dalam kolom SQLite/Firestore, tanpa membebani penyimpanan *file storage* terpisah.

---

## 🧩 Arsitektur Program (Pola Desain MVC)

Agar basis kode tetap rapi, mudah dibaca, dan mudah dikembangkan oleh tim kerja di masa depan, proyek ini disusun menggunakan arsitektur **Model-View-Controller (MVC)**. Berikut rinciannya:

```text
lib/
├── models/         # (Model) Berisi struktur blueprint data (item_model.dart, category_model.dart). Di sinilah definisi tabel database berada.
├── screens/        # (View) Berisi murni antarmuka pengguna (UI) yang dirancang menggunakan Flutter Widgets (auth_screen, home_screen, dll).
├── providers/      # (Controller) Tempat segala logika bisnis dan State Management berada. Menjembatani View dan Data.
└── services/       # (Data Layer) Tempat aplikasi berkomunikasi dengan "dunia luar", baik itu ke memori SQLite ponsel maupun ke Server Firebase.
```

## 🌳 Struktur Dasar Flutter Widget Tree

Untuk mempermudah pemahaman tentang aliran UI (antarmuka), berikut adalah visualisasi *Widget Tree* utama dari aplikasi:

```text
MyApp (Akar Aplikasi)
 └── MultiProvider (Menyuntikkan AuthProvider & ItemProvider ke seluruh lapisan UI)
      └── MaterialApp (Pengatur Tema dan Navigasi Dasar)
           └── Pengecekan Login:
                │
                ├── JIKA BELUM LOGIN: AuthScreen (Menampilkan form login)
                │
                └── JIKA SUDAH LOGIN:
                     ├── Akun Admin (admin@gmail.com):
                     │    └── AdminScreen (Scaffold)
                     │         ├── StreamBuilder (Dashboard Statistik: Menunggu vs Selesai)
                     │         └── Tab View: ListView.builder (Manajemen laporan publik)
                     │
                     └── Akun Mahasiswa Biasa:
                          └── HomeScreen (Scaffold)
                               ├── AppBar (Header & Tombol Logout)
                               ├── Body (Tergantung Tab Navigasi Bawah)
                               │    ├── Tab 0: Consumer<ItemProvider> (Daftar Draft dari SQLite)
                               │    ├── Tab 1: StreamBuilder (Filter Laporan Saya dari Firestore)
                               │    └── Tab 2: StreamBuilder (Feed Daftar Publik dari Firestore)
                               │
                               ├── BottomNavigationBar (Berpindah Tab)
                               │
                               └── FloatingActionButton (Tombol "+" Tambah Laporan)
                                    └── Menavigasikan (Push) ke AddItemScreen (Input Form & Kamera)
```

**Penutup:**
Secara keseluruhan, aplikasi Lost & Found Kampus ini sudah berhasil mengimplementasikan semua requirement tugas yang diberikan. Mulai dari pemakaian SQLite untuk fungsi offline, Firebase untuk sinkronisasi cloud dan login, hingga fitur tambahan seperti akses kamera dan notifikasi lokal, semuanya sudah berjalan dengan baik dan saling terhubung.
