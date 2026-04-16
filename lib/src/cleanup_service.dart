import 'dart:async';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'config.dart';
import 'logger.dart';

/// Result of a cleanup operation.
class CleanupResult {
  final bool success;
  final int deletedCount;
  final DateTime cutoffTime;
  final int durationMs;
  final bool wasLimited;
  final String? error;

  CleanupResult({
    required this.success,
    required this.deletedCount,
    required this.cutoffTime,
    required this.durationMs,
    required this.wasLimited,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'deleted_count': deletedCount,
      'cutoff_time': cutoffTime.toIso8601String(),
      'duration_ms': durationMs,
      'was_limited': wasLimited,
      if (error != null) 'error': error,
    };
  }
}

/// Service responsible for cleaning up old database records.
class CleanupService {
  final Config config;
  final Logger logger;
  final Databases databases;

  static const int _batchSize = 100;

  CleanupService({
    required this.config,
    required this.logger,
    required this.databases,
  });

  /// Executes the cleanup operation.
  /// 
  /// Queries records where [dateColumn] < cutoffTime (sorted by date ASC),
  /// and deletes them. If limitRows is configured, only deletes up to that many rows.
  Future<CleanupResult> execute() async {
    final stopwatch = Stopwatch()..start();
    final cutoffTime = config.cutoffDateTime;

    logger.info(
      'Starting cleanup operation',
      context: {
        'cutoff_time': cutoffTime.toIso8601String(),
        'cutoff_minutes': config.cutoffTimeMinutes,
        'limit_rows': config.limitRows,
        'database_id': config.databaseId,
        'collection_id': config.collectionId,
        'date_column': config.dateColumnName,
      },
    );

    try {
      final documents = await _queryOldDocuments(cutoffTime);

      if (documents.isEmpty) {
        stopwatch.stop();
        logger.info(
          'No old records found to delete',
          context: {'cutoff_time': cutoffTime.toIso8601String()},
        );
        return CleanupResult(
          success: true,
          deletedCount: 0,
          cutoffTime: cutoffTime,
          durationMs: stopwatch.elapsedMilliseconds,
          wasLimited: false,
        );
      }

      final documentsToDelete = _applyLimitIfConfigured(documents);
      final deletedCount = await _deleteDocuments(documentsToDelete);

      stopwatch.stop();

      logger.info(
        'Cleanup operation completed successfully',
        context: {
          'deleted_count': deletedCount,
          'total_found': documents.length,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'was_limited': config.limitRows != null,
        },
      );

      return CleanupResult(
        success: true,
        deletedCount: deletedCount,
        cutoffTime: cutoffTime,
        durationMs: stopwatch.elapsedMilliseconds,
        wasLimited: config.limitRows != null,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      logger.error(
        'Cleanup operation failed',
        error: e,
        stackTrace: stackTrace,
        context: {
          'cutoff_time': cutoffTime.toIso8601String(),
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );

      return CleanupResult(
        success: false,
        deletedCount: 0,
        cutoffTime: cutoffTime,
        durationMs: stopwatch.elapsedMilliseconds,
        wasLimited: false,
        error: e.toString(),
      );
    }
  }

  /// Queries documents older than the cutoff time.
  /// Returns documents sorted by date column in ascending order (oldest first).
  Future<List<Document>> _queryOldDocuments(DateTime cutoffTime) async {
    final cutoffIsoString = cutoffTime.toIso8601String();
    final nowIsoString = DateTime.now().toUtc().toIso8601String();

    logger.info(
      'Querying old documents',
      context: {
        'current_time': nowIsoString,
        'cutoff_time': cutoffIsoString,
        'cutoff_minutes': config.cutoffTimeMinutes,
        'date_column': config.dateColumnName,
        'database_id': config.databaseId,
        'collection_id': config.collectionId,
        'query': 'Query.lessThan("${config.dateColumnName}", "$cutoffIsoString")',
      },
    );

    try {
      final response = await databases.listDocuments(
        databaseId: config.databaseId,
        collectionId: config.collectionId,
        queries: [
          Query.lessThan(config.dateColumnName, cutoffIsoString),
          Query.orderAsc(config.dateColumnName),
          Query.limit(_batchSize),
        ],
      );

      logger.info(
        'Query completed',
        context: {
          'found_documents': response.documents.length,
          'total_available': response.total,
          'documents': response.documents.map((d) => {
            'id': d.$id,
            'createdAt': d.data[config.dateColumnName],
          }).toList(),
        },
      );

      return response.documents;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to query old documents',
        error: e,
        stackTrace: stackTrace,
        context: {'cutoff_time': cutoffIsoString},
      );
      rethrow;
    }
  }

  /// Applies row limit if configured.
  List<Document> _applyLimitIfConfigured(List<Document> documents) {
    if (config.limitRows == null) {
      logger.debug(
        'No row limit configured, deleting all ${documents.length} documents',
      );
      return documents;
    }

    final limit = config.limitRows!;
    if (documents.length > limit) {
      logger.info(
        'Applying row limit',
        context: {
          'total_found': documents.length,
          'limit': limit,
          'will_delete': limit,
        },
      );
      return documents.take(limit).toList();
    }

    logger.debug(
      'Row limit configured but not exceeded',
      context: {
        'total_found': documents.length,
        'limit': limit,
      },
    );
    return documents;
  }

  /// Deletes the specified documents in batches.
  Future<int> _deleteDocuments(List<Document> documents) async {
    if (documents.isEmpty) {
      return 0;
    }

    logger.info(
      'Starting deletion of ${documents.length} documents',
      context: {
        'batch_count': (documents.length / _batchSize).ceil(),
        'document_ids': documents.map((d) => d.$id).toList(),
      },
    );

    int deletedCount = 0;
    final errors = <String>[];

    for (final doc in documents) {
      try {
        logger.info(
          'Deleting document',
          context: {
            'document_id': doc.$id,
            'document_date': doc.data[config.dateColumnName],
          },
        );

        await databases.deleteDocument(
          databaseId: config.databaseId,
          collectionId: config.collectionId,
          documentId: doc.$id,
        );
        deletedCount++;

        logger.info(
          'Successfully deleted document',
          context: {
            'document_id': doc.$id,
            'deleted_count_so_far': deletedCount,
          },
        );
      } catch (e, stackTrace) {
        final errorMsg = 'Failed to delete document ${doc.$id}: $e';
        logger.error(
          errorMsg,
          error: e,
          stackTrace: stackTrace,
          context: {
            'document_id': doc.$id,
            'document_date': doc.data[config.dateColumnName],
          },
        );
        errors.add(errorMsg);
      }
    }

    if (errors.isNotEmpty) {
      logger.warn(
        'Some documents could not be deleted',
        context: {
          'deleted_count': deletedCount,
          'failed_count': errors.length,
          'errors': errors.take(5).toList(),
        },
      );
    }

    return deletedCount;
  }
}
