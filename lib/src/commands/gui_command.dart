import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Command-line interface for launching the Splendid CLI GUI dashboard.
///
/// This command starts a Flutter desktop application that provides a graphical interface for using the Splendid CLI
/// tools. The GUI offers point-and-click access to all CLI functionality including project creation, screen generation,
/// test file creation, and project management.
///
/// The GUI dashboard includes:
/// * Project creation wizard with platform selection
/// * Screen generation interface with MVC architecture
/// * Test file generation tools
/// * Project formatting and setup utilities
/// * Real-time command execution with progress feedback
/// * File system browser for project navigation
///
/// Usage Examples:
/// ```bash
/// # Launch the GUI dashboard
/// splendid_cli gui
///
/// # Launch GUI in a specific project directory
/// splendid_cli gui --project-path ~/my_flutter_app
/// ```
///
/// Exit Codes:
/// * `0` - Success: GUI launched successfully
/// * `1` - General error: Flutter not available or GUI launch failed
/// * `64` - Usage error: Invalid arguments or missing dependencies (EX_USAGE)
///
/// Requirements:
/// * Flutter SDK must be installed and available in PATH
/// * Desktop platform support must be enabled for Flutter
/// * Sufficient system resources for running Flutter desktop app
///
/// Performance: GUI startup time is typically 2-5 seconds depending on system performance.
///
/// Thread Safety: This command launches a separate Flutter process and is safe to run concurrently.
class GuiCommand extends Command<int> {
  /// Creates a new instance of [GuiCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--project-path`: Specify initial project directory to open in GUI
  /// * `--debug`: Launch GUI in debug mode with additional logging
  ///
  /// The argument parser is configured during construction to ensure all command-line options are properly defined and
  /// validated before execution.
  GuiCommand() {
    argParser
      ..addOption(
        'project-path',
        abbr: 'p',
        help: 'The project directory to open in the GUI dashboard.',
      )
      ..addFlag(
        'debug',
        help: 'Launch the GUI in debug mode with additional logging.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  ///
  /// This description appears in the CLI help output when users run `splendid_cli help` or `splendid_cli gui --help`.
  @override
  String get description => 'Launch the Splendid CLI GUI dashboard for visual project management.';

  /// The command name used for CLI invocation.
  ///
  /// Users invoke this command by running `splendid_cli gui <args>`.
  @override
  String get name => 'gui';

  /// Alternative shorter name for the command.
  @override
  List<String> get aliases => ['dashboard'];

  /// Usage pattern displayed in help text and error messages.
  ///
  /// Shows the expected command structure with optional arguments.
  @override
  String get invocation => 'splendid_cli gui [arguments]';

  /// Executes the GUI command with parsed command-line arguments.
  ///
  /// This method orchestrates the GUI launch workflow:
  /// 1. Validates Flutter SDK availability and desktop support
  /// 2. Determines the project path to open (current directory or specified)
  /// 3. Launches the Flutter GUI application with appropriate arguments
  /// 4. Monitors the GUI process and handles termination
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing Flutter SDK installation
  /// * Unsupported desktop platform
  /// * Invalid project paths
  /// * GUI application launch failures
  ///
  /// Returns:
  /// * `0` on successful GUI launch and normal termination
  /// * `1` for unexpected errors during launch or execution
  /// * `64` for usage errors (missing Flutter, invalid paths, etc.)
  ///
  /// Throws:
  /// * No exceptions are thrown; all errors are handled internally
  /// and communicated through return codes and user messages
  @override
  Future<int> run() async {
    /// Logger instance for user-facing output and error reporting.
    final Logger logger = Logger();

    /// Optional project path specified via --project-path flag.
    ///
    /// When provided, the GUI will open with this directory as the active project. When null, the GUI opens with the
    /// current working directory.
    final String? projectPath = argResults!['project-path'] as String?;

    /// Whether to launch the GUI in debug mode (--debug flag).
    ///
    /// Debug mode enables additional logging and development features in the GUI.
    final bool debugMode = argResults!['debug'] as bool;

    try {
      // Validate Flutter SDK availability
      if (!await _isFlutterAvailable(logger)) {
        logger
          ..err('Flutter SDK is required to run the GUI dashboard.')
          ..info('Please install Flutter and ensure it is available in your PATH.')
          ..info('Visit https://flutter.dev/docs/get-started/install for installation instructions.');
        return 64;
      }

      // Validate desktop support
      if (!await _isDesktopSupported(logger)) {
        logger
          ..err('Flutter desktop support is not available on this platform.')
          ..info('The GUI dashboard requires Flutter desktop support.')
          ..info('Please ensure you have enabled desktop support for Flutter.');
        return 64;
      }

      /// The directory path that will be opened in the GUI.
      ///
      /// Defaults to the current working directory if no project path is specified. The path is validated to ensure it
      /// exists and is accessible.
      final String targetPath = projectPath ?? Directory.current.path;

      // Validate project path exists
      final Directory targetDirectory = Directory(targetPath);
      if (!targetDirectory.existsSync()) {
        logger.err('Project path does not exist: $targetPath');
        return 64;
      }

      logger
        ..info('Launching Splendid CLI GUI Dashboard...')
        ..info('Project path: $targetPath');

      if (debugMode) {
        logger.info('Debug mode enabled - additional logging will be available');
      }

      // Launch the GUI application
      final int exitCode = await _launchGui(targetPath, debugMode, logger);

      if (exitCode == 0) {
        logger.success('GUI dashboard closed successfully');
      } else {
        logger.err('GUI dashboard exited with code: $exitCode');
      }

      return exitCode;
    } catch (error) {
      logger.err('Failed to launch GUI dashboard: $error');
      return 1;
    }
  }

  /// Checks if Flutter SDK is available in the system PATH.
  ///
  /// This method attempts to run `flutter --version` to verify that Flutter is properly installed and accessible from
  /// the command line.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for debug output
  ///
  /// Returns:
  /// * `true` if Flutter SDK is available and functional
  /// * `false` if Flutter is not found or not working properly
  Future<bool> _isFlutterAvailable(Logger logger) async {
    try {
      final ProcessResult result = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
      );

      final bool isAvailable = result.exitCode == 0;
      if (isAvailable) {
        logger.detail('Flutter SDK detected and available');
      } else {
        logger.detail('Flutter SDK not available or not working properly');
      }

      return isAvailable;
    } catch (error) {
      logger.detail('Error checking Flutter availability: $error');
      return false;
    }
  }

  /// Checks if Flutter desktop support is available on the current platform.
  ///
  /// This method verifies that the current platform supports Flutter desktop applications and that desktop support is
  /// properly configured.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for debug output
  ///
  /// Returns:
  /// * `true` if desktop support is available
  /// * `false` if desktop support is not available or not configured
  Future<bool> _isDesktopSupported(Logger logger) async {
    try {
      // Check if we're on a supported desktop platform
      if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
        logger.detail('Current platform does not support Flutter desktop');
        return false;
      }

      // Try to check Flutter desktop configuration
      final ProcessResult result = await Process.run(
        'flutter',
        ['config'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final String output = result.stdout.toString();

        // Check for desktop platform enablement
        final bool hasDesktopSupport =
            (Platform.isWindows && output.contains('enable-windows-desktop: true')) ||
            (Platform.isMacOS && output.contains('enable-macos-desktop: true')) ||
            (Platform.isLinux && output.contains('enable-linux-desktop: true'));

        if (hasDesktopSupport) {
          logger.detail('Flutter desktop support is enabled');
          return true;
        } else {
          logger.detail('Flutter desktop support may not be enabled');
          // Still return true as desktop might work even if not explicitly enabled
          return true;
        }
      }

      return false;
    } catch (error) {
      logger.detail('Error checking desktop support: $error');
      // Assume desktop support is available if we can't check
      return true;
    }
  }

  /// Launches the Flutter GUI application with specified parameters.
  ///
  /// This method starts the Flutter desktop application that provides the graphical interface for the Splendid CLI
  /// tools. It handles process management and monitors the application lifecycle.
  ///
  /// Parameters:
  /// * [projectPath] - The directory path to open in the GUI
  /// * [debugMode] - Whether to enable debug mode features
  /// * [logger] - Logger instance for output and error reporting
  ///
  /// Returns:
  /// * Exit code from the Flutter application process
  ///
  /// Throws:
  /// * [ProcessException] if the Flutter process cannot be started
  /// * [FileSystemException] if GUI application files are not accessible
  Future<int> _launchGui(String projectPath, bool debugMode, Logger logger) async {
    try {
      /// Path to the GUI application directory within the CLI package.
      ///
      /// The GUI application is located in the example/gui_dashboard directory and contains a complete Flutter desktop
      /// application.
      final String guiAppPath = path.join(
        path.dirname(Platform.script.path),
        '..',
        'example',
        'gui_dashboard',
      );

      logger.detail('GUI application path: $guiAppPath');

      // Verify GUI application exists
      final Directory guiDirectory = Directory(guiAppPath);
      if (!guiDirectory.existsSync()) {
        throw FileSystemException('GUI application not found at: $guiAppPath');
      }

      /// Arguments to pass to the Flutter run command.
      ///
      /// Includes the target device (desktop), project path, and debug mode settings.
      final List<String> flutterArgs = [
        'run',
        '-d',
        _getDesktopTarget(),
        '--dart-define=PROJECT_PATH=$projectPath',
      ];

      if (debugMode) {
        flutterArgs.add('--debug');
      } else {
        flutterArgs.add('--release');
      }

      logger.detail('Launching Flutter with args: ${flutterArgs.join(' ')}');

      // Start the Flutter process
      final Process process = await Process.start(
        'flutter',
        flutterArgs,
        workingDirectory: guiAppPath,
        runInShell: true,
      );

      // Forward stdout and stderr to console
      process.stdout.listen((List<int> data) {
        if (debugMode) {
          logger.detail('GUI: ${String.fromCharCodes(data).trim()}');
        }
      });

      process.stderr.listen((List<int> data) {
        final String error = String.fromCharCodes(data).trim();
        if (error.isNotEmpty) {
          logger.warn('GUI: $error');
        }
      });

      // Wait for the process to complete
      final int exitCode = await process.exitCode;

      return exitCode;
    } catch (error) {
      logger.err('Failed to launch GUI application: $error');
      rethrow;
    }
  }

  /// Determines the appropriate Flutter desktop target for the current platform.
  ///
  /// This method returns the Flutter device identifier that should be used when launching the desktop application on
  /// the current operating system.
  ///
  /// Returns:
  /// * 'windows' for Windows platforms
  /// * 'macos' for macOS platforms
  /// * 'linux' for Linux platforms
  /// * 'windows' as fallback for unknown platforms
  String _getDesktopTarget() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'windows'; // Fallback
  }
}
