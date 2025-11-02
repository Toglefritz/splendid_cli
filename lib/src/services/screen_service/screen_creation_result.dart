/// Screen Creation Result Module
///
/// This module contains the result class for screen creation operations
/// within the Flutter screen generation service. It provides structured
/// information about the outcome of screen creation attempts.
///
/// Key Components:
/// * [ScreenCreationResult] - Result data for screen creation operations
library;

/// Result of screen creation operation.
///
/// This class encapsulates the outcome of a screen creation request, providing
/// detailed information about success or failure states. It includes metadata
/// about created files, paths, and error information when applicable.
///
/// The result supports both success and failure scenarios:
/// * Success results include created file paths and screen metadata
/// * Failure results include error messages and diagnostic information
///
/// Usage:
/// ```dart
/// // Success case
/// final result = ScreenCreationResult.success(
///   screenName: 'UserProfile',
///   screenPath: '/project/lib/screens/user_profile',
///   createdFiles: ['user_profile_route.dart', 'user_profile_controller.dart'],
/// );
///
/// // Failure case
/// final result = ScreenCreationResult.failure(
///   screenName: 'UserProfile',
///   error: 'Screen already exists',
/// );
/// ```
class ScreenCreationResult {
  /// Creates a screen creation result.
  ///
  /// This constructor allows creating results with custom success/failure states
  /// and detailed information about the operation outcome. Use the factory
  /// constructors [ScreenCreationResult.success] and [ScreenCreationResult.failure] for common result patterns.
  ///
  /// Parameters:
  /// * [success] - Whether the operation completed successfully
  /// * [screenName] - Name of the screen that was processed
  /// * [screenPath] - Path where screen files were created (empty for failures)
  /// * [createdFiles] - List of files that were successfully created
  /// * [error] - Error message for failed operations (null for success)
  const ScreenCreationResult({
    required this.success,
    required this.screenName,
    required this.screenPath,
    required this.createdFiles,
    this.error,
  });

  /// Creates a successful result.
  ///
  /// This factory constructor creates a result indicating successful screen
  /// creation with all the relevant metadata about the created files and
  /// their locations.
  ///
  /// Parameters:
  /// * [screenName] - Name of the successfully created screen
  /// * [screenPath] - Directory path where screen files were created
  /// * [createdFiles] - List of file paths that were generated
  ///
  /// Returns a [ScreenCreationResult] with success=true and no error message.
  const ScreenCreationResult.success({
    required String screenName,
    required String screenPath,
    required List<String> createdFiles,
  }) : this(
         success: true,
         screenName: screenName,
         screenPath: screenPath,
         createdFiles: createdFiles,
       );

  /// Creates a failed result.
  ///
  /// This factory constructor creates a result indicating failed screen
  /// creation with an error message explaining the failure reason.
  ///
  /// Parameters:
  /// * [screenName] - Name of the screen that failed to be created
  /// * [error] - Human-readable error message describing the failure
  ///
  /// Returns a [ScreenCreationResult] with success=false and empty file lists.
  const ScreenCreationResult.failure({
    required String screenName,
    required String error,
  }) : this(
         success: false,
         screenName: screenName,
         screenPath: '',
         createdFiles: const [],
         error: error,
       );

  /// Whether the operation was successful.
  ///
  /// This flag indicates if the screen creation completed without errors.
  /// When true, the [createdFiles] and [screenPath] contain valid information.
  /// When false, the [error] field contains the failure reason.
  final bool success;

  /// Name of the screen that was created.
  ///
  /// This is the screen name from the original request, preserved in the
  /// result for reference and logging purposes. Available for both successful
  /// and failed operations.
  final String screenName;

  /// Path where the screen files were created.
  ///
  /// For successful operations, this contains the absolute path to the
  /// directory where the screen files were generated. For failed operations,
  /// this field is empty.
  ///
  /// The path follows the pattern: {projectPath}/lib/screens/{snake_case_name}/
  final String screenPath;

  /// List of files that were created.
  ///
  /// For successful operations, this contains the absolute paths of all
  /// files that were generated during screen creation, typically including:
  /// * {screen_name}_route.dart - Screen route definition
  /// * {screen_name}_controller.dart - Business logic controller
  /// * {screen_name}_view.dart - UI presentation layer
  ///
  /// For failed operations, this list is empty.
  final List<String> createdFiles;

  /// Error message if operation failed.
  ///
  /// For failed operations, this contains a human-readable error message
  /// explaining why the screen creation failed. Common error scenarios include:
  /// * Invalid screen names
  /// * Non-Flutter project directories
  /// * Existing screen conflicts
  /// * File system permission issues
  ///
  /// For successful operations, this field is null.
  final String? error;
}
