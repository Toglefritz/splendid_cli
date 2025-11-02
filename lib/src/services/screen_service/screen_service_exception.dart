/// Screen Service Exception Module
///
/// This module contains the exception class for screen service operations
/// within the Flutter screen generation service. It provides structured
/// error handling with specific error types and diagnostic information.
///
/// Key Components:
/// * [ScreenServiceException] - Exception class for screen service errors
library;

import 'screen_service_error_type.dart';

/// Exception thrown by screen service operations.
///
/// This exception provides structured error handling for screen creation
/// operations, including specific error types, human-readable messages,
/// and optional underlying cause information for debugging purposes.
///
/// The exception supports various error scenarios:
/// * Invalid screen names that don't follow Dart identifier rules
/// * Non-Flutter project directories missing required files
/// * Existing screen conflicts when force mode is disabled
/// * Unknown errors from underlying system operations
///
/// Usage:
/// ```dart
/// try {
///   await screenService.createScreen(request);
/// } catch (e) {
///   if (e is ScreenServiceException) {
///     switch (e.type) {
///       case ScreenServiceErrorType.invalidScreenName:
///         print('Please provide a valid screen name');
///         break;
///       case ScreenServiceErrorType.screenExists:
///         print('Screen already exists, use --force to overwrite');
///         break;
///       // Handle other error types...
///     }
///   }
/// }
/// ```
class ScreenServiceException implements Exception {
  /// Creates a screen service exception.
  ///
  /// This constructor creates a structured exception with a human-readable
  /// message, specific error type for programmatic handling, and optional
  /// underlying cause for debugging purposes.
  ///
  /// Parameters:
  /// * [message] - Human-readable error description suitable for user display
  /// * [type] - Specific error type for programmatic error handling
  /// * [cause] - Optional underlying exception that caused this error
  const ScreenServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  ///
  /// This message provides a clear, user-friendly description of what went
  /// wrong during the screen creation operation. It should be suitable for
  /// display in CLI output, logs, or user interfaces.
  ///
  /// The message is crafted to be actionable when possible, guiding users
  /// toward resolution of the underlying issue.
  final String message;

  /// Type of error that occurred.
  ///
  /// This categorizes the error into specific types that can be handled
  /// programmatically by calling code. Each error type represents a different
  /// failure scenario with potentially different recovery strategies.
  ///
  /// Common error types include:
  /// * [ScreenServiceErrorType.invalidScreenName] - Invalid screen name format
  /// * [ScreenServiceErrorType.notFlutterProject] - Not in Flutter project directory
  /// * [ScreenServiceErrorType.screenExists] - Screen files already exist
  /// * [ScreenServiceErrorType.unknown] - Unexpected system error
  final ScreenServiceErrorType type;

  /// Optional underlying cause.
  ///
  /// When this exception wraps another exception (such as file system errors
  /// or template processing failures), the original exception is preserved
  /// here for debugging and logging purposes.
  ///
  /// This field is null when the error originates directly from screen
  /// service validation logic rather than underlying system operations.
  final Object? cause;

  /// Returns a string representation of this exception.
  ///
  /// The string includes the exception class name and the human-readable
  /// error message, making it suitable for logging and debugging output.
  ///
  /// Format: "ScreenServiceException: {message}"
  @override
  String toString() => 'ScreenServiceException: $message';
}
