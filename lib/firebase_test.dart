import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseTest {
  static Future<void> testConnection() async {
    try {
      // Test Firebase initialization
      print("Testing Firebase initialization...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase initialized successfully");

      // Test Firebase Authentication
      print("Testing Firebase Authentication...");
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        print("✅ Firebase Authentication successful. User ID: ${userCredential.user?.uid}");
        
        // Test Firestore
        print("Testing Firestore...");
        final db = FirebaseFirestore.instance;
        await db.collection('test').add({
          'test': 'connection',
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("✅ Firestore write successful");
        
        // Sign out the test user
        await FirebaseAuth.instance.signOut();
        print("✅ Test user signed out");
      } catch (authError) {
        print("❌ Firebase Authentication error: $authError");
      }
    } catch (error) {
      print("❌ Firebase initialization error: $error");
    }
  }
}