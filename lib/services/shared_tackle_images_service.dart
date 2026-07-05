import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anonymously shares user-added tackle images with other users.
///
/// When a user adds their own photo to a tackle item, the image is uploaded
/// to Firebase Storage and the URL is stored in Firestore. Other users' apps
/// periodically check for new shared images and display them in the catalog.
class SharedTackleImagesService {
  static final SharedTackleImagesService instance =
      SharedTackleImagesService._();
  SharedTackleImagesService._();

  static const _collection = 'shared_tackle_images';

  /// Get the shared image URL for a tackle type, if one exists.
  Future<String?> getImageUrl(String tackleTypeName) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_docId(tackleTypeName))
          .get();
      if (doc.exists) {
        final url = doc.data()?['image_url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  /// Upload a user's tackle photo and share it anonymously.
  /// Returns the download URL.
  Future<String?> uploadAndShare(
      String tackleTypeName, String imagePath) async {
    try {
      final file = File(imagePath);
      final ref = FirebaseStorage.instance.ref(
          'shared_tackle/${_sanitize(tackleTypeName)}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_docId(tackleTypeName))
          .set({
        'image_url': url,
        'tackle_type': tackleTypeName,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return url;
    } catch (e) {
      return null;
    }
  }

  /// Check for newly shared images since the last check.
  /// Call periodically (e.g. on catalog open).
  Future<Map<String, String>> checkForNewImages() async {
    final result = <String, String>{};
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final url = data['image_url'] as String?;
        final type = data['tackle_type'] as String?;
        if (url != null && type != null) {
          result[type] = url;
        }
      }
    } catch (_) {}
    return result;
  }

  String _docId(String name) => _sanitize(name);

  String _sanitize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  /// Load cached shared image URLs from local storage.
  Future<Map<String, String>> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final result = <String, String>{};
    for (final key in keys) {
      if (key.startsWith('shared_tackle_')) {
        final type = key.substring('shared_tackle_'.length);
        final url = prefs.getString(key);
        if (url != null) result[type] = url;
      }
    }
    return result;
  }

  /// Cache shared image URLs locally for offline use.
  Future<void> cacheUrls(Map<String, String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in urls.entries) {
      await prefs.setString('shared_tackle_${entry.key}', entry.value);
    }
  }
}
