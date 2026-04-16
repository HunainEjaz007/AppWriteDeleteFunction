import 'package:dart_package_1/dart_package_1.dart';
import 'package:test/test.dart';

void main() {
  group('Config Tests', () {
    test('should create valid config', () {
      final config = Config(
        cutoffTimeMinutes: 60,
      );

      expect(config.cutoffTimeMinutes, equals(60));
      expect(config.databaseId, equals('your_database_id'));
      expect(config.collectionId, equals('your_collection_id'));
      expect(config.dateColumnName, equals('date'));
      expect(config.limitRows, isNull);
    });

    test('should calculate cutoff time correctly', () {
      final config = Config(
        cutoffTimeMinutes: 60,
      );

      final cutoff = config.cutoffDateTime;
      final expectedCutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 60));

      // Allow 1 second tolerance for test execution time
      expect(
        cutoff.difference(expectedCutoff).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('should include limitRows when provided', () {
      final config = Config(
        cutoffTimeMinutes: 30,
        limitRows: 50,
      );

      expect(config.limitRows, equals(50));
    });
  });

  group('Logger Tests', () {
    test('should create logger with service name', () {
      final logger = Logger(serviceName: 'TestService');
      expect(logger, isNotNull);
    });

    test('should create default logger', () {
      final logger = Logger();
      expect(logger, isNotNull);
    });
  });

  group('CleanupResult Tests', () {
    test('should create successful result', () {
      final result = CleanupResult(
        success: true,
        deletedCount: 10,
        cutoffTime: DateTime.now().toUtc(),
        durationMs: 1000,
        wasLimited: false,
      );

      expect(result.success, isTrue);
      expect(result.deletedCount, equals(10));
      expect(result.wasLimited, isFalse);
    });

    test('should serialize to JSON correctly', () {
      final cutoff = DateTime.utc(2024, 1, 15, 10, 0, 0);
      final result = CleanupResult(
        success: true,
        deletedCount: 5,
        cutoffTime: cutoff,
        durationMs: 500,
        wasLimited: true,
      );

      final json = result.toJson();
      expect(json['success'], isTrue);
      expect(json['deleted_count'], equals(5));
      expect(json['was_limited'], isTrue);
      expect(json['cutoff_time'], equals('2024-01-15T10:00:00.000Z'));
    });
  });
}
