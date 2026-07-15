import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/translation_service.dart';

/// Main entry point for Fish Together.
/// Shows the list of fishing rooms (personal + joined).
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _s = SessionService.instance;
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await _s.getJoinedRooms();

      // Ensure personal room exists
      try {
        await _s.getOrCreatePersonalRoom();
      } catch (e) {
        // User might not be signed in
      }

      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load rooms. Please try again.';
      });
    }
  }

  Future<void> _joinRoomByCode() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    // Pre-fill name
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      nameCtrl.text = userDoc.data()?['name'] as String? ?? '';
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add, size: 22),
            SizedBox(width: 8),
            Text('Join a Fishing Room'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Room code',
                hintText: 'e.g. PIKE-73',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final code = codeCtrl.text.trim().toUpperCase();
    final name = nameCtrl.text.trim();
    if (code.isEmpty || name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Please enter your name and a room code'),
          ),
        );
      }
      return;
    }

    try {
      final ok = await _s.joinSession(code, name);
      if (mounted) {
        if (ok) {
          // Re-open dashboard
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDashboard(code: code),
            ),
          );
          // Refresh rooms list when coming back
          _loadRooms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Room not found or is no longer active'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  void _openRoom(String code) async {
    _s.setCurrentSession(code);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDashboard(code: code),
      ),
    );
    // Refresh rooms when coming back
    _loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.groups, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Fish Together'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Join a room by code',
            onPressed: _joinRoomByCode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh rooms',
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _loadRooms,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No fishing rooms yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your personal room or join a friend\'s',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () async {
                              try {
                                await _s.getOrCreatePersonalRoom();
                                _loadRooms();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text('Error: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_circle, size: 18),
                            label: const Text('Create My Fishing Room'),
                          ),
                        ],
                      ),
                    )
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _rooms.length,
                            itemBuilder: (ctx, i) {
                              final room = _rooms[i];
                              final code = room['code'] as String? ?? '';
                              final name = room['name'] as String? ?? 'Fishing Room';
                              final members = _s.getMembers(room);
                              final isOwner = _s.isOwner(room);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isOwner
                                        ? Colors.amber.shade100
                                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      isOwner ? Icons.star : Icons.groups,
                                      color: isOwner ? Colors.amber.shade700 : theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (isOwner)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Owner',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Code: $code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        members.isEmpty
                                            ? 'No members yet'
                                            : '${members.length} member${members.length == 1 ? '' : 's'}: ${members.join(', ')}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.copy, size: 18, color: Colors.grey.shade400),
                                        tooltip: 'Copy room code',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              behavior: SnackBarBehavior.floating,
                                              content: Text('Room code copied!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      const Icon(Icons.chevron_right, size: 20),
                                    ],
                                  ),
                                  onTap: () => _openRoom(code),
                                ),
                              );
                            },
                          ),
                        ),
    );
  }
}

// ─── Session Dashboard ──────────────────────────────────────────────────────

/// Real-time session dashboard with chat, photo sharing, and member list.
class SessionDashboard extends StatefulWidget {
  final String code;
  const SessionDashboard({super.key, required this.code});

  @override
  State<SessionDashboard> createState() => _SessionDashboardState();
}

class _SessionDashboardState extends State<SessionDashboard>
    with WidgetsBindingObserver {
  final _s = SessionService.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  // Track last seen message timestamp for notification sounds
  Timestamp? _lastSeenTimestamp;
  bool _isAtBottom = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _s.setCurrentSession(widget.code);
    NotificationService.instance.requestPermissionIfNeeded(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from background, refresh
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    _msgCtrl.clear();
    await _s.sendMessage(t);
    _scrollToBottom();
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;

      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
          content: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Uploading photo...'),
            ],
          ),
        ),
      );

      final bytes = await picked.readAsBytes();
      final url = await _s.sendPhotoBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              content: Text('Photo sent!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Failed to upload photo. Try again.'),
            ),
          );
        }
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('SessionScreen._pickAndSendPhoto error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Photo failed: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text('You can rejoin anytime using the room code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _s.leaveSession();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Please enable location services'),
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Location permission needed to share your position'),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _s.sendMessage(
        '📍 My location: ${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Location sent to room!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not get location: $e'),
          ),
        );
      }
    }
  }

  Future<void> _sendEmergency() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Please enable location services'),
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Location permission needed for emergency alerts'),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final lat = pos.latitude.toStringAsFixed(5);
      final lng = pos.longitude.toStringAsFixed(5);
      await _s.sendMessage('🚨 EMERGENCY! I\'m at $lat,$lng — need help!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Emergency alert sent! 🚨'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not send location: $e'),
          ),
        );
      }
    }
  }

  /// Called when new messages arrive — play notification sound if not at bottom.
  void _onMessagesUpdated(List<QueryDocumentSnapshot> messages) {
    if (messages.isEmpty) return;

    final latest = messages.first.data() as Map<String, dynamic>;
    final ts = latest['timestamp'] as Timestamp?;

    // Only notify about messages from other people
    final sender = latest['sender'] as String? ?? '';
    final isPhoto = latest['isPhoto'] == true;
    final text = latest['text'] as String? ?? '';

    // Build notification body
    final body = isPhoto ? '📷 $sender shared a photo' : text;

    // Play notification sound for new messages from others
    if (_lastSeenTimestamp != null &&
        ts != null &&
        ts.millisecondsSinceEpoch > _lastSeenTimestamp!.millisecondsSinceEpoch) {
      if (sender.isNotEmpty) {
        LocalNotificationService.instance.showSessionNotification(
          title: widget.code,
          body: body,
          payload: 'session_${widget.code}',
        );
      }
    }

    _lastSeenTimestamp = ts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Confirm minimize instead of leaving
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Minimize Room?'),
            content: const Text(
              'The room stays active in the background. '
              'You can come back from the Fishing Rooms list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Minimize'),
              ),
            ],
          ),
        );
        if (result == true && mounted) {
          _s.clearCurrentSession();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<DocumentSnapshot>(
            stream: _s.sessionStreamFor(widget.code),
            builder: (ctx, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final roomName = _s.getRoomName(data);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(roomName, style: const TextStyle(fontSize: 16)),
                  Text(
                    widget.code,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            StreamBuilder<DocumentSnapshot>(
              stream: _s.sessionStreamFor(widget.code),
              builder: (ctx, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final members = _s.getMembers(data);
                return PopupMenuButton<String>(
                  icon: Badge(
                    label: Text('${members.length}'),
                    child: const Icon(Icons.people),
                  ),
                  onSelected: (v) {
                    switch (v) {
                      case 'members':
                        _showMembers(context, data);
                        break;
                      case 'copy_code':
                        Clipboard.setData(ClipboardData(text: widget.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Room code copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        break;
                      case 'leave':
                        _leave();
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'members',
                      child: ListTile(
                        leading: const Icon(Icons.people, size: 20),
                        title: Text('Members (${members.length})'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_code',
                      child: ListTile(
                        leading: const Icon(Icons.copy, size: 20),
                        title: const Text('Copy Room Code'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, size: 20, color: Colors.red.shade300),
                        title: Text('Leave Room', style: TextStyle(color: Colors.red.shade300)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Members bar
            StreamBuilder<DocumentSnapshot>(
              stream: _s.sessionStreamFor(widget.code),
              builder: (ctx, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final members = _s.getMembers(data);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          members.isEmpty
                              ? 'Waiting for others...'
                              : members.join(' — '),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _s.messagesStreamFor(widget.code),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snap.data!.docs;

                  // Detect new messages for notification sound
                  _onMessagesUpdated(msgs);

                  if (msgs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No messages yet',
                              style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            'Share your first catch or say hello!',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification) {
                        setState(() {
                          _isAtBottom = _scrollCtrl.position.pixels <= 50;
                        });
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: msgs.length,
                      itemBuilder: (ctx, i) {
                        final d = msgs[i].data() as Map<String, dynamic>;
                        final text = d['text'] as String? ?? '';
                        final photoUrl = d['photoUrl'] as String? ?? '';
                        final sender = d['sender'] as String? ?? '';
                        final isPhoto = d['isPhoto'] == true;
                        final isCatch = text.contains('🎣');
                        final isEmergency = text.contains('🚨');

                        return _MessageBubble(
                          text: text,
                          photoUrl: photoUrl,
                          sender: sender,
                          isPhoto: isPhoto,
                          isCatch: isCatch,
                          isEmergency: isEmergency,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            // Unread indicator
            if (!_isAtBottom)
              Container(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _scrollToBottom,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('New messages'),
                ),
              ),
            // Chat input
            Container(
              padding: EdgeInsets.fromLTRB(
                  8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  // Photo picker button
                  IconButton(
                    icon: Icon(Icons.photo_camera,
                        color: theme.colorScheme.primary),
                    tooltip: 'Share a photo',
                    onPressed: _pickAndSendPhoto,
                  ),
                  const SizedBox(width: 4),
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: tr('typeMessage'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Location button
                  IconButton(
                    icon: Icon(Icons.my_location,
                        size: 20, color: Colors.grey.shade400),
                    tooltip: 'Share location',
                    onPressed: _sendLocation,
                  ),
                  const SizedBox(width: 4),
                  // Emergency button
                  IconButton(
                    icon: const Icon(Icons.warning_amber,
                        size: 20, color: Colors.red),
                    tooltip: 'Emergency — send alert with location',
                    onPressed: _sendEmergency,
                  ),
                  const SizedBox(width: 4),
                  // Send button
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembers(BuildContext context, Map<String, dynamic>? data) {
    final members = _s.getMembersList(data);
    final ownerUid = data?['owner'] as String? ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Members (${members.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...members.map((entry) {
                  final isOwner = entry.key == ownerUid;
                  final isMe = entry.key == uid;
                  final name = entry.value['name'] as String? ?? 'Unknown';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOwner
                          ? Colors.amber.shade100
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                      child: Icon(
                        isOwner ? Icons.star : Icons.person,
                        color: isOwner
                            ? Colors.amber.shade700
                            : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(name,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                            )),
                        if (isMe)
                          Text(' (you)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    trailing: isOwner
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Owner',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                )),
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final String photoUrl;
  final String sender;
  final bool isPhoto;
  final bool isCatch;
  final bool isEmergency;

  const _MessageBubble({
    required this.text,
    required this.photoUrl,
    required this.sender,
    required this.isPhoto,
    required this.isCatch,
    required this.isEmergency,
  });

  Future<void> _openDirections(String lat, String lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(Uri.parse('geo:$lat,$lng'),
            mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _viewPhoto(BuildContext context, String url) {
    final imageWidget = _buildPhotoWidget(url, fit: BoxFit.contain);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(sender.isNotEmpty ? sender : 'Photo'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        if (comma < 0) return const Icon(Icons.broken_image, size: 40);
        final b64 = url.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: fit);
      } catch (e) {
        debugPrint('_MessageBubble._buildPhotoWidget: $e');
        return const Icon(Icons.broken_image, size: 40);
      }
    }
    return Image.network(url, fit: fit);
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = sender.isEmpty;
    final theme = Theme.of(context);

    Color? bgColor;
    if (isEmergency) {
      bgColor = Colors.red.shade50;
    } else if (isCatch) {
      bgColor = Colors.green.shade50;
    } else if (isPhoto) {
      bgColor = Colors.blue.shade50;
    }

    Color? borderColor;
    if (isEmergency) {
      borderColor = Colors.red.shade200;
    } else if (isCatch) {
      borderColor = Colors.green.shade200;
    } else if (isPhoto) {
      borderColor = Colors.blue.shade200;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor!),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSystem && !isCatch && !isEmergency) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: isSystem
                  ? Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sender.isNotEmpty && !isCatch && !isEmergency)
                          Text(
                            sender,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (isPhoto && photoUrl.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _viewPhoto(context, photoUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 200,
                                height: 200,
                                child: _buildPhotoWidget(photoUrl, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (text.isNotEmpty)
                            Text(
                              text,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ] else if (isPhoto) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              final locMatch = RegExp(r'([\d.]+),([-\d.]+)')
                                  .firstMatch(text);
                              if (locMatch != null) {
                                _openDirections(
                                  locMatch.group(1)!,
                                  locMatch.group(2)!,
                                );
                              }
                            },
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: isCatch ? 14 : 15,
                                fontWeight:
                                    isCatch ? FontWeight.w500 : null,
                                decoration: text.contains(',')
                                    ? TextDecoration.underline
                                    : null,
                                color: text.contains(',')
                                    ? Colors.blue
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
