import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for backing up and restoring user data
class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a backup of all user data
  Future<Map<String, dynamic>> createBackup() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final userId = user.uid;

    // Get app version from package info
    String appVersion = '1.0.0'; // Default fallback
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      // Silently fail and use default version
    }

    final backupData = <String, dynamic>{
      'userId': userId,
      'backupTimestamp': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
    };

    try {
      // Backup user settings
      final settingsDoc = await _firestore
          .collection('user_settings')
          .doc(userId)
          .get();
      if (settingsDoc.exists) {
        backupData['settings'] = settingsDoc.data();
      }

      // Backup user profile
      final profileDoc = await _firestore.collection('users').doc(userId).get();
      if (profileDoc.exists) {
        backupData['profile'] = profileDoc.data();
      }

      // Backup family groups (where user is a member)
      final familyGroupsQuery = await _firestore
          .collection('family_groups')
          .where('members', arrayContains: userId)
          .get();
      backupData['familyGroups'] = familyGroupsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Backup saved locations/favorites
      final locationsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .get();
      backupData['savedLocations'] = locationsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Backup offline map downloads metadata
      final offlineMapsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('offline_maps')
          .get();
      backupData['offlineMaps'] = offlineMapsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Backup emergency contacts
      final emergencyContactsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .get();
      backupData['emergencyContacts'] = emergencyContactsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      return backupData;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Saves backup to Firestore
  Future<String> saveBackup(Map<String, dynamic> backupData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final backupRef = await _firestore
          .collection('user_backups')
          .doc(user.uid)
          .collection('backups')
          .add(backupData);

      // Keep only last 5 backups to save storage
      await _cleanOldBackups(user.uid);

      return backupRef.id;
    } catch (e) {
      throw Exception('Failed to save backup: $e');
    }
  }

  /// Restores user data from a backup
  Future<void> restoreBackup(String backupId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final backupDoc = await _firestore
          .collection('user_backups')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      final backupData = backupDoc.data()!;

      // Restore settings
      if (backupData.containsKey('settings')) {
        await _firestore
            .collection('user_settings')
            .doc(user.uid)
            .set(backupData['settings'], SetOptions(merge: true));
      }

      // Restore profile
      if (backupData.containsKey('profile')) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(backupData['profile'], SetOptions(merge: true));
      }

      // Restore saved locations
      if (backupData.containsKey('savedLocations')) {
        final locations = backupData['savedLocations'] as List;
        for (final location in locations) {
          final locationData = Map<String, dynamic>.from(location);
          final id = locationData.remove('id') as String;
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('saved_locations')
              .doc(id)
              .set(locationData, SetOptions(merge: true));
        }
      }

      // Restore emergency contacts
      if (backupData.containsKey('emergencyContacts')) {
        final contacts = backupData['emergencyContacts'] as List;
        for (final contact in contacts) {
          final contactData = Map<String, dynamic>.from(contact);
          final id = contactData.remove('id') as String;
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('emergency_contacts')
              .doc(id)
              .set(contactData, SetOptions(merge: true));
        }
      }

      // Note: Family groups and offline maps are not restored as they
      // may have changed or been deleted by other users
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Gets list of available backups
  Future<List<Map<String, dynamic>>> getBackups() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final backupsQuery = await _firestore
          .collection('user_backups')
          .doc(user.uid)
          .collection('backups')
          .orderBy('backupTimestamp', descending: true)
          .limit(5)
          .get();

      return backupsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get backups: $e');
    }
  }

  /// Deletes old backups, keeping only the most recent 5
  Future<void> _cleanOldBackups(String userId) async {
    try {
      final backupsQuery = await _firestore
          .collection('user_backups')
          .doc(userId)
          .collection('backups')
          .orderBy('backupTimestamp', descending: true)
          .get();

      // Keep first 5, delete the rest
      if (backupsQuery.docs.length > 5) {
        final toDelete = backupsQuery.docs.skip(5);
        for (final doc in toDelete) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Performs a complete backup operation
  Future<String> performBackup() async {
    final backupData = await createBackup();
    final backupId = await saveBackup(backupData);
    return backupId;
  }

  /// Deletes a specific backup
  Future<void> deleteBackup(String backupId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      await _firestore
          .collection('user_backups')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }
}
