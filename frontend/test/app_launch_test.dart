import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Local Tide Clock'), findsOneWidget);
  });
}
