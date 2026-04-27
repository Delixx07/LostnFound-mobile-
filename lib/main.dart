import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'firebase_options.dart';
// Gunakan alias 'appAuth' untuk menghindari konflik dengan firebase_auth AuthProvider
import 'providers/auth_provider.dart' as app_auth;
import 'providers/item_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'services/notification_service.dart';

// RUBRIK: Semua rubrik terintegrasi di main.dart sebagai entry point
Future<void> main() async {
  // Pastikan binding Flutter sudah siap sebelum inisialisasi plugin
  WidgetsFlutterBinding.ensureInitialized();

  // RUBRIK: Firebase Auth & Firestore - Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // RUBRIK: Notifications - Inisialisasi Awesome Notifications
  await NotificationService.initialize();

  // Minta izin notifikasi dari pengguna
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // RUBRIK: State Management - MultiProvider dengan AuthProvider dan ItemProvider
      providers: [
        // RUBRIK: State Management - MultiProvider dengan AuthProvider dan ItemProvider
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lost & Found Kampus',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        ),
        // RUBRIK: Firebase Auth - Cek status autentikasi secara dinamis
        // Jika FirebaseAuth.instance.currentUser null => AuthScreen
        // Jika sudah login => cek admin atau bukan
        home: _getInitialScreen(),
      ),
    );
  }

  Widget _getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AuthScreen();
    }
    if (user.email == 'admin@gmail.com') {
      return const AdminScreen();
    }
    return const HomeScreen();
  }
}
