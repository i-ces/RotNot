// Firebase configuration for Android
// Config is read from android/app/google-services.json
// DO NOT hardcode API keys here - keep credentials secure!

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase options - Android uses google-services.json
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android reads config from google-services.json automatically
      // No need to specify options here
      throw UnimplementedError(
        'Android uses google-services.json for Firebase configuration. '
        'Use Firebase.initializeApp() without options parameter.',
      );
    }
    throw UnsupportedError(
      'This app currently only supports Android platform. '
      'Firebase config is managed via google-services.json file.',
    );
  }
}
