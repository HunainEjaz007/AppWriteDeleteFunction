// Example demonstrating the Appwrite Cleanup Service
// This is typically used as a Cloud Function, not directly in main.

import 'package:dart_package_1/dart_package_1.dart';

void main() {
  // Example configuration
  final config = Config(
    cutoffTimeMinutes: 60, // Delete records older than 1 hour
    limitRows: 100,        // Delete max 100 rows (optional)
  );

  print('Configuration created: ${config.toString()}');
  print('Cutoff time: ${config.cutoffDateTime}');
  print('Database ID (hardcoded): ${config.databaseId}');
  print('Collection ID (hardcoded): ${config.collectionId}');
  print('Date Column (hardcoded): ${config.dateColumnName}');

  // Logger example
  final logger = Logger(serviceName: 'Example');
  logger.info('This is an example of the cleanup service configuration');
}
