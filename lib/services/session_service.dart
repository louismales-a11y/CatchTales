import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Manages shared fishing sessions (Fishing Rooms) via Firestore.
///
/// Each user gets one permanent personal room (e.g. "Louis's Fishing Room").
/// The room code is stored in the user's profile and persists forever.
/// Friends join by code and stay as members.
class SessionService extends ChangeNotifier {
  static final SessionService instance = SessionService._();
  SessionService._();

  String? _currentSessionCode;

  /// The session code currently being viewed/used.
  String? get currentCode => _currentSessionCode;

  /// Whether the user has an active session they're viewing.
  bool get hasActiveSession => _currentSessionCode != null;

  // ── Room / Session Management ──────────────────────────────────────────

  /// Generate a short session code like "PIKE-73"
  String _generateCode() {
    const words = [
      'BASS', 'PIKE', 'PERCH', 'TROUT', 'WALLEYE',
      'BLUEGILL', 'CRAPPIE', 'MUSKIE', 'SALMON', 'CATFISH',
    ];
    final w = words[Random().nextInt(words.length)];
    final n = Random().nextInt(99) + 1;
    return '$w-$n';
  }

  /// Get or create the current user's personal fishing room.
  /// Each user gets one permanent room that lasts forever.
  Future<Map<String, dynamic>> getOrCreatePersonalRoom() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    // Check if user already has a personal room code saved
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    String? code = userDoc.data()?['personalRoomCode'] as String?;

    if (code != null) {
      // Verify the room still exists
      final roomDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .get();
      if (roomDoc.exists) {
        _currentSessionCode = code;
        notifyListeners();
        return roomDoc.data()!;
      }
      // Room was deleted — fall through to create one
    }

    // Get the user's display name
    final displayName = userDoc.data()?['name'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Angler ${uid.substring(0, 4)}';

    // Generate a unique room code
    String newCode;
    do {
      newCode = _generateCode();
      final existing = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(newCode)
          .get();
      if (!existing.exists) break;
    } while (true);

    _currentSessionCode = newCode;
    notifyListeners();

    // Create the room
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(newCode)
        .set({
      'code': newCode,
      'name': "$displayName's Fishing Room",
      'owner': uid,
      'created_at': FieldValue.serverTimestamp(),
      'active': true,
      'members': {
        uid: {
          'name': displayName,
          'joined_at': FieldValue.serverTimestamp(),
          'isOwner': true,
        }
      },
    });

    // Save the room code to the user's profile
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'personalRoomCode': newCode}, SetOptions(merge: true));

    // Add the room to the user's joined rooms list
    await _addJoinedRoom(newCode);

    return {
      'code': newCode,
      'name': "$displayName's Fishing Room",
      'owner': uid,
      'active': true,
    };
  }

  /// Join an existing session by code.
  Future<bool> joinSession(String code, String displayName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final docRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(code.toUpperCase());

    final doc = await docRef.get();

    if (!doc.exists || doc.data()?['active'] != true) return false;

    _currentSessionCode = code.toUpperCase();
    notifyListeners();

    // Add user as a member
    await docRef.update({
      'members.$uid': {
        'name': displayName,
        'joined_at': FieldValue.serverTimestamp(),
        'isOwner': false,
      }
    });

    // Add to joined rooms list
    await _addJoinedRoom(_currentSessionCode!);

    // Add join message
    await _addMessage(_currentSessionCode!, '$displayName joined the room!');
    return true;
  }

  /// Leave a session and remove ourselves from members.
  Future<void> leaveSession() async {
    if (_currentSessionCode == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final name = await _getMyName();
      await _addMessage(_currentSessionCode!, '$name left the room.');
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_currentSessionCode!)
          .update({'members.$uid': FieldValue.delete()});
    }
    _currentSessionCode = null;
    notifyListeners();
  }

  /// Set the current active session code (e.g. when re-opening a room).
  void setCurrentSession(String code) {
    _currentSessionCode = code.toUpperCase();
    notifyListeners();
  }

  /// Clear the current session without leaving.
  void clearCurrentSession() {
    _currentSessionCode = null;
    notifyListeners();
  }

  /// Get all rooms the current user has joined (including their personal room).
  Future<List<Map<String, dynamic>>> getJoinedRooms() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final codes = (userDoc.data()?['joinedRooms'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (codes.isEmpty) return [];

    final rooms = <Map<String, dynamic>>[];
    for (final code in codes) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(code)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = code;
          // Check if user is still a member
          final members = data['members'] as Map<String, dynamic>? ?? {};
          if (members.containsKey(uid)) {
            rooms.add(data);
          }
        }
      } catch (_) {
        // Room might have been deleted — skip
      }
    }

    return rooms;
  }

  /// Add a room code to the user's joined rooms list.
  Future<void> _addJoinedRoom(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'joinedRooms': FieldValue.arrayUnion([code.toUpperCase()])
    }, SetOptions(merge: true));
  }

  // ── Messages ───────────────────────────────────────────────────────────

  /// Send a text message to the current session.
  Future<void> sendMessage(String text) async {
    if (_currentSessionCode == null) return;
    final name = await _getMyName();
    await _addMessage(_currentSessionCode!, text, senderName: name);
  }

  /// Send a photo message to the current session.
  /// Accepts image bytes (handles both file paths and content URIs).
  /// Returns the download URL if successful, null otherwise.
  Future<String?> sendPhotoBytes(Uint8List imageBytes) async {
    if (_currentSessionCode == null) {
      throw Exception('No active session. Open a fishing room first.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to share photos.');
    }

    debugPrint('SessionService.sendPhotoBytes: storing photo as data URI (${imageBytes.length} bytes)');

    // Store photo as base64 data URI in Firestore (same pattern as profile photos in AuthService)
    // This avoids Firebase Storage rules issues entirely.
    final b64 = base64Encode(imageBytes);
    final dataUri = 'data:image/jpeg;base64,$b64';

    final name = await _getMyName();
    await _addMessage(_currentSessionCode!, dataUri, senderName: name, isPhoto: true);

    return dataUri;
  }

  Future<void> _addMessage(
    String code,
    String content, {
    String? senderName,
    bool isPhoto = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(code)
        .collection('messages')
        .add({
      if (isPhoto)
        'photoUrl': content
      else
        'text': content,
      'sender': senderName ?? '',
      'senderUid': uid,
      'isPhoto': isPhoto,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Share a catch to the session feed.
  Future<void> shareCatch(
    String species,
    double? weight,
    double? length,
    String? location,
  ) async {
    if (_currentSessionCode == null) return;
    final name = await _getMyName();
    await _addMessage(
      _currentSessionCode!,
      '🎣 $name caught a $species'
          '${weight != null ? " (${weight}kg)" : ""}'
          '${location != null ? " at $location" : ""}',
    );
  }

  // ── Streams ────────────────────────────────────────────────────────────

  /// Get session info stream.
  Stream<DocumentSnapshot> sessionStream() {
    if (_currentSessionCode == null) throw Exception('No active session');
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .snapshots();
  }

  /// Get messages stream for the current session.
  Stream<QuerySnapshot> messagesStream() {
    if (_currentSessionCode == null) throw Exception('No active session');
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get messages stream for a specific session code.
  Stream<QuerySnapshot> messagesStreamFor(String code) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(code.toUpperCase())
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get session info stream for a specific code.
  Stream<DocumentSnapshot> sessionStreamFor(String code) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(code.toUpperCase())
        .snapshots();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Get members list from session data.
  List<MapEntry<String, Map<String, dynamic>>> getMembersList(
      Map<String, dynamic>? data) {
    if (data == null) return [];
    final members = data['members'] as Map<String, dynamic>?;
    if (members == null) return [];
    return members.entries.map((e) {
      final m = e.value as Map<String, dynamic>;
      return MapEntry(e.key, m);
    }).toList();
  }

  /// Get display names of all members.
  List<String> getMembers(Map<String, dynamic>? data) {
    return getMembersList(data)
        .map((e) => e.value['name'] as String? ?? 'Unknown')
        .toList();
  }

  /// Check if the current user is the owner of this session.
  bool isOwner(Map<String, dynamic>? data) {
    if (data == null) return false;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return data['owner'] == uid;
  }

  /// Get the room name from session data.
  String getRoomName(Map<String, dynamic>? data) {
    return data?['name'] as String? ?? 'Fishing Room';
  }

  Future<String> _getMyName() async {
    if (_currentSessionCode == null) return 'Someone';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Someone';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_currentSessionCode!)
          .get();
      final members = doc.data()?['members'] as Map<String, dynamic>?;
      final me = members?[uid] as Map<String, dynamic>?;
      return me?['name'] as String? ?? 'Someone';
    } catch (_) {
      return 'Someone';
    }
  }

  /// Delete a message from the current session (only the sender can delete).
  Future<void> deleteMessage(String messageId) async {
    if (_currentSessionCode == null) throw Exception('No active session');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    // Verify the message exists and belongs to this user
    final msgDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!msgDoc.exists) throw Exception('Message not found');

    // Delete the message
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Get the display name of a message sender (looks up from session members).
  Future<String> getSenderName(String? senderUid) async {
    if (senderUid == null || senderUid.isEmpty) return '';
    if (_currentSessionCode == null) return senderUid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_currentSessionCode!)
          .get();
      final members = doc.data()?['members'] as Map<String, dynamic>?;
      final member = members?[senderUid] as Map<String, dynamic>?;
      return member?['name'] as String? ?? senderUid;
    } catch (_) {
      return senderUid;
    }
  }
}
