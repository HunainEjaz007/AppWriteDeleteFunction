import 'dart:io';

/// Configuration class for loading and validating environment variables.
class Config {
  final int cutoffTimeMinutes;
  final int? limitRows;

  // Hardcoded constants - modify these for your setup
  static const String _databaseId = 'your_database_id';
  static const String _collectionId = 'your_collection_id';
  static const String _dateColumnName = 'date';

  Config({
    required this.cutoffTimeMinutes,
    this.limitRows,
  });

  String get databaseId => _databaseId;
  String get collectionId => _collectionId;
  String get dateColumnName => _dateColumnName;

  /// Loads configuration from environment variables.
  /// Throws [Exception] if required variables are missing or invalid.
  factory Config.fromEnvironment() {
    final cutoffTimeStr = Platform.environment['CUTOFF_TIME_MINUTES'];
    final limitRowsStr = Platform.environment['LIMIT_ROWS'];

    if (cutoffTimeStr == null || cutoffTimeStr.isEmpty) {
      throw Exception('Missing required environment variable: CUTOFF_TIME_MINUTES');
    }

    final cutoffTimeMinutes = int.tryParse(cutoffTimeStr);
    if (cutoffTimeMinutes == null || cutoffTimeMinutes <= 0) {
      throw Exception(
        'Invalid CUTOFF_TIME_MINUTES value: $cutoffTimeStr. Must be a positive integer.',
      );
    }

    int? limitRows;
    if (limitRowsStr != null && limitRowsStr.isNotEmpty) {
      limitRows = int.tryParse(limitRowsStr);
      if (limitRows == null || limitRows <= 0) {
        throw Exception(
          'Invalid LIMIT_ROWS value: $limitRowsStr. Must be a positive integer.',
        );
      }
    }

    return Config(
      cutoffTimeMinutes: cutoffTimeMinutes,
      limitRows: limitRows,
    );
  }

  /// Returns the cutoff DateTime (current time minus cutoff minutes).
  DateTime get cutoffDateTime {
    return DateTime.now().toUtc().subtract(Duration(minutes: cutoffTimeMinutes));
  }

  @override
  String toString() {
    return 'Config(cutoffTimeMinutes: $cutoffTimeMinutes, limitRows: $limitRows, '
        'databaseId: $databaseId, collectionId: $collectionId, dateColumnName: $dateColumnName)';
  }
}
