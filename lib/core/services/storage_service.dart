import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Uploads an image file with auto-compression
  /// Returns the download URL
  Future<String?> uploadImage(XFile imageFile, String userId) async {
    try {
      final file = File(imageFile.path);
      final int size = await file.length();

      // Basic 5MB check
      if (size > 5 * 1024 * 1024) {
        throw Exception('File is too large. Max size is 5MB.');
      }

      final ref = _storage
          .ref()
          .child('user_uploads')
          .child(userId)
          .child('images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Uploads a voice recording
  Future<String?> uploadAudio(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final int size = await file.length();

      // Basic 5MB check
      if (size > 5 * 1024 * 1024) {
        throw Exception('Audio file is too large. Max size is 5MB.');
      }

      final ref = _storage
          .ref()
          .child('user_uploads')
          .child(userId)
          .child('audio')
          .child(
            '${DateTime.now().millisecondsSinceEpoch}.m4a',
          ); // Assuming m4a/aac

      final metadata = SettableMetadata(
        contentType: 'audio/mp4', // Common for mobile recordings
        customMetadata: {'userId': userId},
      );

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Audio upload failed: $e');
    }
  }
}
