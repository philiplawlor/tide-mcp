import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Moon phase widget is present', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Moon Phase'), findsOneWidget);
  });
}
