import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// Admin panel for managing brag board reports (dev build only).
class BragAdminScreen extends StatefulWidget {
  const BragAdminScreen({super.key});

  @override
  State<BragAdminScreen> createState() => _BragAdminScreenState();
}

class _BragAdminScreenState extends State<BragAdminScreen> {
  final _reportsRef = FirebaseFirestore.instance.collection('brag_reports');
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _postsRef = FirebaseFirestore.instance.collection('brag_posts');
  final _commentsRef = FirebaseFirestore.instance.collection('brag_comments');

  bool _showDismissed = false;

  Future<String?> _getUserName(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _usersRef.doc(userId).get();
      return doc.data()?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<int> _getReportCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final snap = await _reportsRef.where('targetUserId', isEqualTo: userId).get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _isCurrentlyBanned(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      final data = doc.data();
      if (data == null) return false;
      if (data['banned'] == true) return true; // lifetime
      final until = data['bannedUntil'] as Timestamp?;
      if (until != null && until.toDate().isAfter(DateTime.now())) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Delete this post permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await _postsRef.doc(postId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Delete this comment permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await _commentsRef.doc(commentId).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment deleted')));
  }

  Future<void> _warnUser(String userId, String userName) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warn User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send warning to $userName'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Warning message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Send Warning')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    await _usersRef.doc(userId).collection('warnings').add({
      'message': reason,
      'issuedAt': FieldValue.serverTimestamp(),
      'issuedBy': AuthService.instance.user?.uid ?? 'admin',
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning sent')));
  }

  Future<void> _banUser(String userId, String userName) async {
    // Choose ban duration
    final duration = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ban $userName for:'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx, '48h'), child: const Text('48 Hours')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx, '7d'), child: const Text('7 Days')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx, '30d'), child: const Text('30 Days')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, 'lifetime'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                child: const Text('Lifetime (Permanent)'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    if (duration == null) return;

    final data = <String, dynamic>{
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': AuthService.instance.user?.uid ?? 'admin',
    };

    if (duration == 'lifetime') {
      data['banned'] = true;
      data['bannedUntil'] = null;
    } else {
      data['banned'] = true;
      final hours = int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 48;
      data['bannedUntil'] = Timestamp.fromDate(
        DateTime.now().add(Duration(hours: duration.contains('d') ? hours * 24 : hours)),
      );
    }

    await _usersRef.doc(userId).set(data, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName banned ${duration == 'lifetime' ? 'permanently' : 'for $duration'}')),
      );
    }
  }

  Future<void> _unbanUser(String userId, String userName) async {
    await _usersRef.doc(userId).set(
      {'banned': false, 'bannedUntil': null, 'unbannedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName unbanned')));
  }

  Future<void> _dismissReport(String reportId) async {
    await _reportsRef.doc(reportId).update({
      'status': 'dismissed',
      'dismissedAt': FieldValue.serverTimestamp(),
      'dismissedBy': AuthService.instance.user?.uid ?? 'admin',
    });
  }

  Future<void> _reactivateReport(String reportId) async {
    await _reportsRef.doc(reportId).update({
      'status': 'active',
      'dismissedAt': null,
      'dismissedBy': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brag Board Admin'),
        actions: [
          // Toggle dismissed
          StreamBuilder<QuerySnapshot>(
            stream: _reportsRef.orderBy('timestamp', descending: true).snapshots(),
            builder: (ctx, snap) {
              final active = snap.data?.docs.where((d) => (d.data() as Map)?['status'] != 'dismissed').length ?? 0;
              final total = snap.data?.docs.length ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: active > 0 ? Colors.red.shade700 : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$active active', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$total total', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _showDismissed = !_showDismissed),
                      child: Icon(
                        _showDismissed ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: _showDismissed ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var reports = snap.data!.docs;

          // Filter dismissed
          if (!_showDismissed) {
            reports = reports.where((d) {
              final data = d.data() as Map<String, dynamic>?;
              return data?['status'] != 'dismissed';
            }).toList();
          }

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('The community is behaving!', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final data = reports[i].data() as Map<String, dynamic>;
              final isDismissed = data['status'] == 'dismissed';
              return Opacity(
                opacity: isDismissed ? 0.5 : 1.0,
                child: _ReportCard(
                  key: ValueKey(reports[i].id),
                  report: data,
                  reportId: reports[i].id,
                  isDismissed: isDismissed,
                  onDeletePost: () => _deletePost(data['targetId'] as String),
                  onDeleteComment: () => _deleteComment(data['targetId'] as String),
                  onWarn: (uid, name) => _warnUser(uid, name),
                  onBan: (uid, name) => _banUser(uid, name),
                  onUnban: (uid, name) => _unbanUser(uid, name),
                  onDismiss: () => _dismissReport(reports[i].id),
                  onReactivate: () => _reactivateReport(reports[i].id),
                  getUserName: _getUserName,
                  getReportCount: _getReportCount,
                  isBanned: _isCurrentlyBanned,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final String reportId;
  final bool isDismissed;
  final VoidCallback onDeletePost;
  final VoidCallback onDeleteComment;
  final Future<void> Function(String uid, String name) onWarn;
  final Future<void> Function(String uid, String name) onBan;
  final Future<void> Function(String uid, String name) onUnban;
  final VoidCallback onDismiss;
  final VoidCallback onReactivate;
  final Future<String?> Function(String uid) getUserName;
  final Future<int> Function(String uid) getReportCount;
  final Future<bool> Function(String uid) isBanned;

  const _ReportCard({
    super.key,
    required this.report,
    required this.reportId,
    required this.isDismissed,
    required this.onDeletePost,
    required this.onDeleteComment,
    required this.onWarn,
    required this.onBan,
    required this.onUnban,
    required this.onDismiss,
    required this.onReactivate,
    required this.getUserName,
    required this.getReportCount,
    required this.isBanned,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  int? _reportCount;
  bool? _banned;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final targetUserId = widget.report['targetUserId'] as String? ?? '';
    if (targetUserId.isEmpty) return;
    final results = await Future.wait([
      widget.getReportCount(targetUserId),
      widget.isBanned(targetUserId),
    ]);
    if (mounted) setState(() {
      _reportCount = results[0] as int?;
      _banned = results[1] as bool?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = widget.report;
    final targetType = report['targetType'] as String? ?? 'unknown';
    final targetId = report['targetId'] as String? ?? '';
    final targetUserId = report['targetUserId'] as String? ?? '';
    final reason = report['reason'] as String? ?? 'Not specified';
    final reporterId = report['reporterId'] as String? ?? 'anonymous';
    final ts = (report['timestamp'] as Timestamp?)?.toDate();

    return FutureBuilder<String?>(
      future: targetUserId.isNotEmpty ? widget.getUserName(targetUserId) : Future.value(null),
      builder: (ctx, nameSnap) {
        final userName = nameSnap.data ?? 'Unknown';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: widget.isDismissed ? Colors.grey.shade900 : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: targetType == 'post' ? Colors.orange.shade700 : Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(targetType.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    if (widget.isDismissed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(8)),
                        child: const Text('DISMISSED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (_banned == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)),
                        child: const Text('BANNED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const Spacer(),
                    Text('ID: ${targetId.length > 12 ? '${targetId.substring(0, 12)}...' : targetId}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),

                // User + report count
                if (targetUserId.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('$userName ($targetUserId)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      ),
                      if (_reportCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _reportCount! > 1 ? Colors.red.shade800.withValues(alpha: 0.5) : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${_reportCount}x reported',
                              style: TextStyle(fontSize: 10, color: _reportCount! > 1 ? Colors.red.shade200 : Colors.grey.shade400)),
                        ),
                    ],
                  ),
                const SizedBox(height: 6),

                // Reason
                Row(
                  children: [
                    Icon(Icons.flag, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(reason, style: TextStyle(fontSize: 13, color: Colors.red.shade300, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Time + reporter
                Text(
                  '${ts != null ? _formatDate(ts) : 'unknown'} • reporter: ${reporterId.length > 8 ? '${reporterId.substring(0, 8)}...' : reporterId}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                // Actions
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (targetType == 'post')
                      ActionChip(
                        avatar: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete Post', style: TextStyle(fontSize: 12)),
                        onPressed: widget.onDeletePost,
                        backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
                        side: BorderSide(color: Colors.red.shade700),
                      ),
                    if (targetType == 'comment')
                      ActionChip(
                        avatar: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete Comment', style: TextStyle(fontSize: 12)),
                        onPressed: widget.onDeleteComment,
                        backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
                        side: BorderSide(color: Colors.red.shade700),
                      ),
                    if (targetUserId.isNotEmpty) ...[
                      ActionChip(
                        avatar: const Icon(Icons.warning_amber_outlined, size: 16),
                        label: const Text('Warn', style: TextStyle(fontSize: 12)),
                        onPressed: () => widget.onWarn(targetUserId, userName),
                        backgroundColor: Colors.orange.shade900.withValues(alpha: 0.3),
                        side: BorderSide(color: Colors.orange.shade700),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.block, size: 16),
                        label: Text(_banned == true ? 'Unban' : 'Ban', style: TextStyle(fontSize: 12)),
                        onPressed: _banned == true
                            ? () async { await widget.onUnban(targetUserId, userName); if (mounted) _loadMeta(); }
                            : () async { await widget.onBan(targetUserId, userName); if (mounted) _loadMeta(); },
                        backgroundColor: _banned == true ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.red.shade900.withValues(alpha: 0.3),
                        side: BorderSide(color: _banned == true ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                    ],
                    // Dismiss / Reactivate
                    ActionChip(
                      avatar: Icon(widget.isDismissed ? Icons.undo : Icons.check, size: 16),
                      label: Text(widget.isDismissed ? 'Reactivate' : 'Dismiss', style: TextStyle(fontSize: 12)),
                      onPressed: widget.isDismissed ? widget.onReactivate : widget.onDismiss,
                      backgroundColor: widget.isDismissed ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.grey.shade800,
                      side: BorderSide(color: widget.isDismissed ? Colors.blue.shade700 : Colors.grey.shade600),
                    ),
                    if (targetUserId.isEmpty)
                      Text('No user info', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
