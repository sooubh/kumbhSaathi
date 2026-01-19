import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;
  static final _logger = Logger();

  /// Uploads an image file with auto-compression
  /// Returns the download URL
  Future<String?> uploadImage(XFile imageFile, String userId) async {
    try {
      _logger.d('🔵 [STORAGE] Starting image upload for user: $userId');

      final file = File(imageFile.path);
      final int size = await file.length();
      _logger.d(
        '🔵 [STORAGE] File size: ${(size / 1024).toStringAsFixed(2)} KB',
      );

      // Basic 5MB check
      if (size > 5 * 1024 * 1024) {
        _logger.w(
          '❌ [STORAGE] File too large: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        throw Exception('File is too large. Max size is 5MB.');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'user_uploads/$userId/images/$fileName';
      _logger.d('🔵 [STORAGE] Upload path: $path');

      final ref = _storage
          .ref()
          .child('user_uploads')
          .child(userId)
          .child('images')
          .child(fileName);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      _logger.d('🔵 [STORAGE] Starting upload task...');
      final uploadTask = ref.putFile(file, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _logger.d(
          '🔵 [STORAGE] Upload progress: ${progress.toStringAsFixed(1)}%',
        );
      });

      final taskSnapshot = await uploadTask;
      _logger.i('✅ [STORAGE] Upload completed successfully');

      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      _logger.d('✅ [STORAGE] Download URL obtained: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('❌ [STORAGE] Firebase error: ${e.code} - ${e.message}');
      _logger.e('❌ [STORAGE] Error details: ${e.toString()}');
      throw Exception('Storage upload failed: ${e.message ?? e.code}');
    } catch (e) {
      _logger.e('❌ [STORAGE] Unexpected error: ${e.toString()}');
      throw Exception('Image upload failed: $e');
    }
  }

  /// Uploads a voice recording
  Future<String?> uploadAudio(String filePath, String userId) async {
    try {
      _logger.d('🔵 [STORAGE] Starting audio upload for user: $userId');

      final file = File(filePath);
      final int size = await file.length();
      _logger.d(
        '🔵 [STORAGE] Audio file size: ${(size / 1024).toStringAsFixed(2)} KB',
      );

      // Basic 5MB check
      if (size > 5 * 1024 * 1024) {
        _logger.w(
          '❌ [STORAGE] Audio file too large: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        throw Exception('Audio file is too large. Max size is 5MB.');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = 'user_uploads/$userId/audio/$fileName';
      _logger.d('🔵 [STORAGE] Upload path: $path');

      final ref = _storage
          .ref()
          .child('user_uploads')
          .child(userId)
          .child('audio')
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'audio/mp4', // Common for mobile recordings
        customMetadata: {'userId': userId},
      );

      _logger.d('🔵 [STORAGE] Starting audio upload task...');
      final uploadTask = ref.putFile(file, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _logger.d(
          '🔵 [STORAGE] Audio upload progress: ${progress.toStringAsFixed(1)}%',
        );
      });

      final taskSnapshot = await uploadTask;
      _logger.i('✅ [STORAGE] Audio upload completed successfully');

      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      _logger.d('✅ [STORAGE] Audio download URL obtained: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('❌ [STORAGE] Firebase error: ${e.code} - ${e.message}');
      _logger.e('❌ [STORAGE] Error details: ${e.toString()}');
      throw Exception('Audio upload failed: ${e.message ?? e.code}');
    } catch (e) {
      _logger.e('❌ [STORAGE] Unexpected error: ${e.toString()}');
      throw Exception('Audio upload failed: $e');
    }
  }
}
