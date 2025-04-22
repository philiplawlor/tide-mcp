// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

// Removed default counter test as it is not relevant to the current app.
void main() {
  testWidgets('App loads with prompt for location selection', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TideHomePage(initialLoading: false)));
    await tester.pumpAndSettle();
    expect(find.textContaining('select a location'), findsOneWidget);
  });
}
