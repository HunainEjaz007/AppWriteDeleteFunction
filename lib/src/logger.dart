import 'dart:convert';
import 'dart:io';

/// Log level enum for categorizing log messages.
enum LogLevel { debug, info, warn, error }

/// Structured logger for consistent logging across the application.
class Logger {
  final String serviceName;

  Logger({this.serviceName = 'CleanupService'});

  /// Logs a message with the specified level and optional context.
  void log(LogLevel level, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'level': level.name.toUpperCase(),
      'service': serviceName,
      'message': message,
      if (context != null) 'context': context,
    };

    // Output as JSON for structured logging
    stdout.writeln(jsonEncode(logEntry));
  }

  /// Logs a debug message.
  void debug(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, context: context);
  }

  /// Logs an info message.
  void info(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.info, message, context: context);
  }

  /// Logs a warning message.
  void warn(String message, {Map<String, dynamic>? context}) {
    log(LogLevel.warn, message, context: context);
  }

  /// Logs an error message.
  void error(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    final extendedContext = {
      if (context != null) ...context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    log(LogLevel.error, message, context: extendedContext.isNotEmpty ? extendedContext : null);
  }
}
