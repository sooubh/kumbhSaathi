import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../firebase_options.dart';

/// Firebase service for database operations
class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Google Sign In only on mobile (Required for v7.0.0+)
    if (!kIsWeb) {
      await googleSignIn.initialize();
    }

    // Enable offline persistence for Firestore
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Get current user ID
  static String? get currentUserId => auth.currentUser?.uid;

  /// Check if user is logged in
  static bool get isLoggedIn => auth.currentUser != null;

  /// Sign in anonymously (for quick access without registration)
  static Future<UserCredential> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific: Use Firebase Auth popup/redirect
        final GoogleAuthProvider provider = GoogleAuthProvider();
        // Using popup for better UX (alternatively use signInWithRedirect)
        return await auth.signInWithPopup(provider);
      } else {
        // Mobile: Use google_sign_in package v7.x authenticate() method
        final GoogleSignInAccount? googleUser = await googleSignIn
            .authenticate();

        // User cancelled the sign-in flow
        if (googleUser == null) {
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Check if we have the required credentials
        if (googleAuth.idToken == null) {
          throw Exception(
            'Failed to get authentication credentials from Google',
          );
        }

        // Create a new credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the OAuth credential
        return await auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // Firebase-specific authentication errors
      throw Exception('Authentication failed: ${e.message ?? e.code}');
    } catch (e) {
      // Handle user cancellation and other errors
      // PlatformException with code 'sign_in_canceled' or 'sign_in_failed'
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('SIGN_IN_CANCELLED') ||
          e.toString().contains('canceled')) {
        // User cancelled - return null gracefully
        return null;
      }
      // Other errors (network, developer config issues, etc.)
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }
}

/// Collection references
class FirestoreCollections {
  static const String users = 'users';
  static const String lostPersons = 'lost_persons';
  static const String ghats = 'ghats';
  static const String facilities = 'facilities';
  static const String facilityRoutes = 'facility_routes';
  static const String emergencyAlerts = 'emergency_alerts';
  static const String settings = 'settings';
}
