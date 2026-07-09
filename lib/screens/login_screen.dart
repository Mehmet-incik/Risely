import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../services/services.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'weak-password':
        return 'Şifre çok zayıf, en az 6 karakter olmalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı, lütfen biraz sonra tekrar dene.';
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi şu anda kullanılamıyor.';
      default:
        return 'Bir şeyler ters gitti, lütfen tekrar dene.';
    }
  }

  Future<void> _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve şifre alanları boş bırakılamaz.');
      return;
    }
    if (!_isLoginMode && name.isEmpty) {
      setState(() => _errorMessage = 'Lütfen adını gir.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        if (mounted) {
          await context.read<TaskStore>().saveUserName(name);
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo ve Başlık
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.xp, AppColors.academic]), boxShadow: [BoxShadow(color: AppColors.xp.withOpacity(0.4), blurRadius: 15, spreadRadius: -5)]),
                child: const Center(child: Text('🚀', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 24),
              Text('Risely', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(_isLoginMode ? 'Kendi efsaneni yazmaya devam et.' : 'Yeni bir başlangıç için efsaneni yazmaya başla.', style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 40),

              // Segment (Giriş Yap / Kayıt Ol)
              Center(
                child: CupertinoSlidingSegmentedControl<bool>(
                  backgroundColor: AppColors.surfaceAlt.withOpacity(0.5),
                  thumbColor: AppColors.surface,
                  groupValue: _isLoginMode,
                  padding: const EdgeInsets.all(4),
                  children: {
                    true: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Text('Giriş Yap', style: TextStyle(fontSize: 14, fontWeight: _isLoginMode ? FontWeight.bold : FontWeight.normal, color: _isLoginMode ? Colors.white : AppColors.textMuted))),
                    false: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Text('Kayıt Ol', style: TextStyle(fontSize: 14, fontWeight: !_isLoginMode ? FontWeight.bold : FontWeight.normal, color: !_isLoginMode ? Colors.white : AppColors.textMuted))),
                  },
                  onValueChanged: (val) { if (val != null) setState(() { _isLoginMode = val; _errorMessage = null; }); },
                ),
              ),
              const SizedBox(height: 30),

              // Form Alanları
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_isLoginMode),
                  children: [
                    if (!_isLoginMode) ...[
                      TextField(controller: _nameController, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'Tam Adın', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                      const SizedBox(height: 16),
                    ],
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'E-posta Adresi', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                    const SizedBox(height: 16),
                    TextField(controller: _passwordController, obscureText: _obscurePassword, style: TextStyle(color: AppColors.text, fontSize: 14), decoration: InputDecoration(filled: true, fillColor: AppColors.surface, hintText: 'Şifre', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13), prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20), suffixIcon: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword), child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18))),
                  ],
                ),
              ),

              if (_isLoginMode) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Şifremi Unuttum?', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)))),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.xp, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 5, shadowColor: AppColors.xp.withOpacity(0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_isLoginMode ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),

              // Misafir Girişi
              Row(children: [Expanded(child: Divider(color: AppColors.border, thickness: 1)), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('VEYA', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5))), Expanded(child: Divider(color: AppColors.border, thickness: 1))]),
              const SizedBox(height: 30),
              TextButton(
                onPressed: _isLoading ? null : _continueAsGuest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Bir hesap açmadan ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    Text('Misafir Olarak Devam Et', style: TextStyle(fontSize: 13, color: AppColors.xp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
