import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/api_config.dart';

class ProKeyManagerScreen extends StatefulWidget {
  const ProKeyManagerScreen({super.key});

  @override
  State<ProKeyManagerScreen> createState() => _ProKeyManagerScreenState();
}

class _ProKeyManagerScreenState extends State<ProKeyManagerScreen> {
  String _filter = 'all';
  String _search = '';
  bool _generating = false;
  String _generateType = 'lifetime';

  List<QueryDocumentSnapshot>? _allDocs;
  bool _loading = true;
  String? _error;

  static const _neon = Color(0xFF76FF03);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pro_licenses').get();
      if (mounted) {
        setState(() {
          _allDocs = snapshot.docs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  List<QueryDocumentSnapshot> get _filteredDocs {
    final docs = _allDocs ?? [];
    if (_filter == 'all' && _search.isEmpty) return docs;

    return docs.where((d) {
      // Filter
      if (_filter == 'available') {
        final used = d['used'] == true;
        final gv = d['givenTo'] as String? ?? '';
        if (used || gv.trim().isNotEmpty) return false;
      } else if (_filter == 'used') {
        if (d['used'] != true) return false;
      } else if (_filter == 'given') {
        final used = d['used'] == true;
        final gv = d['givenTo'] as String? ?? '';
        if (used || gv.trim().isEmpty) return false;
      }

      // Search
      if (_search.isNotEmpty) {
        final q = _search.toUpperCase();
        final key = d.id.toUpperCase();
        final recipient = (d['givenTo'] as String? ?? '').toUpperCase();
        if (!key.contains(q) && !recipient.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isDev) {
      return const Scaffold(
        body: Center(child: Text('Only available in dev builds')),
      );
    }

    final docs = _allDocs ?? [];
    final filtered = _filteredDocs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Key Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: _generating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_circle_outline),
            onPressed: _generating ? null : _showGenerateDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A1628),
      body: _buildBody(filtered, docs),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildBody(List<QueryDocumentSnapshot> filtered, List<QueryDocumentSnapshot> all) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by key or recipient...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip('${all.length} Total', Colors.grey),
                const SizedBox(width: 8),
                _chip('${all.where((d) => d['used'] != true && (d['givenTo'] as String? ?? '').trim().isEmpty).length} Available', _neon),
                const SizedBox(width: 8),
                _chip('${all.where((d) => d['used'] != true && (d['givenTo'] as String? ?? '').trim().isNotEmpty).length} Given', Colors.orange),
                const SizedBox(width: 8),
                _chip('${all.where((d) => d['used'] == true).length} Used', Colors.blueGrey),
                const Spacer(),
                if (_filter != 'all')
                  Text('(${filtered.length} shown)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: const Divider(height: 1)),
        SliverFillRemaining(
          child: _buildContent(filtered),
        ),
      ],
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot> docs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('$_error', style: const TextStyle(fontSize: 13, color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () {
              setState(() { _loading = true; _error = null; _allDocs = null; _load(); });
            }, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_off, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              _allDocs!.isEmpty ? 'No keys yet — tap + to generate' : 'No keys match this filter',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) => _KeyTile(doc: docs[index]),
    );
  }

  void _showFilterMenu() {
    final cur = _filter;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Filter by'), dense: true, enabled: false),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('All keys'),
            trailing: cur == 'all' ? Icon(Icons.check, size: 18, color: _neon) : null,
            onTap: () { setState(() => _filter = 'all'); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: _neon),
            title: const Text('Available'),
            subtitle: const Text('Not used, not assigned'),
            trailing: cur == 'available' ? Icon(Icons.check, size: 18, color: _neon) : null,
            onTap: () { setState(() => _filter = 'available'); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.orange),
            title: const Text('Given out'),
            subtitle: const Text('Assigned to someone, not yet used'),
            trailing: cur == 'given' ? Icon(Icons.check, size: 18, color: Colors.orange) : null,
            onTap: () { setState(() => _filter = 'given'); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.blueGrey),
            title: const Text('Used'),
            subtitle: const Text('Already activated'),
            trailing: cur == 'used' ? Icon(Icons.check, size: 18, color: Colors.blueGrey) : null,
            onTap: () { setState(() => _filter = 'used'); Navigator.pop(ctx); },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showGenerateDialog() {
    final ctrl = TextEditingController(text: '10');
    String selectedType = _generateType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Keys'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Number of keys',
                  helperText: '1-200 at a time',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lifetime', label: Text('Lifetime')),
                  ButtonSegment(value: 'yearly', label: Text('Yearly')),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setDialogState(() => selectedType = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(ctrl.text) ?? 10;
                _generateType = selectedType;
                Navigator.pop(ctx);
                _generateKeys(count.clamp(1, 200), type: selectedType);
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateKeys(int count, {String type = 'lifetime'}) async {
    setState(() => _generating = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final codes = <String>[];
      int attempts = 0;

      while (codes.length < count && attempts < 200) {
        attempts++;
        final code = _generateCode();
        if (!codes.contains(code)) {
          final existing = await FirebaseFirestore.instance.collection('pro_licenses').doc(code).get();
          if (!existing.exists) {
            codes.add(code);
            batch.set(
              FirebaseFirestore.instance.collection('pro_licenses').doc(code),
              {
                'type': type,
                'used': false,
                'usedAt': null,
                'givenTo': null,
                'givenAt': null,
                'notes': null,
                'createdAt': FieldValue.serverTimestamp(),
              },
            );
          }
        }
      }

      if (codes.isNotEmpty) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${codes.length} new keys ($type)'),
            backgroundColor: Colors.green,
          ),
        );
        _load(); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _generating = false);
  }

  String _generateCode() {
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final len = chars.length;
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    final parts = List.generate(3, (p) {
      final pSeed = seed + p * 7919;
      final buf = StringBuffer();
      for (int i = 0; i < 4; i++) {
        buf.writeCharCode(chars.codeUnitAt((pSeed + i * 37) % len));
      }
      return buf.toString();
    });
    return 'PRO-${parts[0]}-${parts[1]}-${parts[2]}';
  }
}

class _KeyTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const _KeyTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final type = doc['type'] as String? ?? 'lifetime';
    final used = doc['used'] == true;
    final givenTo = doc['givenTo'] as String?;
    final usedAt = doc['usedAt'] as Timestamp?;
    final notes = doc['notes'] as String?;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (used) {
      statusColor = Colors.blueGrey;
      statusLabel = 'Used';
      statusIcon = Icons.check_circle;
    } else if (givenTo != null && givenTo.trim().isNotEmpty) {
      statusColor = Colors.orange;
      statusLabel = 'Given';
      statusIcon = Icons.person_outline;
    } else {
      statusColor = _neon;
      statusLabel = 'Available';
      statusIcon = Icons.vpn_key;
    }

    final dateFmt = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: type == 'yearly' ? Colors.amber.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type == 'yearly' ? '1yr' : 'LIFE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: type == 'yearly' ? Colors.amber : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                ],
              ),
              if (givenTo != null && givenTo.trim().isNotEmpty || usedAt != null) ...[
                const SizedBox(height: 4),
                if (givenTo != null && givenTo.trim().isNotEmpty)
                  Text('Given to: $givenTo',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                if (usedAt != null)
                  Text('Activated: ${dateFmt.format(usedAt.toDate())}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (notes != null && notes.isNotEmpty)
                  Text(notes, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.vpn_key, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(doc.id, style: const TextStyle(fontSize: 16, fontFamily: 'monospace', letterSpacing: 1)),
            ),
          ],
        ),
        content: _KeyDetailContent(doc: doc, onClose: () => Navigator.pop(ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const _neon = Color(0xFF76FF03);
}

class _KeyDetailContent extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onClose;

  const _KeyDetailContent({required this.doc, required this.onClose});

  @override
  State<_KeyDetailContent> createState() => _KeyDetailContentState();
}

class _KeyDetailContentState extends State<_KeyDetailContent> {
  late TextEditingController _givenToCtrl;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _givenToCtrl = TextEditingController(text: widget.doc['givenTo'] as String? ?? '');
    _notesCtrl = TextEditingController(text: widget.doc['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _givenToCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.doc['type'] as String? ?? 'lifetime';
    final used = widget.doc['used'] == true;
    final usedAt = widget.doc['usedAt'] as Timestamp?;
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: type == 'yearly' ? Colors.amber.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type == 'yearly' ? 'Yearly' : 'Lifetime',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: type == 'yearly' ? Colors.amber : Colors.grey)),
              ),
              const SizedBox(width: 8),
              Icon(used ? Icons.check_circle : Icons.vpn_key, size: 16, color: used ? Colors.blueGrey : _KeyTile._neon),
              const SizedBox(width: 6),
              Text(
                used ? 'Activated ${usedAt != null ? dateFmt.format(usedAt.toDate()) : ''}' : 'Not yet used',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _givenToCtrl,
            decoration: const InputDecoration(
              labelText: 'Given to (store name / contact)',
              hintText: "e.g. Bob's Bait & Tackle",
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'e.g. Met at fishing expo',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Key'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.doc.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Key copied'), backgroundColor: Colors.green),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save, size: 16),
              label: const Text('Save Details'),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final update = <String, dynamic>{
        'givenTo': _givenToCtrl.text.isNotEmpty ? _givenToCtrl.text.trim() : null,
        'notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      };
      if (_givenToCtrl.text.isNotEmpty && widget.doc['givenAt'] == null) {
        update['givenAt'] = FieldValue.serverTimestamp();
      }
      await widget.doc.reference.update(update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), backgroundColor: Colors.green),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }
}
