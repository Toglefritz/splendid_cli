import 'l10n_sorter_error_type.dart';

/// Exception thrown when L10n sorting operations fail.
///
/// Provides structured error information including error type for appropriate
/// handling and exit code determination.
class L10nSorterException implements Exception {
  /// Creates a new L10n sorter exception.
  ///
  /// Parameters:
  /// * [message] - Human-readable error description
  /// * [type] - Category of error for handling logic
  const L10nSorterException(this.message, this.type);

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final L10nSorterErrorType type;

  @override
  String toString() => 'L10nSorterException: $message';
}
