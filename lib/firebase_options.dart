// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDCrK07bfPA0nRCxC_9y4Go87yU5SfWkQ',
    appId: '1:697635097783:android:3ce695801fea6722d65132',
    messagingSenderId: '697635097783',
    projectId: 'mealpy-ca38a',
    databaseURL: 'https://mealpy-ca38a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'mealpy-ca38a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQcfsMMYR7rASYUx5JXnlygc_b5ggzrYs',
    appId: '1:697635097783:ios:5b2a91cca5ba0491d65132',
    messagingSenderId: '697635097783',
    projectId: 'mealpy-ca38a',
    databaseURL: 'https://mealpy-ca38a-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'mealpy-ca38a.appspot.com',
    androidClientId: '697635097783-d6q3cb4al5jqon8ridrvr2tkhrgd56vs.apps.googleusercontent.com',
    iosClientId: '697635097783-ov5ncaadj1n2jfb7e01uf735269p9t9d.apps.googleusercontent.com',
    iosBundleId: 'com.mk.mealpy',
  );
}
