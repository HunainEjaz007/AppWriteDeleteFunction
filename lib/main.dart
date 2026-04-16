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

  logger.info('Cloud function started');

  try {
    // Load configuration from environment variables
    final config = Config.fromEnvironment();
    logger.info('Configuration loaded', context: {'config': config.toString()});

    // Initialize Appwrite client using context
    final client = Client()
      .setEndpoint(context.req.headers['x-appwrite-endpoint'] ?? 'https://cloud.appwrite.io/v1')
      .setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(context.env['APPWRITE_API_KEY']);

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

    logger.info('Cleanup completed', context: {'result': result.toJson()});

    // Return response
    return context.res.json(result.toJson());
  } catch (e, stackTrace) {
    logger.error(
      'Fatal error in cloud function',
      error: e,
      stackTrace: stackTrace,
    );

    return context.res.json({
      'success': false,
      'error': e.toString(),
    });
  }
}
