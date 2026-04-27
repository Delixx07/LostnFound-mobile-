import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

// RUBRIK: Firebase Auth - Provider untuk manajemen autentikasi
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  bool _isLoading = false;

  /// Getter untuk mendapatkan user yang sedang login
  User? get currentUser => _currentUser;

  /// Getter untuk status loading (untuk menampilkan CircularProgressIndicator)
  bool get isLoading => _isLoading;

  /// Getter untuk mengecek apakah user sudah login
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    // Mendengarkan perubahan status autentikasi secara real-time
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // RUBRIK: Firebase Auth - Login dengan Email & Password
  /// Login pengguna dengan email dan password
  /// Throws [FirebaseAuthException] jika terjadi kesalahan autentikasi
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = credential.user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      // Lempar kembali error ke UI untuk ditampilkan via ScaffoldMessenger
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
    } finally {
      _setLoading(false);
    }
  }

  // RUBRIK: Firebase Auth - Register dengan Email & Password
  /// Mendaftarkan pengguna baru dengan email dan password
  /// Throws error message jika terjadi kesalahan autentikasi
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = credential.user;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
    } finally {
      _setLoading(false);
    }
  }

  // RUBRIK: Firebase Auth - Logout
  /// Keluar dari akun Firebase Auth
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw 'Gagal keluar dari akun. Coba lagi.';
    } finally {
      _setLoading(false);
    }
  }

  /// Mengkonversi kode error Firebase menjadi pesan yang ramah pengguna
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Gunakan email lain atau login.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Data draft tetap tersimpan lokal.';
      default:
        return 'Terjadi kesalahan autentikasi ($code). Coba lagi.';
    }
  }
}
