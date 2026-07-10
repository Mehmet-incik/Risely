import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('is_dark_mode') ?? true;
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskStore(),
      child: const RiselyApp(),
    ),
  );
}

class RiselyApp extends StatelessWidget {
  const RiselyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Risely',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: AppColors.bg,
            colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: AppColors.xp, surface: AppColors.surface,
            ),
          ),
          // Oturum durumuna göre LoginScreen ya da SplashScreen'e yönlendirir
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // ÖNEMLİ: LoginScreen/SplashScreen KENDİ İÇLERİNDE Navigator.pushReplacement
  // ile bir sonraki ekrana geçmemeli — bu, AuthGate'i içeren route'un YERİNE
  // geçer ve AuthGate'i (dolayısıyla bu dinleyiciyi) widget ağacından tamamen
  // düşürür. Bir daha giriş/çıkış olayı hiç yakalanmaz. Bunun yerine ekranlar
  // arası geçiş SADECE burada, _user/_splashDone state'i üzerinden yönetilir.
  User? _user;
  bool _isWaiting = true;
  bool _splashDone = false;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
        _isWaiting = false;
        _splashDone = false; // her yeni oturumda splash tekrar oynasın
      });
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isWaiting) return Scaffold(backgroundColor: AppColors.bg);
    if (_user == null) return const LoginScreen();
    if (!_splashDone) {
      return SplashScreen(onFinished: () => setState(() => _splashDone = true));
    }
    return const MainScreen();
  }
}
