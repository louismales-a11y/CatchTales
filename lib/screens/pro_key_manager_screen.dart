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
      final snapshot = await FirebaseFirestore.instance
          .collection('pro_licenses')
          .get();
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
      if (_filter == 'available') {
        if (d['used'] == true) return false;
        if ((d['givenTo'] as String? ?? '').trim().isNotEmpty) return false;
      } else if (_filter == 'used') {
        if (d['used'] != true) return false;
      } else if (_filter == 'given') {
        if (d['used'] == true) return false;
        if ((d['givenTo'] as String? ?? '').trim().isEmpty) return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toUpperCase();
        if (!d.id.toUpperCase().contains(q) &&
            !(d['givenTo'] as String? ?? '').toUpperCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isDev) {
      return Scaffold(body: Center(child: Text('Only in dev')));
    }

    final filtered = _filteredDocs;
    final allCount = (_allDocs ?? []).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Key Manager'),
        actions: [
          // Filter label showing current selection
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _filter == 'all' ? 'All' : _filter == 'available' ? 'Avail' : _filter == 'given' ? 'Given' : 'Used',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              print('Filter changed to: $v');
              setState(() => _filter = v);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'all', child: Text('All (${allCount})')),
              PopupMenuItem(value: 'available', child: Text('Available')),
              PopupMenuItem(value: 'given', child: Text('Given out')),
              PopupMenuItem(value: 'used', child: Text('Used')),
            ],
          ),
          IconButton(
            icon: _generating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_circle_outline),
            onPressed: _generating ? null : _showGenerateDialog,
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('$_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    // Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('$allCount total, ${filtered.length} shown',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _buildList(filtered)),
                  ],
                ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          (_allDocs ?? []).isEmpty ? 'No keys yet' : 'No keys match filter ($_filter)',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (_, i) => _keyTile(docs[i]),
    );
  }

  Widget _keyTile(QueryDocumentSnapshot doc) {
    final type = doc['type'] as String? ?? 'lifetime';
    final used = doc['used'] == true;
    final givenTo = doc['givenTo'] as String?;
    Color c;
    String s;
    if (used) { c = Colors.blueGrey; s = 'Used'; }
    else if (givenTo != null && givenTo.trim().isNotEmpty) { c = Colors.orange; s = 'Given'; }
    else { c = _neon; s = 'Available'; }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.vpn_key, size: 18, color: c),
        title: Text(doc.id, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', letterSpacing: 1)),
        subtitle: givenTo != null && givenTo.trim().isNotEmpty
            ? Text(givenTo, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: type == 'yearly' ? Colors.amber.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(type == 'yearly' ? '1yr' : 'LIFE',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                      color: type == 'yearly' ? Colors.amber : Colors.grey)),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
              child: Text(s, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: c)),
            ),
          ],
        ),
        onTap: () => _showDetail(doc),
      ),
    );
  }

  void _showDetail(QueryDocumentSnapshot doc) {
    final givenCtrl = TextEditingController(text: doc['givenTo'] as String? ?? '');
    final notesCtrl = TextEditingController(text: doc['notes'] as String? ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(doc.id, style: const TextStyle(fontSize: 15, fontFamily: 'monospace', letterSpacing: 1)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: givenCtrl,
                    decoration: const InputDecoration(labelText: 'Given to', isDense: true, border: OutlineInputBorder()),
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes', isDense: true, border: OutlineInputBorder()),
                    style: const TextStyle(fontSize: 13), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: doc.id));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied'), backgroundColor: Colors.green));
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                setSt(() => saving = true);
                try {
                  await doc.reference.update({
                    'givenTo': givenCtrl.text.trim().isEmpty ? null : givenCtrl.text.trim(),
                    'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    if (givenCtrl.text.trim().isNotEmpty && doc['givenAt'] == null)
                      'givenAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog() {
    final ctrl = TextEditingController(text: '10');
    String selectedType = _generateType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Generate Keys'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Count', isDense: true, border: OutlineInputBorder()),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lifetime', label: Text('Lifetime')),
                  ButtonSegment(value: 'yearly', label: Text('Yearly')),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setSt(() => selectedType = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
          final existing = await FirebaseFirestore.instance
              .collection('pro_licenses').doc(code).get();
          if (!existing.exists) {
            codes.add(code);
            batch.set(
              FirebaseFirestore.instance.collection('pro_licenses').doc(code),
              {'type': type, 'used': false, 'usedAt': null, 'givenTo': null,
               'givenAt': null, 'notes': null,
               'createdAt': FieldValue.serverTimestamp()},
            );
          }
        }
      }
      if (codes.isNotEmpty) await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generated ${codes.length} keys ($type)'),
                backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _generating = false);
  }

  String _generateCode() {
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final len = chars.length;
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    return 'PRO-' + List.generate(3, (p) {
      final ps = seed + p * 7919;
      return String.fromCharCodes(
        List.generate(4, (i) => chars.codeUnitAt((ps + i * 37) % len)),
      );
    }).join('-');
  }
}
