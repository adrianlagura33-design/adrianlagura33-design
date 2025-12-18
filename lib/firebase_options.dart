import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (isAndroid) {
      return android;
    } else if (isIOS) {
      return ios;
    } else if (isWeb) {
      return web;
    } else if (isMacOS) {
      return macos;
    } else if (isLinux) {
      return linux;
    } else if (isWindows) {
      return windows;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZm2WkfVIjULXJs6h2tOXd_TIJdlmS11Y',
    appId: '1:907981329888:android:5ef4607deb135424d54785',
    messagingSenderId: '907981329888',
    projectId: 'braids-scanner',
    databaseURL: 'https://braids-scanner-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'braids-scanner.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLQfjFq0JLzFZnrxgyFyyuXLQIYLBN5hQ',
    appId: '1:907981329888:ios:451a80e5b01f9efbd54785',
    messagingSenderId: '907981329888',
    projectId: 'braids-scanner',
    databaseURL: 'https://braids-scanner-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'braids-scanner.firebasestorage.app',
    iosBundleId: 'com.example.braids',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHC1PhnBQ3Us0RyFNc5hsXoTt04SBy1_I',
    appId: '1:907981329888:web:1759c5eb91a1abffd54785',
    messagingSenderId: '907981329888',
    projectId: 'braids-scanner',
    authDomain: 'braids-scanner.firebaseapp.com',
    databaseURL: 'https://braids-scanner-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'braids-scanner.firebasestorage.app',
    measurementId: 'G-N33FPD1XRZ',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLQfjFq0JLzFZnrxgyFyyuXLQIYLBN5hQ',
    appId: '1:907981329888:ios:451a80e5b01f9efbd54785',
    messagingSenderId: '907981329888',
    projectId: 'braids-scanner',
    databaseURL: 'https://braids-scanner-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'braids-scanner.firebasestorage.app',
    iosBundleId: 'com.example.braids',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAHC1PhnBQ3Us0RyFNc5hsXoTt04SBy1_I',
    appId: '1:907981329888:web:11d16928321ff464d54785',
    messagingSenderId: '907981329888',
    projectId: 'braids-scanner',
    authDomain: 'braids-scanner.firebaseapp.com',
    databaseURL: 'https://braids-scanner-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'braids-scanner.firebasestorage.app',
    measurementId: 'G-P71L9B21XC',
  );

  static bool get isAndroid =>
      const bool.fromEnvironment('dart.library.io') &&
      !const bool.fromEnvironment('dart.library.html');

  static bool get isIOS =>
      const bool.fromEnvironment('dart.library.io') &&
      !const bool.fromEnvironment('dart.library.html') &&
      (() {
        try {
          return const String.fromEnvironment('os.name').startsWith('iOS');
        } catch (e) {
          return false;
        }
      })();

  static bool get isWeb => const bool.fromEnvironment('dart.library.html');

  static bool get isMacOS =>
      const bool.fromEnvironment('dart.library.io') &&
      !const bool.fromEnvironment('dart.library.html') &&
      (() {
        try {
          return const String.fromEnvironment('os.name').startsWith('macOS');
        } catch (e) {
          return false;
        }
      })();

  static bool get isLinux =>
      const bool.fromEnvironment('dart.library.io') &&
      !const bool.fromEnvironment('dart.library.html') &&
      (() {
        try {
          return const String.fromEnvironment('os.name').startsWith('Linux');
        } catch (e) {
          return false;
        }
      })();

  static bool get isWindows =>
      const bool.fromEnvironment('dart.library.io') &&
      !const bool.fromEnvironment('dart.library.html') &&
      (() {
        try {
          return const String.fromEnvironment('os.name').startsWith('Windows');
        } catch (e) {
          return false;
        }
      })();
}