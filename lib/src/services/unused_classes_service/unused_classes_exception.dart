import 'unused_classes_error_type.dart';

/// Exception thrown when unused class detection operations fail.
///
/// Provides structured error information including error type for appropriate
/// handling and exit code determination.
class UnusedClassesException implements Exception {
  /// Creates a new unused classes exception.
  ///
  /// Parameters:
  /// * [message] - Human-readable error description
  /// * [type] - Category of error for handling logic
  const UnusedClassesException(this.message, this.type);

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final UnusedClassesErrorType type;

  @override
  String toString() => 'UnusedClassesException: $message';
}
