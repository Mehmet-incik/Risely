import 'package:firebase_auth/firebase_auth.dart';

// LoginScreen ve ProfileScreen (misafir hesap yükseltme) ortak kullanır.
String firebaseAuthErrorMessage(FirebaseAuthException e) {
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
    case 'credential-already-in-use':
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
