import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Submit button appears after selecting location', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Placeholder: would simulate location selection
    // expect(find.text('Submit'), findsOneWidget);
  });
}
