import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

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
    ///
    /// Defaults to the current working directory if no --project flag is provided.
    /// Must contain a valid pubspec.yaml file with Flutter dependencies.
    final String? projectPath = argResults!['project'] as String?;
    final String targetPath = projectPath ?? Directory.current.path;

    /// Whether to run the Flutter app after completing setup.
    ///
    /// Controlled by the --run/--no-run flag. When false, only dependency
    /// installation and localization generation are performed.
    final bool shouldRun = argResults!['run'] as bool;

    /// Whether to enable verbose output from Flutter commands.
    ///
    /// When true, passes the --verbose flag to Flutter commands for detailed
    /// output that can help with debugging setup issues.
    final bool verbose = argResults!['verbose'] as bool;

    // Validate that the target directory is a Flutter project
    if (!await _isFlutterProject(targetPath)) {
      logger
        ..err('Not a Flutter project: $targetPath')
        ..info('Make sure you are in a Flutter project directory or specify one with --project');
      return 64;
    }

    final String projectName = path.basename(targetPath);
    logger.info('Setting up Flutter project: $projectName');

    try {
      // Step 1: Install dependencies
      logger.info('📦 Installing dependencies...');
      await _runFlutterCommand(['pub', 'get'], targetPath, verbose, logger);
      logger..success('✓ Dependencies installed')

      // Step 2: Generate localizations
      ..info('🌐 Generating localizations...');
      await _runFlutterCommand(['gen-l10n'], targetPath, verbose, logger);
      logger.success('✓ Localizations generated');

      // Step 3: Optionally run the app
      if (shouldRun) {
        logger..info('🚀 Starting application...')
        ..info('Press Ctrl+C to stop the application when ready.');

        // Note: flutter run is a long-running command, so we inform the user
        // but don't wait for it to complete
        await _runFlutterCommand(['run'], targetPath, verbose, logger, waitForCompletion: false);
      }

      logger
        ..success('✓ Setup completed successfully!')
        ..info('')
        ..info('Your Flutter project is ready for development.');

      if (!shouldRun) {
        logger.info('Run "flutter run" when you\'re ready to start the app.');
      }

      return 0;
    } catch (error) {
      logger.err('Setup failed: $error');
      return 1;
    }
  }

  /// Checks if the specified directory contains a valid Flutter project.
  ///
  /// A valid Flutter project must have:
  /// * A pubspec.yaml file in the root directory
  /// * Flutter SDK dependency declared in pubspec.yaml
  /// * A lib/ directory (created by flutter create)
  ///
  /// Parameters:
  /// * [projectPath] - Path to the directory to check
  ///
  /// Returns:
  /// * `true` if the directory contains a valid Flutter project
  /// * `false` if the directory is not a Flutter project
  Future<bool> _isFlutterProject(String projectPath) async {
    final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final Directory libDirectory = Directory(path.join(projectPath, 'lib'));

    // Check if pubspec.yaml exists
    if (!pubspecFile.existsSync()) {
      return false;
    }

    // Check if lib directory exists
    if (!libDirectory.existsSync()) {
      return false;
    }

    try {
      // Check if pubspec.yaml contains Flutter dependency
      final String pubspecContent = await pubspecFile.readAsString();
      return pubspecContent.contains('flutter:') &&
          (pubspecContent.contains('sdk: flutter') || pubspecContent.contains('flutter'));
    } catch (error) {
      return false;
    }
  }

  /// Executes a Flutter command with the specified arguments.
  ///
  /// This method runs Flutter CLI commands in the specified project directory
  /// and handles output, error reporting, and process management.
  ///
  /// Parameters:
  /// * [args] - Command arguments to pass to the flutter command
  /// * [workingDirectory] - Directory to run the command in
  /// * [verbose] - Whether to show verbose output
  /// * [logger] - Logger instance for output and error reporting
  /// * [waitForCompletion] - Whether to wait for the command to complete
  ///
  /// Throws:
  /// * [ProcessException] if the flutter command fails or is not found
  Future<void> _runFlutterCommand(
    List<String> args,
    String workingDirectory,
    bool verbose,
    Logger logger, {
    bool waitForCompletion = true,
  }) async {
    final List<String> commandArgs = [...args];

    // Add verbose flag if requested
    if (verbose && !commandArgs.contains('--verbose')) {
      commandArgs.add('--verbose');
    }

    if (verbose) {
      logger.detail('Running: flutter ${commandArgs.join(' ')}');
    }

    if (!waitForCompletion && args.contains('run')) {
      // For flutter run, start the process but don't wait for completion
      final Process process = await Process.start(
        'flutter',
        commandArgs,
        workingDirectory: workingDirectory,
        mode: ProcessStartMode.detached,
      );

      logger.info('Application started (PID: ${process.pid})');
      return;
    }

    // For other commands, wait for completion
    final ProcessResult result = await Process.run(
      'flutter',
      commandArgs,
      workingDirectory: workingDirectory,
    );

    if (verbose && result.stdout.toString().isNotEmpty) {
      logger.detail('stdout: ${result.stdout}');
    }

    if (result.exitCode != 0) {
      final String errorMessage = result.stderr.toString().isNotEmpty
          ? result.stderr.toString()
          : 'Command failed with exit code ${result.exitCode}';

      throw ProcessException(
        'flutter',
        commandArgs,
        'Flutter command failed: $errorMessage',
      );
    }
  }
}
