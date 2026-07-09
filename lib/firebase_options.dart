// Bu dosya elle oluşturuldu (flutterfire CLI yerine google-services.json
// içeriği referans alınarak) — Node.js/Firebase CLI bu makinede kurulu değil.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions henüz web için ayarlanmadı — Risely şimdilik yalnızca Android hedefliyor.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için ayarlanmadı: $defaultTargetPlatform — Risely şimdilik yalnızca Android hedefliyor.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAe3ukuPJMkxdoo_7fR1VF72nVEEoxj4-c',
    appId: '1:186876835054:android:9a1d13fd06163babd62fff',
    messagingSenderId: '186876835054',
    projectId: 'risely-app',
    storageBucket: 'risely-app.firebasestorage.app',
  );
}
