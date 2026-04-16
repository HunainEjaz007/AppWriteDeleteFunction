import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'src/config.dart';
import 'src/logger.dart';
import 'src/cleanup_service.dart';

/// Appwrite Cloud Function entry point for data cleanup.
/// 
/// Environment Variables:
/// - CUTOFF_TIME_MINUTES (required): Delete records older than this many minutes from current time
/// - LIMIT_ROWS (optional): Maximum number of rows to delete. If not set, deletes all old records
/// - APPWRITE_DATABASE_ID (required): Database ID
/// - APPWRITE_COLLECTION_ID (required): Collection ID
/// - DATE_COLUMN_NAME (optional): Name of the timestamp column, defaults to 'date'
/// 
/// Example: If CUTOFF_TIME_MINUTES=60, deletes all records where date < (now - 60 minutes)
Future<void> main(List<String> args) async {
  final logger = Logger(serviceName: 'AppwriteCleanupFunction');

  logger.info('Cloud function started');

  try {
    // Load configuration from environment variables
    final config = Config.fromEnvironment();
    logger.info('Configuration loaded', context: {'config': config.toString()});

    // Initialize Appwrite client
    final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(Platform.environment['APPWRITE_API_KEY']);

    logger.info('Appwrite client initialized');

    // Initialize databases service
    final databases = Databases(client);

    // Create and execute cleanup service
    final cleanupService = CleanupService(
      config: config,
      logger: logger,
      databases: databases,
    );

    final result = await cleanupService.execute();

    // Output result as JSON
    final responseJson = jsonEncode(result.toJson());
    logger.info('Cleanup completed', context: {'result': result.toJson()});

    // Write response to stdout for Appwrite
    stdout.writeln(responseJson);

    // Exit with appropriate code
    exit(result.success ? 0 : 1);
  } catch (e, stackTrace) {
    logger.error(
      'Fatal error in cloud function',
      error: e,
      stackTrace: stackTrace,
    );

    final errorResponse = jsonEncode({
      'success': false,
      'error': e.toString(),
    });

    stdout.writeln(errorResponse);
    exit(1);
  }
}
