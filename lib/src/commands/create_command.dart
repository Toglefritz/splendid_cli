import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';

import '../services/project_service.dart';
import '../services/project_service/project_creation_request.dart';
import '../services/project_service/project_creation_result.dart';
import '../services/project_service/project_service_error_type.dart';
import '../services/project_service/project_service_exception.dart';

/// Command-line interface for creating new Flutter applications with MVC
/// architecture.
///
/// This command generates a complete Flutter project structure following
/// Splendid's MVC coding standards. It uses Mason bricks to ensure consistent
/// project layout, proper separation of concerns, and adherence to established
/// patterns. The command first creates a Flutter project with specified
/// platform support, then applies the MVC template structure.
///
/// The generated applications include:
/// * Route classes for screen entry points (StatefulWidget)
/// * Controller classes for business logic and state management
/// * View classes for UI presentation (StatelessWidget)
/// * Proper directory structure organized by features
/// * Pre-configured analysis options and formatting rules
/// * Standard dependencies and development tools
/// * Platform support for all Flutter platforms by default
///
/// Usage Examples:
/// ```bash
/// # Create app with all platforms (default)
/// splendid_cli create awesome_app
///
/// # Create app with specific platforms
/// splendid_cli create mobile_app --platforms android,ios
///
/// # Create app in specific directory
/// splendid_cli create cool_app --output-directory ~/projects
///
/// # Force overwrite existing directory
/// splendid_cli create cool_app --force
/// ```
///
/// Exit Codes:
/// * `0` - Success: Application created successfully
/// * `1` - General error: Unexpected failure during generation
/// * `64` - Usage error: Invalid arguments or project name (EX_USAGE)
///
/// Performance: Typical generation time is 2-5 seconds depending on system I/O
/// performance.
///
/// Thread Safety: This command is not thread-safe and should not be run
/// concurrently for the same target directory.
class CreateCommand extends Command<int> {
  /// Service for handling project operations.
  static const ProjectService _projectService = ProjectService.defaultInstance();

  /// Creates a new instance of [CreateCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--output-directory` (-o): Custom target directory for project creation
  /// * `--org`: Organization in reverse domain name notation for app identifiers
  /// * `--platforms`: Comma-separated list of platforms to enable
  /// * `--force`: Overwrite existing directories without confirmation
  ///
  /// The argument parser is configured during construction to ensure all
  /// command-line options are properly defined and validated before execution.
  CreateCommand() {
    argParser
      ..addOption(
        'output-directory',
        abbr: 'o',
        help: 'The desired output directory when creating a new project.',
      )
      ..addOption(
        'org',
        help:
            'The organization responsible for your new Flutter project, in reverse domain name notation.\n'
            'This string is used in Java package names and as prefix in the iOS bundle identifier.\n'
            'Examples: com.example, org.mycompany, io.github.username',
        defaultsTo: 'com.example',
      )
      ..addOption(
        'platforms',
        help:
            'The platforms to enable for this project (comma-separated).\n'
            'Available: android,ios,web,windows,macos,linux\n'
            'Default: all platforms',
        defaultsTo: 'android,ios,web,windows,macos,linux',
      )
      ..addFlag(
        'force',
        help: 'Whether to force project generation.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  ///
  /// This description appears in the CLI help output when users run
  /// `splendid_cli help` or `splendid_cli create --help`.
  @override
  String get description => 'Create a new Flutter app with MVC architecture and platform support.';

  /// The command name used for CLI invocation.
  ///
  /// Users invoke this command by running `splendid_cli create <args>`.
  @override
  String get name => 'create';

  /// Usage pattern displayed in help text and error messages.
  ///
  /// Shows the expected command structure with required and optional arguments.
  /// The project name is required, while flags and options are optional.
  @override
  String get invocation => 'splendid_cli create <project_name> [arguments]';

  /// Executes the create command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete application generation workflow:
  /// 1. Validates command-line arguments and project name
  /// 2. Determines target directory and handles existing directory conflicts
  /// 3. Loads the appropriate Mason brick template
  /// 4. Generates the Flutter project with MVC structure
  /// 5. Provides user feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid project names
  /// * Directory conflicts (existing directories without --force)
  /// * File system permission errors
  /// * Mason brick loading failures
  /// * Template generation errors
  ///
  /// Returns:
  /// * `0` on successful project creation
  /// * `1` for unexpected errors during generation
  /// * `64` for usage errors (missing args, invalid names, etc.)
  ///
  /// Throws:
  /// * No exceptions are thrown; all errors are handled internally
  /// and communicated through return codes and user messages
  @override
  Future<int> run() async {
    /// Logger instance for user-facing output and error reporting.
    ///
    /// Provides structured logging with different levels (info, success, warn,
    /// err) and consistent formatting across all CLI operations.
    final Logger logger = Logger();

    // Validate that a project name was provided as a positional argument
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Project name is required.')
        ..info(usage);

      return 64;
    }

    /// The project name provided by the user as the first positional argument.
    final String projectName = argResults!.rest.first;

    /// Optional custom output directory specified via --output-directory flag.
    final String? outputDirectory = argResults!['output-directory'] as String?;

    /// Organization in reverse domain name notation for app identifiers.
    final String organization = argResults!['org'] as String;

    /// Whether to force overwrite existing directories (--force flag).
    final bool force = argResults!['force'] as bool;

    /// Comma-separated list of platforms to enable for the Flutter project.
    final String platforms = argResults!['platforms'] as String;

    // Create request object
    final ProjectCreationRequest request = ProjectCreationRequest(
      projectName: projectName,
      outputDirectory: outputDirectory,
      platforms: platforms,
      organization: organization,
      force: force,
    );

    try {
      // Show progress messages
      logger
        ..info('Creating Flutter project with platform support...')
        ..info('Preparing for MVC architecture template...')
        ..info('Applying MVC architecture template...');

      // Use service to create project
      final ProjectCreationResult result = await _projectService.createProject(request);

      if (result.success) {
        logger
          ..success('✓ Generated Flutter app: ${result.projectName}')
          ..info('')
          ..info('Next steps:')
          ..info('  cd ${result.targetPath}')
          ..info('  splendid_cli setup')
          ..info('')
          ..info('Or run the setup steps manually:')
          ..info('  flutter pub get')
          ..info('  flutter gen-l10n')
          ..info('  flutter run');

        return 0;
      } else {
        logger.err('Failed to create project: ${result.error}');
        return 1;
      }
    } on ProjectServiceException catch (e) {
      switch (e.type) {
        case ProjectServiceErrorType.invalidProjectName:
          logger
            ..err(e.message)
            ..info('Project name must be a valid Dart package name.');
          return 64;
        case ProjectServiceErrorType.invalidOrganization:
          logger
            ..err(e.message)
            ..info('Organization must be in reverse domain name notation (e.g., com.example).');
          return 64;
        case ProjectServiceErrorType.directoryExists:
          logger
            ..err(e.message)
            ..info('Use --force to overwrite existing directory.');
          return 1;
        case ProjectServiceErrorType.invalidPlatforms:
          logger.err(e.message);
          return 64;
        // A default case is useful to guard against any unforeseen errors.
        // ignore: no_default_cases
        default:
          logger.err('Failed to create project: ${e.message}');
          return 1;
      }
    } catch (error) {
      logger.err('Failed to create project: $error');
      return 1;
    }
  }
}
