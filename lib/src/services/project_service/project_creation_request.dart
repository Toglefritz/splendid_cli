/// Project Creation Request Model
///
/// This file contains the request configuration model for Flutter project
/// creation operations within the Splendid CLI project service. It encapsulates
/// all the parameters needed to create a new Flutter project with MVC
/// architecture.
library;

/// Request configuration for project creation.
///
/// This class encapsulates all the parameters needed to create a new Flutter
/// project, including project metadata, platform configuration, and behavioral
/// options. It serves as a data transfer object between the CLI interface and
/// the project service business logic.
///
/// The request supports:
/// * Custom project naming with validation
/// * Multi-platform project creation
/// * Organization configuration for package naming
/// * Directory management with force overwrite option
class ProjectCreationRequest {
  /// Creates a project creation request.
  ///
  /// All parameters are validated by the ProjectService before processing. The
  /// [projectName] must follow Dart package naming conventions. The
  /// [organization] must be in reverse domain name notation. The [platforms]
  /// string should contain comma-separated platform names.
  ///
  /// Parameters:
  /// * [projectName] - Name of the project to create (required)
  /// * [outputDirectory] - Custom output directory (optional)
  /// * [platforms] - Comma-separated list of platforms to enable
  /// * [organization] - Organization in reverse domain name notation
  /// * [force] - Whether to overwrite existing directories
  const ProjectCreationRequest({
    required this.projectName,
    this.outputDirectory,
    this.platforms = 'android,ios,web,windows,macos,linux',
    this.organization = 'com.example',
    this.force = false,
  });

  /// Name of the project to create.
  ///
  /// Must follow Dart package naming conventions:
  /// * Start with a lowercase letter
  /// * Contain only lowercase letters, numbers, and underscores
  /// * Not start with an underscore
  /// * Be a valid Dart identifier
  ///
  /// Examples: 'my_app', 'todo_manager', 'family_tracker'
  final String projectName;

  /// Optional custom output directory.
  ///
  /// If specified, the project will be created in this directory. If null, the
  /// project will be created in the current working directory. The final
  /// project path will be: outputDirectory/projectName
  final String? outputDirectory;

  /// Comma-separated list of platforms to enable.
  ///
  /// Valid platforms include: android, ios, web, windows, macos, linux The
  /// Flutter CLI will create platform-specific code and configuration for each
  /// specified platform.
  ///
  /// Default includes all platforms for maximum compatibility. Example:
  /// 'android,ios,web' for mobile and web only
  final String platforms;

  /// Organization responsible for the project in reverse domain name notation.
  ///
  /// This string is used in Java package names and as prefix in the iOS bundle
  /// identifier. Must follow reverse domain name format with at least two
  /// segments separated by dots.
  ///
  /// Examples:
  /// * 'com.example' - Generic example organization
  /// * 'org.mycompany' - Company organization
  /// * 'io.github.username' - GitHub-based organization
  /// * 'net.domain.subdomain' - Multi-level domain
  ///
  /// Each segment must:
  /// * Start with a lowercase letter
  /// * Contain only lowercase letters, numbers, and hyphens
  /// * End with a lowercase letter or number
  final String organization;

  /// Whether to overwrite existing directories.
  ///
  /// When true, the service will delete and recreate the target directory if it
  /// already exists. When false, the service will throw an exception if the
  /// target directory exists.
  ///
  /// Use with caution as this will permanently delete existing files.
  final bool force;
}
