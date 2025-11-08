import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize sqflite for testing
void setupTestDatabase() {
  // Initialize FFI
  sqfliteFfiInit();
  // Set the database factory for testing
  databaseFactory = databaseFactoryFfi;
}
