import 'dart:convert';
import 'dart:io';

/// Log level enum for categorizing log messages.
enum LogLevel { debug, info, warn, error }

/// Log entry model.
class LogEntry {
  final String timestamp;
  final String level;
  final String service;
  final String message;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.service,
    required this.message,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'level': level,
      'service': service,
      'message': message,
      if (context != null) 'context': context,
    };
  }
}

/// Structured logger for consistent logging across the application.
class Logger {
  final String serviceName;
  final List<LogEntry> _logs = [];
  final bool captureLogs;

  Logger({
    this.serviceName = 'CleanupService',
    this.captureLogs = true,
  });

  /// Returns all captured logs.
  List<Map<String, dynamic>> get logs => _logs.map((l) => l.toJson()).toList();

  /// Clears all captured logs.
  void clearLogs() => _logs.clear();

  /// Logs a message with the specified level and optional context.
  void log(LogLevel level, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final logEntry = LogEntry(
      timestamp: timestamp,
      level: level.name.toUpperCase(),
      service: serviceName,
      message: message,
      context: context,
    );

    // Capture log if enabled
    if (captureLogs) {
      _logs.add(logEntry);
    }

    // Output as JSON for structured logging
    stdout.writeln(jsonEncode(logEntry.toJson()));
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
