import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages shared fishing sessions via Firestore.
class SessionService {
  static final SessionService instance = SessionService._();
  SessionService._();

  String? _currentSessionCode;

  String? get currentCode => _currentSessionCode;

  /// Generate a short session code like "PIKE-73"
  String _generateCode() {
    const words = ['BASS','PIKE','PERCH','TROUT','WALLEYE','BLUEGILL',
                   'CRAPPIE','MUSKIE','SALMON','CATFISH'];
    final w = words[Random().nextInt(words.length)];
    final n = Random().nextInt(99) + 1;
    return '$w-$n';
  }

  /// Create a new session and return the code.
  Future<String> createSession(String displayName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    // Generate unique code
    String code;
    do {
      code = _generateCode();
      final existing = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .get();
      if (!existing.exists) break;
    } while (true);

    _currentSessionCode = code;

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(code)
        .set({
      'code': code,
      'created_at': FieldValue.serverTimestamp(),
      'active': true,
      'members': {
        uid: {
          'name': displayName,
          'joined_at': FieldValue.serverTimestamp(),
        }
      },
    });

    // Add welcome message
    await _addMessage(code, '${displayName} started fishing! 🎣');

    return code;
  }

  /// Join an existing session by code.
  Future<bool> joinSession(String code, String displayName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final doc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(code.toUpperCase())
        .get();

    if (!doc.exists || doc.data()?['active'] != true) return false;

    _currentSessionCode = code.toUpperCase();

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .update({
      'members.$uid': {
        'name': displayName,
        'joined_at': FieldValue.serverTimestamp(),
      }
    });

    await _addMessage(_currentSessionCode!, '$displayName joined the session!');
    return true;
  }

  /// Leave the current session.
  Future<void> leaveSession() async {
    if (_currentSessionCode == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final name = await _getMyName();
      await _addMessage(_currentSessionCode!, '$name left the session.');
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_currentSessionCode!)
          .update({'members.$uid': FieldValue.delete()});
    }
    _currentSessionCode = null;
  }

  /// Send a chat message.
  Future<void> sendMessage(String text) async {
    if (_currentSessionCode == null) return;
    final name = await _getMyName();
    await _addMessage(_currentSessionCode!, text, senderName: name);
  }

  Future<void> _addMessage(String code, String text, {String? senderName}) async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(code)
        .collection('messages')
        .add({
      'text': text,
      'sender': senderName ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Share a catch to the session feed.
  Future<void> shareCatch(String species, double? weight, double? length, String? location) async {
    if (_currentSessionCode == null) return;
    final name = await _getMyName();
    await _addMessage(_currentSessionCode!,
        '🎣 $name caught a $species${weight != null ? " (${weight}kg)" : ""}${location != null ? " at $location" : ""}');
  }

  /// Get session info stream
  Stream<DocumentSnapshot> sessionStream() {
    if (_currentSessionCode == null) throw Exception('No active session');
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .snapshots();
  }

  /// Get messages stream
  Stream<QuerySnapshot> messagesStream() {
    if (_currentSessionCode == null) throw Exception('No active session');
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get members list from session data
  List<String> getMembers(Map<String, dynamic>? data) {
    if (data == null) return [];
    final members = data['members'] as Map<String, dynamic>?;
    if (members == null) return [];
    return members.entries.map((e) {
      final m = e.value as Map<String, dynamic>;
      return m['name'] as String? ?? 'Unknown';
    }).toList();
  }

  Future<String> _getMyName() async {
    if (_currentSessionCode == null) return 'Someone';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Someone';
    final doc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_currentSessionCode!)
        .get();
    final members = doc.data()?['members'] as Map<String, dynamic>?;
    final me = members?[uid] as Map<String, dynamic>?;
    return me?['name'] as String? ?? 'Someone';
  }
}
