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
///
/// Example: If CUTOFF_TIME_MINUTES=60, deletes all records where createdAt < (now - 60 minutes)
///
/// Note: For Appwrite Cloud Functions, this is wrapped by the runtime.
/// The context object is injected by the Appwrite runtime.
Future<dynamic> main(dynamic context) async {
  final logger = Logger(serviceName: 'AppwriteCleanupFunction');

  logger.info('=== CLOUD FUNCTION STARTED ===');
  logger.info('Context type: ${context.runtimeType}');

  try {
    // DEBUG: Log all context properties
    try {
      logger.info('Context.req type: ${context.req?.runtimeType}');
      logger.info('Context.res type: ${context.res?.runtimeType}');
      logger.info('Context.env type: ${context.env?.runtimeType}');

      if (context.env != null) {
        logger.info('Available env vars: ${context.env.keys.toList()}');
      }
    } catch (e) {
      logger.error('Error inspecting context', error: e);
    }

    // DEBUG: Log Platform environment variables
    logger.info('Platform.env keys: ${Platform.environment.keys.where((k) => k.contains('APPWRITE')).toList()}');

    // Load configuration from environment variables
    final config = Config.fromEnvironment();
    logger.info('Configuration loaded', context: {'config': config.toString()});

    // DEBUG: Get API credentials from environment
    final endpoint = Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ??
        context.env?['APPWRITE_FUNCTION_API_ENDPOINT'] ??
        'https://cloud.appwrite.io/v1';

    final projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ??
        context.env?['APPWRITE_FUNCTION_PROJECT_ID'];

    final apiKey = Platform.environment['APPWRITE_API_KEY'] ??
        context.env?['APPWRITE_API_KEY'];

    logger.info('Appwrite endpoint: $endpoint');
    logger.info('Project ID: ${projectId != null ? 'SET' : 'MISSING'}');
    logger.info('API Key: ${apiKey != null ? 'SET (${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...)' : 'MISSING'}');

    if (projectId == null || apiKey == null) {
      throw Exception('Missing APPWRITE_FUNCTION_PROJECT_ID or APPWRITE_API_KEY');
    }

    // Initialize Appwrite client
    final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);

    logger.info('Appwrite client initialized successfully');

    // Initialize databases service
    final databases = Databases(client);

    // DEBUG: Test database connection by getting collection info
    try {
      logger.info('Testing database connection...');
      final collection = await databases.getCollection(
        databaseId: config.databaseId,
        collectionId: config.collectionId,
      );
      logger.info('Database connection successful', context: {
        'collection_name': collection.name,
        'collection_id': collection.$id,
      });
    } catch (e, stackTrace) {
      logger.error(
        'Failed to connect to database/collection',
        error: e,
        stackTrace: stackTrace,
        context: {
          'database_id': config.databaseId,
          'collection_id': config.collectionId,
        },
      );
      throw Exception('Database connection failed: $e');
    }

    // Create and execute cleanup service
    final cleanupService = CleanupService(
      config: config,
      logger: logger,
      databases: databases,
    );

    final result = await cleanupService.execute();

    logger.info('=== CLEANUP COMPLETED ===', context: {'result': result.toJson()});

    // Return response with logs
    return context.res.json(result.toJson());
  } catch (e, stackTrace) {
    logger.error(
      '=== FATAL ERROR ===',
      error: e,
      stackTrace: stackTrace,
    );

    return context.res.json({
      'success': false,
      'error': e.toString(),
      'stack_trace': stackTrace.toString(),
      'logs': logger.logs,
    });
  }
}
