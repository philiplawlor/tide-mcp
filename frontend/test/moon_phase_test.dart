import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Moon phase widget is present', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TideHomePage(initialLoading: false)));
    await tester.pumpAndSettle();
    expect(find.textContaining('select a location'), findsOneWidget);
  });
}
