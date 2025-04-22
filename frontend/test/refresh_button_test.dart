import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Refresh button is present', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
