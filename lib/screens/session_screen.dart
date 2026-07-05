import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _s = SessionService.instance;
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _creating = false;
  bool _joining = false;
  bool _showJoin = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Firebase if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      _nameCtrl.text = 'Angler ${user.uid.substring(0, 4)}';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      if (mounted) {
        NotificationService.instance.requestPermissionIfNeeded(context);
      }
      final code = await _s.createSession(name);
      if (mounted) {
        setState(() => _creating = false);
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => _SessionDashboard(code: code)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    if (code.isEmpty || name.isEmpty) return;
    setState(() => _joining = true);
    try {
      final ok = await _s.joinSession(code, name);
      if (mounted) {
        setState(() => _joining = false);
        if (ok) {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => _SessionDashboard(code: code)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session not found or expired'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Fishing Session')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!_showJoin) ...[
            // Create session
            Icon(Icons.groups, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Fish Together', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'e.g. Louis',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: _creating ? null : _create,
                icon: _creating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_circle),
                label: const Text('Start a Session'),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showJoin = true),
                child: const Text('Join an existing session'),
              ),
            ),
          ] else ...[
            // Join session
            Icon(Icons.group_add, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Join Session', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Session code',
                hintText: 'e.g. PIKE-73',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: _joining ? null : _join,
                icon: _joining
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: const Text('Join'),
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showJoin = false),
                child: const Text('Create a session instead'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Real-time session dashboard with chat and shared catch feed.
class _SessionDashboard extends StatefulWidget {
  final String code;
  const _SessionDashboard({required this.code});

  @override
  State<_SessionDashboard> createState() => _SessionDashboardState();
}

class _SessionDashboardState extends State<_SessionDashboard> {
  final _s = SessionService.instance;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    _msgCtrl.clear();
    await _s.sendMessage(t);
  }

  Future<void> _leave() async {
    await _s.leaveSession();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services'), behavior: SnackBarBehavior.floating));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission needed to share your position'), behavior: SnackBarBehavior.floating));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      await _s.sendMessage(
        '📍 My location: ${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}'
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location sent to session!'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sendEmergency() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services'), behavior: SnackBarBehavior.floating));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission needed for emergency alerts'), behavior: SnackBarBehavior.floating));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      final lat = pos.latitude.toStringAsFixed(5);
      final lng = pos.longitude.toStringAsFixed(5);
      await _s.sendMessage(
        '🚨 EMERGENCY! I\'m at $lat,$lng — need help!'
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency alert sent! 🚨'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Session ${widget.code}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Share location',
            onPressed: _sendLocation,
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber, color: Colors.red),
            tooltip: 'Emergency — send location with alert',
            onPressed: _sendEmergency,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave session',
            onPressed: _leave,
          ),
        ],
      ),
      body: Column(
        children: [
          // Session code card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.link, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session Code',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(widget.code,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 2)),
                      );
                    },
                    child: Icon(Icons.copy, size: 18, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          // Members bar
          StreamBuilder<DocumentSnapshot>(
            stream: _s.sessionStream(),
            builder: (ctx, snap) {
              final members = _s.getMembers(snap.data?.data() as Map<String, dynamic>?);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        members.isEmpty ? 'Waiting for others...' : members.join(' — '),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
              stream: _s.messagesStream(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) {
                    final d = msgs[i].data() as Map<String, dynamic>;
                    final text = d['text'] as String? ?? '';
                    final sender = d['sender'] as String? ?? '';
                    final isCatch = text.contains('🎣');
                    return _MessageBubble(text: text, sender: sender, isCatch: isCatch);
                  },
                );
              },
            ),
          ),
          // Chat input
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isCatch;

  const _MessageBubble({required this.text, required this.sender, required this.isCatch});

  Future<void> _openDirections(String lat, String lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try { await launchUrl(Uri.parse('geo:$lat,$lng'), mode: LaunchMode.externalApplication); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = sender.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: isCatch
            ? BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSystem && !isCatch) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: isSystem
                  ? Text(text, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sender.isNotEmpty && !isCatch)
                          Text(sender, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                        GestureDetector(
                          onTap: () {
                            final locMatch = RegExp(r'([\d.]+),([-\d.]+)').firstMatch(text);
                            if (locMatch != null) _openDirections(locMatch.group(1)!, locMatch.group(2)!);
                          },
                          child: Text(text, style: TextStyle(
                            fontSize: isCatch ? 14 : 15,
                            fontWeight: isCatch ? FontWeight.w500 : null,
                            decoration: text.contains(',') ? TextDecoration.underline : null,
                            color: text.contains(',') ? Colors.blue : null,
                          )),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
