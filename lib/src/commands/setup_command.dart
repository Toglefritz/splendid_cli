import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../services/project_service.dart';

/// Command-line interface for setting up a Flutter project after creation.
///
/// This command automates the post-creation setup process by running the standard
/// Flutter commands needed to prepare a project for development:
/// * `flutter pub get` - Downloads and installs dependencies
/// * `flutter gen-l10n` - Generates localization files
/// * `flutter run` - Launches the application (optional)
///
/// The command must be run from within a Flutter project directory or a parent
/// directory containing Flutter projects. It automatically detects Flutter projects
/// and provides options for batch setup of multiple projects.
///
/// Usage Examples:
/// ```bash
/// # Setup current directory (must be a Flutter project)
/// splendid_cli setup
///
/// # Setup specific project directory
/// splendid_cli setup --project my_app
///
/// # Setup without running the app
/// splendid_cli setup --no-run
///
/// # Setup with verbose output
/// splendid_cli setup --verbose
/// ```
///
/// Exit Codes:
/// * `0` - Success: All setup commands completed successfully
/// * `1` - General error: One or more setup commands failed
/// * `64` - Usage error: Not in a Flutter project or invalid arguments
///
/// Performance: Typical setup time is 10-30 seconds depending on dependency count
/// and network speed for downloading packages.
///
/// Thread Safety: This command is safe to run concurrently on different projects
/// but should not be run multiple times on the same project simultaneously.
class SetupCommand extends Command<int> {
  /// Service for handling project operations.
  static const ProjectService _projectService = ProjectService();

  /// Creates a new instance of [SetupCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--project` (-p): Specify a specific project directory to setup
  /// * `--no-run`: Skip the flutter run step
  /// * `--verbose` (-v): Enable verbose output from Flutter commands
  SetupCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        help: 'The Flutter project directory to setup. Defaults to current directory.',
      )
      ..addFlag(
        'run',
        help: 'Whether to run the app after setup.',
        defaultsTo: true,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output from Flutter commands.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  @override
  String get description => 'Setup a Flutter project by running pub get, gen-l10n, and optionally flutter run.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'setup';

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli setup [arguments]';

  /// Executes the setup command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete setup workflow:
  /// 1. Validates that the target directory is a Flutter project
  /// 2. Runs `flutter pub get` to install dependencies
  /// 3. Runs `flutter gen-l10n` to generate localization files
  /// 4. Optionally runs `flutter run` to launch the application
  ///
  /// Each step is executed sequentially and the command fails fast if any
  /// step encounters an error. Progress is reported to the user throughout
  /// the process.
  ///
  /// Returns:
  /// * `0` on successful completion of all setup steps
  /// * `1` if any setup command fails
  /// * `64` for usage errors (not a Flutter project, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    /// The target project directory to setup.
    final String? projectPath = argResults!['project'] as String?;
    final String targetPath = projectPath ?? Directory.current.path;

    /// Whether to run the Flutter app after completing setup.
    final bool shouldRun = argResults!['run'] as bool;

    /// Whether to enable verbose output from Flutter commands.
    final bool verbose = argResults!['verbose'] as bool;

    // Create request object
    final ProjectSetupRequest request = ProjectSetupRequest(
      projectPath: targetPath,
      runApp: shouldRun,
      verbose: verbose,
    );

    try {
      final String projectName = path.basename(targetPath);
      logger..info('Setting up Flutter project: $projectName')

      // Show progress messages
      ..info('📦 Installing dependencies...')
      ..info('🌐 Generating localizations...');

      if (shouldRun) {
        logger
          ..info('🚀 Starting application...')
          ..info('Press Ctrl+C to stop the application when ready.');
      }

      // Use service to setup project
      final ProjectSetupResult result = await _projectService.setupProject(request);

      if (result.success) {
        logger
          ..success('✓ Dependencies installed')
          ..success('✓ Localizations generated');

        if (shouldRun) {
          logger.success('✓ Application started');
        }

        logger
          ..success('✓ Setup completed successfully!')
          ..info('')
          ..info('Your Flutter project is ready for development.');

        if (!shouldRun) {
          logger.info('Run "flutter run" when you\'re ready to start the app.');
        }

        return 0;
      } else {
        logger.err('Setup failed: ${result.error}');
        return 1;
      }
    } on ProjectServiceException catch (e) {
      switch (e.type) {
        case ProjectServiceErrorType.notFlutterProject:
          logger
            ..err(e.message)
            ..info('Make sure you are in a Flutter project directory or specify one with --project');
          return 64;
        case ProjectServiceErrorType.flutterCommandFailed:
          logger.err('Setup failed: ${e.message}');
          return 1;
        // A default case is useful to guard against any unforeseen errors.
        // ignore: no_default_cases
        default:
          logger.err('Setup failed: ${e.message}');
          return 1;
      }
    } catch (error) {
      logger.err('Setup failed: $error');
      return 1;
    }
  }
}
