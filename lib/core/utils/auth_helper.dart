import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to get current user information
class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current user ID
  static String? get userId => _auth.currentUser?.uid;

  /// Get the current user ID or return a default value
  static String getUserIdOrDefault([String defaultId = 'anonymous']) {
    return userId ?? defaultId;
  }

  /// Get the current user's display name
  static String? get userName => _auth.currentUser?.displayName;

  /// Get the current user's display name or return a default
  static String getUserNameOrDefault([String defaultName = 'User']) {
    return userName ?? defaultName;
  }

  /// Get the current user's email
  static String? get userEmail => _auth.currentUser?.email;

  /// Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Get the current Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Get user's full name from Firestore profile
  static Future<String> getUserFullName() async {
    final user = _auth.currentUser;
    if (user == null) return 'User';

    // First try display name from auth
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // Then try to get from Firestore profile
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          // Try different possible name fields
          if (data.containsKey('name') && data['name'] != null) {
            return data['name'] as String;
          }
          if (data.containsKey('displayName') && data['displayName'] != null) {
            return data['displayName'] as String;
          }
          if (data.containsKey('fullName') && data['fullName'] != null) {
            return data['fullName'] as String;
          }
        }
      }
    } catch (e) {
      // Silently fail and return default
    }

    return 'User';
  }

  /// Get user profile data from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      // Silently fail
    }

    return null;
  }
}
