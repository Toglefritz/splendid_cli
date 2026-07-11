import 'unused_l10n_error_type.dart';

/// Exception thrown when unused localization detection operations fail.
///
/// Provides structured error information including error type for appropriate
/// handling and exit code determination.
class UnusedL10nException implements Exception {
  /// Creates a new unused l10n exception.
  ///
  /// Parameters:
  /// * [message] - Human-readable error description
  /// * [type] - Category of error for handling logic
  const UnusedL10nException(this.message, this.type);

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final UnusedL10nErrorType type;

  @override
  String toString() => 'UnusedL10nException: $message';
}
