import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Week at a Glance is shown', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Week at a Glance'), findsOneWidget);
  });
}
