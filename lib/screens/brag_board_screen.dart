import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/brag_board_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../widgets/water_background.dart';
import '../widgets/brag_image.dart';
import 'brag_post_detail_screen.dart';
import 'edit_brag_post_screen.dart';
import 'new_brag_post_screen.dart';

/// Main feed showing all brag posts.
class BragBoardScreen extends StatefulWidget {
  const BragBoardScreen({super.key});

  @override
  State<BragBoardScreen> createState() => _BragBoardScreenState();
}

class _BragBoardScreenState extends State<BragBoardScreen> {
  final _service = BragBoardService.instance;
  final _listKey = GlobalKey();
  int _refreshCounter = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshCounter++);
  }

  void _showPostMenu(BragPost post) {
    final auth = AuthService.instance;
    final isOwner = auth.user?.uid == post.userId ||
        (auth.userName.isNotEmpty && auth.userName == post.userName);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF76FF03)),
                title: const Text('Edit Post'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final edited = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditBragPostScreen(
                        postId: post.id,
                        userId: post.userId,
                        userName: post.userName,
                        initialSpecies: post.species,
                        initialDescription: post.description,
                        initialMoreInfo: post.moreInfo,
                        initialPhotoData: post.photoData,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(post);
                },
              ),
            ],
            if (!isOwner) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.report('post', post.id, reason: 'Inappropriate', targetUserId: post.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Reported. Thank you.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(ctx);
                  _service.blockUser(post.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(behavior: SnackBarBehavior.floating, content: Text('User blocked.')),
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BragPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deletePost(post.id, post.userId, postUserName: post.userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Brag Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Share your catch',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewBragPostScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<BragPost>>(
        stream: _service.streamPosts(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text('Something went wrong\n${snap.error}', textAlign: TextAlign.center));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data!;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.set_meal, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No brags yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54)),
                  const SizedBox(height: 8),
                  const Text('Be the first to share your catch.', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewBragPostScreen())),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Share Your Catch'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            displacement: 40,
            color: const Color(0xFF76FF03),
            child: ListView.builder(
              key: ValueKey('brag_list_$_refreshCounter'),
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (ctx, i) => _PostCard(post: posts[i], onMenu: () => _showPostMenu(posts[i])),
            ),
          );
        },
      ),
    );
  }
}

/// A single post card in the feed.
class _PostCard extends StatelessWidget {
  final BragPost post;
  final VoidCallback onMenu;

  const _PostCard({required this.post, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BragPostDetailScreen(post: post))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    backgroundImage: AuthService.imageProviderFor(post.profilePhotoUrl),
                    child: post.profilePhotoUrl.isEmpty
                        ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                            style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(_formatDate(post.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: onMenu,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Photo
            BragImage(post: post, height: 280),
            // Species tag
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF76FF03).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🐟 ${post.species}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF76FF03))),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(post.description, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border, color: post.likedByMe ? Colors.red : null, size: 20),
                    onPressed: () => BragBoardService.instance.toggleLike(post.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('${post.likesCount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  if (post.moreInfo != null)
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ),
            // Report link
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    BragBoardService.instance.report('post', post.id, reason: 'Inappropriate', targetUserId: post.userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Report submitted. Thank you.')),
                    );
                  },
                  child: Text('Report', style: TextStyle(color: Colors.red.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
