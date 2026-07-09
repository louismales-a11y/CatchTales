import 'package:flutter_test/flutter_test.dart';
import 'package:catchtales/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CatchTalesApp());
    expect(find.text('CatchTales'), findsWidgets);
  });
}
