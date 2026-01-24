/// Screen Service Error Type Module
///
/// This module contains the error type enumeration for screen service
/// operations within the Flutter screen generation service. It defines the
/// specific categories of errors that can occur during screen creation
/// processes.
///
/// Key Components:
/// * [ScreenServiceErrorType] - Enumeration of possible screen service error types
library;

/// Types of errors that can occur in screen service operations.
///
/// This enumeration categorizes the different failure scenarios that can occur
/// during screen creation operations. Each error type represents a specific
/// category of failure with distinct characteristics and potential recovery
/// strategies.
///
/// The error types are designed to enable programmatic error handling, allowing
/// calling code to respond appropriately to different failure scenarios:
///
/// * Input validation errors can prompt for corrected input
/// * Environment errors can guide users to proper project setup
/// * Conflict errors can offer resolution options (force overwrite, rename, etc.)
/// * System errors can trigger retry logic or escalation
///
/// Usage:
/// ```dart
/// switch (exception.type) {
/// case ScreenServiceErrorType.invalidScreenName:
/// // Prompt user for valid screen name
/// break;
/// case ScreenServiceErrorType.notFlutterProject:
/// // Guide user to Flutter project directory
/// break;
/// case ScreenServiceErrorType.screenExists:
/// // Offer force overwrite option
/// break;
/// case ScreenServiceErrorType.unknown:
/// // Log error and show generic failure message
/// break;
/// }
/// ```
enum ScreenServiceErrorType {
  /// Invalid screen name provided.
  ///
  /// This error occurs when the requested screen name does not meet the
  /// requirements for a valid Dart identifier. Common issues include:
  /// * Names starting with numbers or special characters
  /// * Names containing spaces or invalid punctuation
  /// * Names that are Dart reserved words (class, if, for, etc.)
  /// * Empty or null screen names
  ///
  /// Recovery: Prompt the user to provide a valid screen name that follows Dart
  /// identifier naming conventions (alphanumeric and underscore only, starting
  /// with letter or underscore).
  invalidScreenName,

  /// Directory is not a Flutter project.
  ///
  /// This error occurs when the specified project path does not contain the
  /// required files and structure of a Flutter project. The service validates
  /// for:
  /// * Presence of pubspec.yaml file
  /// * Presence of lib/ directory
  /// * Flutter dependencies in pubspec.yaml
  ///
  /// Recovery: Guide the user to navigate to a valid Flutter project directory
  /// or initialize a new Flutter project in the current location.
  notFlutterProject,

  /// Screen already exists.
  ///
  /// This error occurs when screen files with the requested name already exist
  /// in the project and the force flag is not set. The service detects existing
  /// screen directories and files to prevent accidental overwrites.
  ///
  /// Recovery: Offer options to:
  /// * Use a different screen name
  /// * Enable force mode to overwrite existing files
  /// * Manually remove existing screen files first
  screenExists,

  /// Unknown error occurred.
  ///
  /// This error type covers unexpected failures that don't fit into the other
  /// specific categories. Common scenarios include:
  /// * File system permission errors
  /// * Template processing failures
  /// * Network errors when downloading templates
  /// * Unexpected exceptions from underlying libraries
  ///
  /// Recovery: Log the full error details for debugging, display a generic
  /// error message to the user, and potentially offer retry options.
  unknown,
}
