import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/app.dart';
import 'core/core_providers.dart'; // For databaseProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialized DB asynchronously without blocking UI
  final container = ProviderContainer(
    overrides: [
      databaseProvider,
    ],
  );
  // Warm up the DB on app start - ensure database is initialized
  final db = container.read(databaseProvider);
  await db.database; // This will trigger database creation

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
