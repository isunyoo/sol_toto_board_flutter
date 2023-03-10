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
        return macos;
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
    apiKey: 'AIzaSyBG6EDspFZ8bgp_X-YiIZodFAkkT-DrJ-I',
    appId: '1:1032684398117:android:2889ffc570506fc84f41cc',
    messagingSenderId: '1032684398117',
    projectId: 'eth-toto-board',
    databaseURL: 'https://eth-toto-board-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'eth-toto-board.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQ2GkClF6-UCaR4ljfu6JGLpBt6qqcXvM',
    appId: '1:1032684398117:ios:7920c109f04e32044f41cc',
    messagingSenderId: '1032684398117',
    projectId: 'eth-toto-board',
    databaseURL: 'https://eth-toto-board-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'eth-toto-board.appspot.com',
    androidClientId: '1032684398117-h0h2sp8ifua19smf48olkfi7phd7lc65.apps.googleusercontent.com',
    iosClientId: '1032684398117-vh93ol07t1i1706muh3drv1ccju1om3t.apps.googleusercontent.com',
    iosBundleId: 'com.example.firebaseTest',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCQ2GkClF6-UCaR4ljfu6JGLpBt6qqcXvM',
    appId: '1:1032684398117:ios:7920c109f04e32044f41cc',
    messagingSenderId: '1032684398117',
    projectId: 'eth-toto-board',
    databaseURL: 'https://eth-toto-board-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'eth-toto-board.appspot.com',
    androidClientId: '1032684398117-h0h2sp8ifua19smf48olkfi7phd7lc65.apps.googleusercontent.com',
    iosClientId: '1032684398117-vh93ol07t1i1706muh3drv1ccju1om3t.apps.googleusercontent.com',
    iosBundleId: 'com.example.firebaseTest',
  );
}
