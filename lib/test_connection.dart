import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'src/config.dart';
import 'src/logger.dart';

/// Test script to verify Appwrite connection before deploying.
/// Run this locally with: dart lib/test_connection.dart
///
/// Required environment variables:
/// - APPWRITE_API_KEY
/// - APPWRITE_FUNCTION_PROJECT_ID (optional, defaults from config)
/// - APPWRITE_FUNCTION_API_ENDPOINT (optional, defaults to https://cloud.appwrite.io/v1)
Future<void> main() async {
  final logger = Logger(serviceName: 'ConnectionTest');

  logger.info('=== TESTING APPWRITE CONNECTION ===');

  try {
    // Load config
    final config = Config(
      cutoffTimeMinutes: 1,
    );

    logger.info('Config loaded:');
    logger.info('  Database ID: ${config.databaseId}');
    logger.info('  Collection ID: ${config.collectionId}');
    logger.info('  Date Column: ${config.dateColumnName}');

    // Get credentials from environment
    final endpoint = Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ??
        'https://cloud.appwrite.io/v1';
    final projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'];
    final apiKey = Platform.environment['APPWRITE_API_KEY'];

    logger.info('Environment:');
    logger.info('  Endpoint: $endpoint');
    logger.info('  Project ID: ${projectId ?? 'NOT SET'}');
    logger.info('  API Key: ${apiKey != null ? 'SET (${apiKey.substring(0, 20)}...)' : 'NOT SET'}');

    if (apiKey == null) {
      logger.error('APPWRITE_API_KEY is not set!');
      logger.info('');
      logger.info('To set it, run:');
      logger.info('  set APPWRITE_API_KEY=your_api_key  (Windows CMD)');
      logger.info('  \$env:APPWRITE_API_KEY="your_api_key"  (Windows PowerShell)');
      logger.info('  export APPWRITE_API_KEY=your_api_key  (Linux/Mac)');
      exit(1);
    }

    if (projectId == null) {
      logger.warn('APPWRITE_FUNCTION_PROJECT_ID not set, using project from API key');
    }

    // Initialize client
    final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId ?? '')
      .setKey(apiKey);

    logger.info('Client initialized, testing connection...');

    final databases = Databases(client);

    // Test: Get collection info
    try {
      final collection = await databases.getCollection(
        databaseId: config.databaseId,
        collectionId: config.collectionId,
      );
      logger.info('✓ Successfully connected to collection!');
      logger.info('  Collection Name: ${collection.name}');
      logger.info('  Collection ID: ${collection.$id}');
    } catch (e) {
      logger.error('✗ Failed to get collection', error: e);
      logger.info('');
      logger.info('Possible issues:');
      logger.info('  - Wrong database_id or collection_id in config.dart');
      logger.info('  - API key does not have permission to read this collection');
      logger.info('  - Collection does not exist');
      exit(1);
    }

    // Test: List documents (just count)
    try {
      final response = await databases.listDocuments(
        databaseId: config.databaseId,
        collectionId: config.collectionId,
        queries: [Query.limit(1)],
      );
      logger.info('✓ Successfully queried documents!');
      logger.info('  Total documents in collection: ${response.total}');
    } catch (e) {
      logger.error('✗ Failed to list documents', error: e);
      exit(1);
    }

    logger.info('');
    logger.info('=== ALL TESTS PASSED ===');
    logger.info('Your setup looks correct. Deploy the function to Appwrite.');

  } catch (e, stackTrace) {
    logger.error('Unexpected error', error: e, stackTrace: stackTrace);
    exit(1);
  }
}
