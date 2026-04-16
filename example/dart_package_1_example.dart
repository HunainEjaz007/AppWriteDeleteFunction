// Example demonstrating the Appwrite Cleanup Service
// This is typically used as a Cloud Function, not directly in main.

import 'package:dart_package_1/dart_package_1.dart';

void main() {
  // Example configuration - DELETES ALL DOCUMENTS
  final config = Config(
    cutoffTimeMinutes: 1, // Required but not used for filtering (delete all mode)
    limitRows: 100,       // Delete max 100 rows (optional, remove to delete all)
  );

  print('Configuration created: ${config.toString()}');
  print('Database ID (hardcoded): ${config.databaseId}');
  print('Collection ID (hardcoded): ${config.collectionId}');
  print('Date Column (hardcoded): ${config.dateColumnName}');
  print('');
  print('NOTE: This function now DELETES ALL documents from the collection!');
  print('Set LIMIT_ROWS env var to limit how many are deleted.');

  // Logger example - logs are captured and returned in response
  final logger = Logger(serviceName: 'Example');
  logger.info('Example log message');
  logger.info('All logs will be returned in the function response');

  print('');
  print('Captured logs: ${logger.logs}');
}
