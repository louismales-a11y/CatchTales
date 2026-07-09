/// Generates Pro license codes and uploads them to Firestore.
///
/// Usage:
///   dart run scripts/generate_license.dart --count=10 --batch=pro-batch-1
///
/// Or just run it to generate 5 codes with default batch name.
///
/// Requires Firebase admin SDK or you can run once and copy-paste the codes.
/// For now, this script prints codes and a Firestore import command you can paste.

import 'dart:math';

void main(List<String> args) {
  final count = _getArg(args, 'count', '5');
  final batch = _getArg(args, 'batch', 'pro-batch-1');

  final codes = <String>[];
  for (int i = 0; i < int.parse(count); i++) {
    codes.add(_generateCode());
  }

  print('''
╔══════════════════════════════════════════════════╗
║         CatchTales - Pro License Codes      ║
║         Batch: $batch                           ║
╚══════════════════════════════════════════════════╝
''');

  for (final code in codes) {
    print('  $code');
  }

  print('''

To upload these to Firestore, run this in Firebase Console > Firestore > Run a query > New collection "pro_licenses":

''');

  for (final code in codes) {
    print('''
  db.collection("pro_licenses").doc("$code").set({
    code: "$code",
    batch: "$batch",
    used: false,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  })''');
  }

  print('''

Or save these codes and upload via Firebase Console manually.
Each code is unique. Share them with users who pay.
''');
}

const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I, O, 0, 1 to avoid confusion

String _generateCode() {
  final rand = Random.secure();
  final prefix = 'PRO';
  final parts = <String>[];
  for (int i = 0; i < 3; i++) {
    final buf = StringBuffer();
    for (int j = 0; j < 4; j++) {
      buf.write(_chars[rand.nextInt(_chars.length)]);
    }
    parts.add(buf.toString());
  }
  return '$prefix-${parts[0]}-${parts[1]}-${parts[2]}';
}

String _getArg(List<String> args, String name, String defaultVal) {
  for (final arg in args) {
    if (arg.startsWith('--$name=')) {
      return arg.split('=')[1];
    }
  }
  return defaultVal;
}
