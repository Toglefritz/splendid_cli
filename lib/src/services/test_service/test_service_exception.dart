/// Test Service Exception Module
///
/// This module contains the exception class for test service operations. It
/// provides structured error handling with specific error types and contextual
/// information for debugging and user feedback.
library;

import 'test_service_error_type.dart';

/// Exception thrown by test service operations.
///
/// This exception class provides structured error handling for all test service
/// operations. It includes a human-readable message, a specific error type for
/// programmatic handling, and optional cause information for debugging
/// purposes.
///
/// The exception is designed to provide clear feedback to both users and
/// developers about what went wrong during test generation operations, enabling
/// appropriate error handling and recovery strategies.
///
/// Usage:
/// ```dart
/// try {
/// await testService.generateTest(request);
/// } on TestServiceException catch (e) {
/// switch (e.type) {
/// case TestServiceErrorType.targetFileNotFound:
/// print('File not found: ${e.message}');
/// break;
/// case TestServiceErrorType.testFileExists:
/// print('Test already exists: ${e.message}');
/// break;
/// default:
/// print('Unexpected error: ${e.message}');
/// }
/// }
/// ```
class TestServiceException implements Exception {
  /// Creates a test service exception.
  ///
  /// Parameters:
  /// * [message] - Human-readable error message suitable for display
  /// * [type] - Specific error type for programmatic handling
  /// * [cause] - Optional underlying exception that caused this error
  const TestServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  ///
  /// This message is suitable for display to users and provides clear
  /// information about what went wrong during the test generation operation.
  /// The message should be actionable when possible, guiding users toward
  /// resolution steps.
  final String message;

  /// Type of error that occurred.
  ///
  /// This enumeration value allows for programmatic handling of different error
  /// scenarios. Callers can use this to implement specific recovery strategies
  /// or user interface behaviors based on the error type.
  final TestServiceErrorType type;

  /// Optional underlying cause.
  ///
  /// When this exception wraps another exception (such as file system errors or
  /// template generation failures), the original exception is preserved here
  /// for debugging and logging purposes.
  final Object? cause;

  /// Returns a string representation of this exception.
  ///
  /// The string includes the exception class name and the human-readable
  /// message, making it suitable for logging and debugging output.
  @override
  String toString() => 'TestServiceException: $message';
}
