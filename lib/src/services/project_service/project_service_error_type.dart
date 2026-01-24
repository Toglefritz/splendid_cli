/// Project Service Error Type Enumeration
///
/// This file contains the error type enumeration for Flutter project service
/// operations within the Splendid CLI project service. It provides categorized
/// error types that enable structured error handling, appropriate user
/// feedback, and programmatic error recovery strategies.
library;

/// Types of errors that can occur in project service operations.
///
/// This enumeration categorizes all possible error conditions that can occur
/// during Flutter project creation and setup operations. Each error type
/// represents a specific category of failure that requires different handling
/// approaches and user feedback strategies.
///
/// The error types are organized by the nature of the problem:
/// * Input validation errors (user-correctable)
/// * File system and environment errors (system-related)
/// * Flutter toolchain errors (tool-related)
/// * Template and resource errors (resource-related)
/// * Unknown errors (unexpected conditions)
///
/// This categorization enables:
/// * Appropriate error handling and recovery strategies
/// * Targeted user feedback and guidance
/// * Error reporting and analytics categorization
/// * Automated retry logic for transient errors
enum ProjectServiceErrorType {
  /// Invalid project name provided.
  ///
  /// This error occurs when the project name doesn't follow Dart package naming
  /// conventions. Project names must:
  /// * Start with a lowercase letter
  /// * Contain only lowercase letters, numbers, and underscores
  /// * Not start with an underscore
  /// * Be valid Dart identifiers
  ///
  /// Recovery: User should provide a valid project name following the
  /// conventions. Example invalid names: 'My-App', '123app', '_private', 'my
  /// app' Example valid names: 'my_app', 'todo_manager', 'family_tracker'
  invalidProjectName,

  /// Invalid organization format provided.
  ///
  /// This error occurs when the organization doesn't follow reverse domain name
  /// notation. Organizations must:
  /// * Contain at least one dot separator
  /// * Have segments separated by dots
  /// * Each segment must start with a lowercase letter
  /// * Each segment can contain letters, numbers, and hyphens
  /// * Each segment must end with a letter or number
  ///
  /// Recovery: User should provide a valid organization in reverse domain
  /// format. Example invalid: 'mycompany', 'com.', '.example', 'com..example'
  /// Example valid: 'com.example', 'org.mycompany', 'io.github.username'
  invalidOrganization,

  /// Invalid platforms specified.
  ///
  /// This error occurs when the platforms string contains unsupported or
  /// malformed platform names. Valid platforms include:
  /// * android, ios, web, windows, macos, linux
  ///
  /// Recovery: User should specify valid platform names in comma-separated
  /// format. Example invalid: 'android,invalid,web', 'mobile', 'desktop'
  /// Example valid: 'android,ios,web', 'windows,macos,linux'
  invalidPlatforms,

  /// Target directory already exists.
  ///
  /// This error occurs when attempting to create a project in a directory that
  /// already exists and the force flag is not set. This prevents accidental
  /// overwriting of existing projects or files.
  ///
  /// Recovery: User can either:
  /// * Choose a different project name or output directory
  /// * Use the force flag to overwrite the existing directory
  /// * Manually remove the existing directory
  directoryExists,

  /// Directory is not a Flutter project.
  ///
  /// This error occurs during setup operations when the target directory
  /// doesn't contain a valid Flutter project structure. A valid Flutter project
  /// must have:
  /// * pubspec.yaml file with Flutter dependencies
  /// * lib directory with Dart source code
  ///
  /// Recovery: User should ensure they're targeting a valid Flutter project
  /// directory or create a new project first.
  notFlutterProject,

  /// Flutter command execution failed.
  ///
  /// This error occurs when any Flutter CLI command fails during project
  /// creation or setup. This can happen due to:
  /// * Flutter not being installed or not in PATH
  /// * Network connectivity issues (for pub get)
  /// * Insufficient disk space
  /// * Permission issues
  /// * Invalid Flutter installation
  ///
  /// Recovery: User should check Flutter installation, network connectivity,
  /// disk space, and permissions. Running 'flutter doctor' can help diagnose
  /// Flutter environment issues.
  flutterCommandFailed,

  /// Template loading failed.
  ///
  /// This error occurs when the Mason brick template cannot be loaded or
  /// applied to the project. This can happen due to:
  /// * Missing or corrupted template files
  /// * Network issues when downloading templates
  /// * Insufficient permissions to access template cache
  /// * Template format or version incompatibility
  ///
  /// Recovery: User can try clearing the template cache, checking network
  /// connectivity, or ensuring proper file permissions.
  templateLoadFailed,

  /// Unknown error occurred.
  ///
  /// This error type represents unexpected conditions that don't fit into other
  /// categories. It serves as a fallback for:
  /// * Unexpected exceptions from underlying systems
  /// * New error conditions not yet categorized
  /// * System-level failures outside normal operation
  ///
  /// Recovery: User should check system resources, restart the operation, or
  /// report the issue if it persists. The underlying cause information in the
  /// exception can help with debugging.
  unknown,
}
