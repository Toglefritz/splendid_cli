/// Screen Creation Request Module
///
/// This module contains the request configuration class for screen creation
/// operations within the Flutter screen generation service. It defines the
/// parameters and options needed to create new MVC-structured screens.
///
/// Key Components:
/// * [ScreenCreationRequest] - Configuration for screen creation operations
library;

/// Request configuration for screen creation.
///
/// This class encapsulates all the parameters needed to create a new Flutter
/// screen with MVC architecture. It provides configuration for screen naming,
/// project location, conflict resolution, and template selection.
///
/// The request supports various creation modes:
/// * Standard screens with example content and full MVC structure
/// * Blank screens without example content for custom implementation
/// * Force mode to overwrite existing screen files
///
/// Usage:
/// ```dart
/// final request = ScreenCreationRequest(
///   screenName: 'UserProfile',
///   projectPath: '/path/to/flutter/project',
///   force: false,
///   blank: false,
/// );
/// ```
class ScreenCreationRequest {
  /// Creates a screen creation request.
  ///
  /// All parameters define the behavior and configuration for the screen
  /// generation process. The screen name must be a valid Dart identifier
  /// and the project path must point to a valid Flutter project directory.
  ///
  /// Parameters:
  /// * [screenName] - Name of the screen to create (must be valid Dart identifier)
  /// * [projectPath] - Absolute path to the Flutter project directory
  /// * [force] - Whether to overwrite existing screen files (default: false)
  /// * [blank] - Whether to create blank screen without example content (default: false)
  const ScreenCreationRequest({
    required this.screenName,
    required this.projectPath,
    this.force = false,
    this.blank = false,
  });

  /// Name of the screen to create.
  ///
  /// This name is used to generate the screen files and class names following
  /// Flutter naming conventions. The name must be a valid Dart identifier
  /// and will be converted to appropriate cases for different file types:
  /// * PascalCase for class names (e.g., UserProfile)
  /// * snake_case for file names (e.g., user_profile)
  ///
  /// The screen name should be descriptive and follow Flutter naming conventions
  /// for screen components.
  final String screenName;

  /// Path to the Flutter project.
  ///
  /// This should be the absolute path to the root directory of a Flutter project
  /// containing a pubspec.yaml file and lib/ directory. The service will validate
  /// that this path contains a valid Flutter project before proceeding with
  /// screen creation.
  ///
  /// Screen files will be created in the lib/screens/{screen_name}/ subdirectory
  /// of this project path.
  final String projectPath;

  /// Whether to overwrite existing screen files.
  ///
  /// When set to true, the service will overwrite any existing screen files
  /// with the same name. When false (default), the service will throw an
  /// exception if screen files already exist.
  ///
  /// Use with caution as this will permanently delete existing screen
  /// implementations and cannot be undone.
  final bool force;

  /// Whether to create a blank screen without example content.
  ///
  /// When set to true, the service will generate minimal screen files without
  /// example UI components or business logic. This is useful when you want
  /// to implement the screen functionality from scratch.
  ///
  /// When false (default), the service generates screens with example content
  /// and basic UI structure to help developers get started quickly.
  final bool blank;
}
