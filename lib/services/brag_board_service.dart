import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;
import 'auth_service.dart';

/// A brag post from a user.
class BragPost {
  final String id;
  final String userId;
  final String userName;
  final String species;
  final String description;
  final String? photoUrl;
  final String? photoData; // base64 encoded image (legacy, new posts use photoUrl)
  final String? moreInfo;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

  BragPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.species,
    this.description = '',
    this.photoUrl,
    this.photoData,
    this.moreInfo,
    required this.timestamp,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
  });

  factory BragPost.fromMap(String id, Map<String, dynamic> data, {bool likedByMe = false}) {
    return BragPost(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Angler',
      species: data['species'] as String? ?? 'Unknown',
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoData: data['photoData'] as String?,
      moreInfo: data['moreInfo'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      likedByMe: likedByMe,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'species': species,
    'description': description,
    'photoUrl': photoUrl,
    'photoData': photoData,
    'moreInfo': moreInfo,
    'timestamp': Timestamp.fromDate(timestamp),
    'likesCount': likesCount,
    'commentsCount': commentsCount,
  };
}

/// A comment on a brag post.
class BragComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  final String? parentId;

  BragComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.parentId,
  });

  bool get isReply => parentId != null;

  factory BragComment.fromMap(String id, Map<String, dynamic> data) {
    return BragComment(
      id: id,
      postId: data['postId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Angler',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentId: data['parentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'userId': userId,
    'userName': userName,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'parentId': parentId,
  };
}

/// Service for the Brag Board social feed.
class BragBoardService {
  static final BragBoardService instance = BragBoardService._();
  BragBoardService._();

  final _postsRef = FirebaseFirestore.instance.collection('brag_posts');
  final _commentsRef = FirebaseFirestore.instance.collection('brag_comments');
  final _likesRef = FirebaseFirestore.instance.collection('brag_likes');
  final _reportsRef = FirebaseFirestore.instance.collection('brag_reports');
  final _blocksRef = FirebaseFirestore.instance.collection('brag_blocks');
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Posts ─────────────────────────────────────────────────────

  /// Stream of all posts ordered by newest first.
  Stream<List<BragPost>> streamPosts({int limit = 50}) {
    return _streamPosts(_postsRef.orderBy('timestamp', descending: true), limit: limit);
  }

  /// Stream of posts sorted by hotness (likes + comments, recent first).
  Stream<List<BragPost>> streamHotPosts({int limit = 50, int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _streamPosts(
      _postsRef
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('timestamp', descending: true),
      limit: limit,
      sortBy: (a, b) {
        final scoreA = a.likesCount + a.commentsCount * 2;
        final scoreB = b.likesCount + b.commentsCount * 2;
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return b.timestamp.compareTo(a.timestamp);
      },
    );
  }

  /// Internal stream builder with optional client-side sort.
  Stream<List<BragPost>> _streamPosts(
    Query query, {
    int limit = 50,
    int Function(BragPost a, BragPost b)? sortBy,
  }) {
    final userId = _uid;
    return query
        .limit(limit)
        .snapshots()
        .asyncMap((snap) async {
      final posts = <BragPost>[];
      for (final doc in snap.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
          bool liked = false;
          if (userId != null) {
            final likeDoc = await _likesRef
                .where('postId', isEqualTo: doc.id)
                .where('userId', isEqualTo: userId)
                .get();
            liked = likeDoc.docs.isNotEmpty;
          }
          posts.add(BragPost.fromMap(doc.id, data, likedByMe: liked));
        } catch (e) {
          debugPrint('BragBoardService.streamPosts: error processing post ${doc.id}: $e');
        }
      }
      if (sortBy != null) posts.sort(sortBy);
      return posts;
    }).handleError((e) {
      debugPrint('BragBoardService.streamPosts error: $e');
      return <BragPost>[];
    });
  }

  /// Check if the current user is banned (supports temporary bans).
  Future<bool> _isBanned() async {
    if (_uid == null) return false;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid!).get();
      final data = doc.data();
      if (data == null) return false;
      // Lifetime ban
      if (data['banned'] == true && data['bannedUntil'] == null) return true;
      // Temporary ban — check if expired
      final until = data['bannedUntil'] as Timestamp?;
      if (until != null) {
        if (until.toDate().isAfter(DateTime.now())) return true;
        // Ban expired — auto-unban
        await doc.reference.update({'banned': false, 'bannedUntil': null});
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Upload a new post with photo as base64 in Firestore.
  Future<String?> createPost({
    required XFile photo,
    required String species,
    String description = '',
    String? moreInfo,
  }) async {
    if (_uid == null) return null;
    if (await _isBanned()) {
      debugPrint('BragBoardService: user is banned, cannot post');
      return null;
    }
    try {
      debugPrint('BragBoardService: reading photo bytes...');
      final imageBytes = await photo.readAsBytes();

      // Compress: resize to 1024px max, JPEG quality 70
      final compressed = _compressImage(imageBytes);
      debugPrint('BragBoardService: compressed ${imageBytes.length} -> ${compressed.length} bytes');

      // Encode to base64
      final photoData = base64Encode(compressed);
      debugPrint('BragBoardService: base64 length ${photoData.length}');

      // Use the user's permanent profile name (set at sign-up)
      final userName = AuthService.instance.userName.isNotEmpty
          ? AuthService.instance.userName
          : (_auth.currentUser?.displayName ?? 'Angler');

      // Build doc (compressed to ~45KB base64, well under 1MB Firestore limit)
      final doc = await _postsRef.add({
        'userId': _uid!,
        'userName': userName,
        'species': species,
        'description': description,
        'photoData': photoData,
        'moreInfo': moreInfo,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'likesCount': 0,
        'commentsCount': 0,
      });
      debugPrint('BragBoardService: post created with id: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('BragBoardService.createPost ERROR: $e');
      return null;
    }
  }

  /// Toggle like on a post.
  Future<void> toggleLike(String postId) async {
    if (_uid == null) return;
    try {
      final existing = await _likesRef
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: _uid)
          .get();
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.delete();
        await _postsRef.doc(postId).update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        await _likesRef.add({
          'postId': postId,
          'userId': _uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await _postsRef.doc(postId).update({
          'likesCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('BragBoardService.toggleLike: $e');
    }
  }

  /// Delete a post (owner only).
  Future<bool> deletePost(String postId, String userId) async {
    if (_uid != userId) return false;
    try {
      await _postsRef.doc(postId).delete();
      // Delete comments on this post
      final comments = await _commentsRef.where('postId', isEqualTo: postId).get();
      for (final c in comments.docs) {
        await c.reference.delete();
      }
      // Delete likes on this post
      final likes = await _likesRef.where('postId', isEqualTo: postId).get();
      for (final l in likes.docs) {
        await l.reference.delete();
      }
      return true;
    } catch (e) {
      debugPrint('BragBoardService.deletePost: $e');
      return false;
    }
  }

  // ─── Comments ──────────────────────────────────────────────────

  /// Stream comments for a post, grouped as top-level + replies.
  Stream<List<BragComment>> streamComments(String postId) {
    return _commentsRef
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BragComment.fromMap(d.id, d.data()))
            .toList());
  }

  /// Add a comment or reply.
  Future<bool> addComment({
    required String postId,
    required String text,
    String? parentId,
  }) async {
    if (_uid == null) return false;
    if (await _isBanned()) {
      debugPrint('BragBoardService: user is banned, cannot comment');
      return false;
    }
    try {
      final comment = BragComment(
        id: '',
        postId: postId,
        userId: _uid!,
        userName: _auth.currentUser?.displayName ?? 'Angler',
        text: text,
        timestamp: DateTime.now(),
        parentId: parentId,
      );
      await _commentsRef.add(comment.toMap());
      await _postsRef.doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      debugPrint('BragBoardService.addComment: $e');
      return false;
    }
  }

  /// Delete a comment (owner only).
  Future<bool> deleteComment(String commentId, String userId) async {
    if (_uid != userId) return false;
    try {
      await _commentsRef.doc(commentId).delete();
      return true;
    } catch (e) {
      debugPrint('BragBoardService.deleteComment: $e');
      return false;
    }
  }

  // ─── Reports & Blocks ─────────────────────────────────────────

  /// Report a post or comment.
  Future<void> report(String targetType, String targetId, {String? reason, String? targetUserId}) async {
    if (_uid == null) return;
    try {
      await _reportsRef.add({
        'targetType': targetType,
        'targetId': targetId,
        'targetUserId': targetUserId ?? '',
        'reporterId': _uid,
        'reason': reason ?? 'Inappropriate',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('BragBoardService.report: $e');
    }
  }

  /// Block a user.
  Future<void> blockUser(String blockedId) async {
    if (_uid == null) return;
    try {
      await _blocksRef.add({
        'blockerId': _uid,
        'blockedId': blockedId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('BragBoardService.blockUser: $e');
    }
  }

  /// Check if user has blocked another.
  Future<bool> isBlocked(String userId) async {
    if (_uid == null) return false;
    try {
      final result = await _blocksRef
          .where('blockerId', isEqualTo: _uid)
          .where('blockedId', isEqualTo: userId)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('BragBoardService.isBlocked: $e');
      return false;
    }
  }

  /// Compress image bytes: resize to max 1024px, JPEG quality 70.
  static Uint8List _compressImage(Uint8List bytes) {
    final decoded = img_lib.decodeImage(bytes);
    if (decoded == null) return bytes;

    img_lib.Image resized;
    if (decoded.width > 1024 || decoded.height > 1024) {
      final scale = 1024.0 /
          (decoded.width > decoded.height ? decoded.width : decoded.height);
      resized = img_lib.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    } else {
      resized = decoded;
    }

    return Uint8List.fromList(img_lib.encodeJpg(resized, quality: 70));
  }

  /// Pick image from gallery with compression to fit Firestore.
  static Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
  }
}
