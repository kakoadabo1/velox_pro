// Généré pour le projet Firebase "velox-pro-d6030" (app Android dj.nomade.velox_pro).
// Si tu ajoutes une app iOS/Web dans Firebase, régénère ce fichier avec
// `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions n\'a pas été configuré pour le Web. '
        'Lance `flutterfire configure` si tu cibles le Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'FirebaseOptions n\'a pas été configuré pour iOS. '
          'Ajoute une app iOS dans Firebase puis lance `flutterfire configure`.',
        );
      default:
        throw UnsupportedError(
          'FirebaseOptions non supporté pour cette plateforme.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAuWgVLKrP4KdC3rjwSUUdzdVWsQZarloU',
    appId: '1:23290944403:android:f8a4a3c1722d87e4a9a666',
    messagingSenderId: '23290944403',
    projectId: 'velox-pro-d6030',
    storageBucket: 'velox-pro-d6030.firebasestorage.app',
  );
}
