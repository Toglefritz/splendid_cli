import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

import '../services/project_service.dart';
import '../services/project_service/device_selection_info.dart';
import '../services/project_service/flutter_device.dart';
import '../services/project_service/project_service_error_type.dart';
import '../services/project_service/project_service_exception.dart';
import '../services/project_service/project_setup_request.dart';
import '../services/project_service/project_setup_result.dart';

/// Command-line interface for setting up a Flutter project after creation.
///
/// This command automates the post-creation setup process by running the
/// standard Flutter commands needed to prepare a project for development:
/// * `flutter pub get` - Downloads and installs dependencies
/// * `flutter gen-l10n` - Generates localization files
/// * `flutter run` - Launches the application (optional)
///
/// The command must be run from within a Flutter project directory or a parent
/// directory containing Flutter projects. It automatically detects Flutter
/// projects and provides options for batch setup of multiple projects.
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
/// Performance: Typical setup time is 10-30 seconds depending on dependency
/// count and network speed for downloading packages.
///
/// Thread Safety: This command is safe to run concurrently on different
/// projects but should not be run multiple times on the same project
/// simultaneously.
class SetupCommand extends Command<int> {
  /// Service for handling project operations.
  static const ProjectService _projectService = ProjectService();

  /// Creates a new instance of [SetupCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--project` (-p): Specify a specific project directory to setup
  /// * `--device` (-d): Specify a device ID for flutter run
  /// * `--no-run`: Skip the flutter run step
  /// * `--verbose` (-v): Enable verbose output from Flutter commands
  SetupCommand() {
    argParser
      ..addOption(
        'project',
        abbr: 'p',
        help: 'The Flutter project directory to setup. Defaults to current directory.',
      )
      ..addOption(
        'device',
        abbr: 'd',
        help: 'Device ID to use for flutter run. If not specified, automatically selects the best available device.',
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
  /// Each step is executed sequentially and the command fails fast if any step
  /// encounters an error. Progress is reported to the user throughout the
  /// process.
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

    /// Optional device ID to use for flutter run.
    final String? deviceId = argResults!['device'] as String?;

    /// Whether to run the Flutter app after completing setup.
    final bool shouldRun = argResults!['run'] as bool;

    /// Whether to enable verbose output from Flutter commands.
    final bool verbose = argResults!['verbose'] as bool;

    // Create request object
    final ProjectSetupRequest request = ProjectSetupRequest(
      projectPath: targetPath,
      runApp: shouldRun,
      verbose: verbose,
      deviceId: deviceId,
    );

    try {
      final String projectName = path.basename(targetPath);
      logger
        ..info('Setting up Flutter project: $projectName')
        // Show progress messages
        ..info('📦 Installing dependencies...')
        ..info('🌐 Generating localizations...');

      // Get device selection info before running if we're going to run the app
      DeviceSelectionInfo? deviceInfo;
      if (shouldRun) {
        try {
          deviceInfo = await _projectService.getDeviceSelection(
            targetPath,
            deviceId: deviceId,
          );

          // Show device selection information before running
          _showDeviceSelectionInfo(logger, deviceInfo);

          logger
            ..info('🚀 Starting application...')
            ..info('Press Ctrl+C to stop the application when ready.');
        } catch (e) {
          // If device selection fails, we'll let the setup process handle it
          logger
            ..info('🚀 Starting application...')
            ..info('Press Ctrl+C to stop the application when ready.');
        }
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

  /// Shows device selection information to the user.
  ///
  /// Provides feedback about which device was selected and why, especially
  /// useful when multiple devices are available and automatic selection occurs.
  void _showDeviceSelectionInfo(Logger logger, DeviceSelectionInfo deviceInfo) {
    final FlutterDevice selectedDevice = deviceInfo.selectedDevice;
    final List<FlutterDevice> availableDevices = deviceInfo.availableDevices;
    final String reason = deviceInfo.selectionReason;

    // Only show device selection info if there were multiple devices or if user
    // specified one
    if (availableDevices.length > 1 || reason == 'User specified') {
      logger
        ..info('')
        ..info('📱 Device Selection:')
        ..info('   Selected: ${selectedDevice.name} (${selectedDevice.id})')
        ..info('   Reason: $reason');

      // Show other available devices if there were multiple options
      if (availableDevices.length > 1) {
        final List<FlutterDevice> otherDevices = availableDevices.where((d) => d.id != selectedDevice.id).toList();

        if (otherDevices.isNotEmpty) {
          logger
            ..info('   Other available: ${otherDevices.map((d) => '${d.name} (${d.id})').join(', ')}')
            ..info('   💡 Use --device=<id> to specify a different device');
        }
      }
    }
  }
}
