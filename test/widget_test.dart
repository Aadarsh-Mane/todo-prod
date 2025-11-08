import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo/app.dart';
import 'test_setup.dart';

void main() {
  setUpAll(() {
    setupTestDatabase();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Save the original ErrorWidget.builder
    final originalBuilder = ErrorWidget.builder;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Wait for initial load
    await tester.pump();

    // Verify that we can see the lists screen (using findsWidgets since it appears in appbar and maybe elsewhere)
    expect(find.text('My Lists'), findsWidgets);

    // Restore original ErrorWidget.builder
    ErrorWidget.builder = originalBuilder;
  });
}
