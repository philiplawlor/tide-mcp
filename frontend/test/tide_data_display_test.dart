import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Tide data is displayed', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Placeholder: would check for tide data text
    // expect(find.textContaining('High Tides'), findsWidgets);
  });
}
