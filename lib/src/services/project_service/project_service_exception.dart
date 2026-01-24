/// Project Service Exception Model
///
/// This file contains the exception class for Flutter project service
/// operations within the Splendid CLI project service. It provides structured
/// error handling with categorized error types, user-friendly messages, and
/// optional underlying cause information for comprehensive debugging and user
/// feedback.
library;

import 'project_service_error_type.dart';

/// Exception thrown by project service operations.
///
/// This exception provides structured error handling for all project service
/// operations, including project creation and setup. It categorizes errors by
/// type to enable appropriate handling and user feedback strategies.
///
/// The exception includes:
/// * Human-readable error messages suitable for user display
/// * Categorized error types for programmatic handling
/// * Optional underlying cause information for debugging
/// * Consistent error handling across all project service operations
///
/// Error categories include validation errors, file system issues, Flutter
/// command failures, and template loading problems, each requiring different
/// handling approaches and user feedback strategies.
class ProjectServiceException implements Exception {
  /// Creates a project service exception.
  ///
  /// This constructor creates a structured exception with categorized error
  /// information. The message should be user-friendly and actionable when
  /// possible, while the type enables programmatic error handling.
  ///
  /// Parameters:
  /// * [message] - Human-readable error message for user display
  /// * [type] - Categorized error type for programmatic handling
  /// * [cause] - Optional underlying exception that caused this error
  const ProjectServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  ///
  /// This message is designed to be displayed to users and should provide
  /// clear, actionable information about what went wrong and how to resolve the
  /// issue when possible.
  ///
  /// The message should:
  /// * Be clear and concise
  /// * Avoid technical jargon when possible
  /// * Provide actionable guidance for resolution
  /// * Include relevant context (e.g., invalid values, file paths)
  ///
  /// Examples:
  /// * 'Directory already exists. Use force flag to overwrite.'
  /// * 'Invalid project name: my-app. Must use underscores instead of hyphens.'
  /// * 'Flutter create failed: insufficient disk space in target directory.'
  final String message;

  /// Type of error that occurred.
  ///
  /// This categorizes the error to enable appropriate handling strategies:
  /// * Validation errors can be resolved by correcting user input
  /// * File system errors may require user intervention or different paths
  /// * Flutter command errors may indicate environment or configuration issues
  /// * Template errors may require cache clearing or network connectivity
  ///
  /// The error type enables:
  /// * Programmatic error handling and recovery strategies
  /// * Appropriate user feedback and guidance
  /// * Error reporting and analytics categorization
  /// * Automated retry logic for transient errors
  final ProjectServiceErrorType type;

  /// Optional underlying cause.
  ///
  /// When this exception wraps another exception (e.g., from file system
  /// operations, network requests, or Flutter CLI execution), the original
  /// exception is preserved here for debugging and logging purposes.
  ///
  /// This information is typically not displayed to users but is valuable for:
  /// * Debugging and troubleshooting
  /// * Error logging and monitoring
  /// * Understanding root causes of failures
  /// * Technical support and issue resolution
  final Object? cause;

  /// Returns a string representation of the exception.
  ///
  /// This provides a consistent format for logging and debugging purposes,
  /// including the error type and message. The underlying cause is not included
  /// in the string representation to keep it concise.
  ///
  /// Format: 'ProjectServiceException: [message]'
  @override
  String toString() => 'ProjectServiceException: $message';
}
