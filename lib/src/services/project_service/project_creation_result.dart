/// Project Creation Result Model
///
/// This file contains the result model for Flutter project creation operations
/// within the Splendid CLI project service. It encapsulates the outcome of
/// project creation attempts, including success/failure status and relevant
/// metadata for user feedback and logging purposes.
library;

/// Result of project creation operation.
///
/// This class encapsulates the outcome of a Flutter project creation attempt,
/// providing structured information about success or failure, along with
/// relevant metadata for user feedback and system logging.
///
/// The result includes:
/// * Success/failure status for operation outcome
/// * Project metadata (name, path, platforms) for confirmation
/// * Error information for troubleshooting failed operations
/// * Structured data for consistent error handling and user feedback
class ProjectCreationResult {
  /// Creates a project creation result.
  ///
  /// This constructor is typically used internally by the factory constructors
  /// [ProjectCreationResult.success] and [ProjectCreationResult.failure] which
  /// provide more convenient and type-safe ways to create results.
  ///
  /// Parameters:
  /// * [success] - Whether the operation was successful
  /// * [projectName] - Name of the project that was created or attempted
  /// * [targetPath] - Path where the project was created or attempted
  /// * [platforms] - Platforms that were enabled or attempted
  /// * [error] - Error message if operation failed (null for success)
  const ProjectCreationResult({
    required this.success,
    required this.projectName,
    required this.targetPath,
    required this.platforms,
    this.error,
  });

  /// Creates a successful result.
  ///
  /// Use this factory constructor when project creation completes successfully.
  /// It automatically sets success to true and ensures no error message is included.
  ///
  /// Parameters:
  /// * [projectName] - Name of the successfully created project
  /// * [targetPath] - Path where the project was created
  /// * [platforms] - Platforms that were successfully enabled
  const ProjectCreationResult.success({
    required String projectName,
    required String targetPath,
    required String platforms,
  }) : this(
         success: true,
         projectName: projectName,
         targetPath: targetPath,
         platforms: platforms,
       );

  /// Creates a failed result.
  ///
  /// Use this factory constructor when project creation fails for any reason.
  /// It automatically sets success to false and requires an error message
  /// for user feedback and debugging purposes.
  ///
  /// Parameters:
  /// * [projectName] - Name of the project that failed to create
  /// * [targetPath] - Path where creation was attempted
  /// * [platforms] - Platforms that were attempted
  /// * [error] - Descriptive error message explaining the failure
  const ProjectCreationResult.failure({
    required String projectName,
    required String targetPath,
    required String platforms,
    required String error,
  }) : this(
         success: false,
         projectName: projectName,
         targetPath: targetPath,
         platforms: platforms,
         error: error,
       );

  /// Whether the operation was successful.
  ///
  /// True indicates the project was created successfully and is ready for use.
  /// False indicates the operation failed and the error field contains details.
  final bool success;

  /// Name of the project.
  ///
  /// This is the project name that was requested in the creation request,
  /// regardless of whether the operation succeeded or failed. It's useful
  /// for user feedback and logging purposes.
  final String projectName;

  /// Path where the project was created.
  ///
  /// For successful operations, this is the actual path where the project
  /// files were created. For failed operations, this is the path where
  /// creation was attempted.
  ///
  /// The path includes the project name as the final directory component.
  final String targetPath;

  /// Platforms that were enabled.
  ///
  /// For successful operations, this represents the platforms that were
  /// actually configured in the Flutter project. For failed operations,
  /// this represents the platforms that were requested.
  ///
  /// Format: comma-separated list (e.g., 'android,ios,web,windows,macos,linux')
  final String platforms;

  /// Error message if operation failed.
  ///
  /// This field is null for successful operations and contains a descriptive
  /// error message for failed operations. The message should be user-friendly
  /// and provide actionable information when possible.
  ///
  /// Examples:
  /// * 'Directory already exists. Use force flag to overwrite.'
  /// * 'Invalid project name: must follow Dart package naming conventions.'
  /// * 'Flutter create command failed: insufficient disk space.'
  final String? error;
}
