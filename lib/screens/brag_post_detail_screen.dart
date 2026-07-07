import 'package:flutter/material.dart';
import '../services/brag_board_service.dart';
import '../services/auth_service.dart';

/// Detailed view of a brag post with comments.
class BragPostDetailScreen extends StatefulWidget {
  final BragPost post;
  const BragPostDetailScreen({super.key, required this.post});

  @override
  State<BragPostDetailScreen> createState() => _BragPostDetailScreenState();
}

class _BragPostDetailScreenState extends State<BragPostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _replyCtrl = TextEditingController();
  final _service = BragBoardService.instance;
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    await _service.addComment(postId: widget.post.id, text: text);
  }

  Future<void> _addReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _replyToId == null) return;
    _replyCtrl.clear();
    setState(() { _replyToId = null; _replyToName = null; });
    await _service.addComment(postId: widget.post.id, text: text, parentId: _replyToId);
  }

  void _reportComment(BragComment comment) {
    _service.report('comment', comment.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Comment reported. Thank you.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final isOwner = AuthService.instance.user?.uid == post.userId;

    return Scaffold(
      appBar: AppBar(title: Text('${post.userName}\'s Catch')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Photo
                if (post.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(post.photoUrl!, height: 300, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.grey.shade900)),
                  ),
                const SizedBox(height: 16),

                // Species + actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF76FF03).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: Text('🐟 ${post.species}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF76FF03))),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border, color: post.likedByMe ? Colors.red : null),
                      onPressed: () => _service.toggleLike(post.id),
                    ),
                    Text('${post.likesCount}', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),

                // Description
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(post.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                ],

                // More Info
                if (post.moreInfo != null && post.moreInfo!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            const Text('More Info', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(post.moreInfo!, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 32),

                // Comments header
                const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // Comments stream
                StreamBuilder<List<BragComment>>(
                  stream: _service.streamComments(post.id),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snap.data!;
                    // Separate top-level from replies
                    final topLevel = comments.where((c) => c.parentId == null).toList();
                    if (topLevel.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No comments yet. Be the first!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
                      );
                    }
                    return Column(
                      children: topLevel.map((c) => _commentTile(c, comments)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF76FF03)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentTile(BragComment comment, List<BragComment> allComments) {
    final isOwner = AuthService.instance.user?.uid == comment.userId;
    final replies = allComments.where((c) => c.parentId == comment.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The comment itself
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(comment.userName[0].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(width: 8),
                  Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'report') _reportComment(comment);
                      if (v == 'delete' && isOwner) _service.deleteComment(comment.id, comment.userId);
                    },
                    itemBuilder: (_) => [
                      if (isOwner) const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, size: 18), title: Text('Delete', style: TextStyle(fontSize: 13)))),
                      const PopupMenuItem(value: 'report', child: ListTile(leading: Icon(Icons.flag, size: 18), title: Text('Report', style: TextStyle(fontSize: 13)))),
                    ],
                    icon: const Icon(Icons.more_horiz, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.text, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_timeAgo(comment.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToId = comment.id;
                        _replyToName = comment.userName;
                      });
                    },
                    child: Text('Reply', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Reply input if replying to this comment
        if (_replyToId == comment.id)
          Container(
            margin: const EdgeInsets.only(left: 24, bottom: 8),
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF76FF03).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text('@$_replyToName ', style: const TextStyle(fontSize: 12, color: Color(0xFF76FF03))),
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addReply(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 18, color: Color(0xFF76FF03)),
                  onPressed: _addReply,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() { _replyToId = null; _replyToName = null; }),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        // Replies
        ...replies.map((r) => Container(
          margin: const EdgeInsets.only(left: 24, bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'report') _reportComment(r);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'report', child: ListTile(leading: Icon(Icons.flag, size: 16), title: Text('Report', style: TextStyle(fontSize: 12)))),
                    ],
                    icon: const Icon(Icons.more_horiz, size: 14),
                  ),
                ],
              ),
              Text(r.text, style: const TextStyle(fontSize: 13)),
              Text(_timeAgo(r.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        )),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
