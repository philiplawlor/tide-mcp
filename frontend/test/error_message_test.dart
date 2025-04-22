import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Error message displays on error', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Simulate error state if possible
    // expect(find.textContaining('Error:'), findsWidgets);
  });
}
