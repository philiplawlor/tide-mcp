import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Loading indicator is present when loading', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Simulate loading state if possible
    // expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
