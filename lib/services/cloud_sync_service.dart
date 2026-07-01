import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catch.dart';
import 'database_service.dart';

/// Cloud sync status
enum SyncStatus { disconnected, syncing, connected, error }

/// Handles Firebase cloud sync with anonymous auth.
/// Gracefully degrades if Firebase isn't configured — never crashes.
class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._();
  CloudSyncService._();

  bool _initialized = false;
  bool _available = false;
  SyncStatus _status = SyncStatus.disconnected;
  String _lastError = '';

  SyncStatus get status => _status;
  String get lastError => _lastError;
  bool get isAvailable => _available;
  bool get isConnected => _available && _status == SyncStatus.connected;

  /// Initialize Firebase. Safe to call even if not configured.
  Future<void> init() async {
    if (!_initialized) {
      _initialized = true;
      try {
        await Firebase.initializeApp();
        _available = true;
      } catch (e) {
        _available = false;
        _status = SyncStatus.disconnected;
        debugPrint('Cloud sync unavailable: $e');
        return;
      }
    }
    // Always try to sign in (or check existing session)
    await _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      _status = SyncStatus.connected;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = 'Auth failed: $e';
    }
  }

  /// Upload all catches to Firestore.
  Future<void> uploadCatches() async {
    if (!_available) return;
    _status = SyncStatus.syncing;
    try {
      final catches = await DatabaseService.instance.getCatches();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not signed in');

      final batch = FirebaseFirestore.instance.batch();
      for (final c in catches) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('catches')
            .doc(c.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString());
        batch.set(ref, {
          ...c.toMap(),
          'synced_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _status = SyncStatus.connected;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = 'Upload failed: $e';
    }
  }

  /// Download catches from Firestore and merge into local DB.
  Future<int> downloadCatches() async {
    if (!_available) return 0;
    _status = SyncStatus.syncing;
    int count = 0;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not signed in');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('catches')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = null; // let local DB assign ID
        final c = Catch.fromMap(data);
        await DatabaseService.instance.addCatch(c);
        count++;
      }
      _status = SyncStatus.connected;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = 'Download failed: $e';
    }
    return count;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _status = SyncStatus.disconnected;
    _initialized = false;
  }
}
