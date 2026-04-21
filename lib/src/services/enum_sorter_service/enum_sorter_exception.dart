import 'enum_sorter_error_type.dart';

/// Exception thrown when enum sorting operations fail.
///
/// Provides structured error information including error type for appropriate
/// handling and exit code determination.
class EnumSorterException implements Exception {
  /// Creates a new enum sorter exception.
  ///
  /// Parameters:
  /// * [message] - Human-readable error description
  /// * [type] - Category of error for handling logic
  const EnumSorterException(this.message, this.type);

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final EnumSorterErrorType type;

  @override
  String toString() => 'EnumSorterException: $message';
}
