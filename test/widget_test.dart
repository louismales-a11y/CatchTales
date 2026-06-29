import 'package:flutter_test/flutter_test.dart';
import 'package:bestfishbuddy/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BestFishBuddyApp());
    expect(find.text('Best Fish Buddy'), findsWidgets);
  });
}
