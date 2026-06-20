import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGPtN6f0GQqF7-6vMf-sGk-nYkGV1p6Zs',
    appId: '1:169354239547:android:a95288d71c446e1c24861e',
    messagingSenderId: '169354239547',
    projectId: 'notes-manager-cd97b',
    storageBucket: 'notes-manager-cd97b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmU_zki6gDTXs7xKOKIB8tzeobqzlTZY8',
    appId: '1:169354239547:ios:8705c6f61612586824861e',
    messagingSenderId: '169354239547',
    projectId: 'notes-manager-cd97b',
    storageBucket: 'notes-manager-cd97b.firebasestorage.app',
    iosBundleId: 'com.example.authNotesManager',
  );
}
