import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_config.dart';

class ProKeyManagerScreen extends StatefulWidget {
  const ProKeyManagerScreen({super.key});
  @override
  State<ProKeyManagerScreen> createState() => _ProKeyManagerScreenState();
}

class _ProKeyManagerScreenState extends State<ProKeyManagerScreen> {
  String _filter = 'all';
  bool _generating = false;
  String _generateType = 'lifetime';
  List<QueryDocumentSnapshot>? _allDocs;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await FirebaseFirestore.instance.collection('pro_licenses').get();
      if (mounted) setState(() { _allDocs = s.docs; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = '$e'; _loading = false; }); }
  }

  List<QueryDocumentSnapshot> get _filtered {
    final d = _allDocs ?? [];
    if (_filter == 'all') return d;
    return d.where((x) {
      if (_filter == 'used') return x['used'] == true;
      if (_filter == 'available') return x['used'] != true && (x['givenTo'] as String? ?? '').isEmpty;
      if (_filter == 'given') return x['used'] != true && (x['givenTo'] as String? ?? '').isNotEmpty;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiConfig.isDev) return Scaffold(body: const Center(child: Text('Dev only')));

    final filtered = _filtered;
    final hasItems = filtered.isNotEmpty;
    final isEmpty = filtered.isEmpty && !_loading && _error == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_allDocs?.length ?? 0} keys'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'all', child: Text('All (${_allDocs?.length ?? 0})')),
              PopupMenuItem(value: 'available', child: const Text('Available')),
              PopupMenuItem(value: 'given', child: const Text('Given out')),
              PopupMenuItem(value: 'used', child: const Text('Used')),
            ],
          ),
          IconButton(
            icon: _generating ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.add_circle_outline),
            onPressed: _generating ? null : _showGenerateDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  Text('$_error'),
                  ElevatedButton(onPressed: (){setState((){_loading=true;_error=null;});_load();}, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: hasItems
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: ListTile(
                              title: Text(filtered[i].id, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                              onTap: () {},
                            ),
                          ),
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              alignment: Alignment.center,
                              child: Text(
                                (_allDocs ?? []).isEmpty ? 'No keys yet' : 'No keys match this filter',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }

  void _showGenerateDialog() {
    final ctrl = TextEditingController(text: '10');
    String st = _generateType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Generate Keys'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Count', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'lifetime', label: Text('Lifetime')), ButtonSegment(value: 'yearly', label: Text('Yearly'))],
              selected: {st},
              onSelectionChanged: (v) => setSt(() => st = v.first),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: (){final c=int.tryParse(ctrl.text)??10;_generateType=st;Navigator.pop(ctx);_genKeys(c.clamp(1,200),type:st);}, child: const Text('Generate')),
          ],
        ),
      ),
    );
  }

  Future<void> _genKeys(int count, {String type = 'lifetime'}) async {
    setState(() => _generating = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final codes = <String>[]; int att = 0;
      while (codes.length < count && att < 200) {
        att++; final c = _code();
        if (!codes.contains(c)) {
          final e = await FirebaseFirestore.instance.collection('pro_licenses').doc(c).get();
          if (!e.exists) {
            codes.add(c); batch.set(FirebaseFirestore.instance.collection('pro_licenses').doc(c), {
              'type':type,'used':false,'usedAt':null,'givenTo':null,'givenAt':null,'notes':null,'createdAt':FieldValue.serverTimestamp(),
            });
          }
        }
      }
      if (codes.isNotEmpty) await batch.commit();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated ${codes.length}'), backgroundColor: Colors.green)); _load(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
    if (mounted) setState(() => _generating = false);
  }

  String _code() {
    final chars='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed=DateTime.now().microsecondsSinceEpoch&0x7FFFFFFF;
    return 'PRO-'+List.generate(3,(p){
      final ps=seed+p*7919;
      return String.fromCharCodes(List.generate(4,(i)=>chars.codeUnitAt((ps+i*37)%chars.length)));
    }).join('-');
  }
}
