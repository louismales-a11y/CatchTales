import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Backs up catch photos to Firebase Storage.
/// Silent failure — never crashes the app.
class PhotoBackupService {
  static final PhotoBackupService instance = PhotoBackupService._();
  PhotoBackupService._();

  /// Upload a photo to Firebase Storage.
  /// Returns the download URL if successful, null otherwise.
  Future<String?> uploadPhoto(String localPath, {String? catchId}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final file = File(localPath);
      if (!file.existsSync()) return null;

      final id = catchId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('photos')
          .child('$id.jpg');

      // Fail fast if Storage is unavailable (Spark plan)
      await ref.putFile(file).timeout(const Duration(seconds: 5));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('PhotoBackupService.uploadPhoto failed: $e');
      return null; // Photo stays local
    }
  }

  /// Delete a photo from Firebase Storage by URL.
  Future<void> deletePhoto(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('PhotoBackupService.deletePhoto failed: $e');
    }
  }
}
