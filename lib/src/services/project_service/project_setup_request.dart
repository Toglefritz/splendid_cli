/// Project Setup Request Model
///
/// This file contains the request configuration model for Flutter project setup
/// operations within the Splendid CLI project service. It encapsulates all the
/// parameters needed to set up an existing Flutter project with post-creation
/// configuration and optional application execution.
library;

/// Request configuration for project setup.
///
/// This class encapsulates all the parameters needed to set up an existing
/// Flutter project after creation, including dependency installation,
/// localization generation, and optional application execution with device
/// selection.
///
/// The setup process typically includes:
/// * Running flutter pub get to install dependencies
/// * Running flutter gen-l10n to generate localization files
/// * Optionally running the application on a selected device
/// * Providing verbose output for debugging purposes
class ProjectSetupRequest {
  /// Creates a project setup request.
  ///
  /// The [projectPath] must point to a valid Flutter project directory
  /// containing a pubspec.yaml file and lib directory. The setup process will
  /// validate this before proceeding with any operations.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the Flutter project to setup (required)
  /// * [runApp] - Whether to run the app after setup
  /// * [verbose] - Whether to enable verbose output
  /// * [deviceId] - Optional device ID to use for flutter run
  const ProjectSetupRequest({
    required this.projectPath,
    this.runApp = true,
    this.verbose = false,
    this.deviceId,
  });

  /// Path to the Flutter project to setup.
  ///
  /// This must be a valid Flutter project directory containing:
  /// * pubspec.yaml file with Flutter dependencies
  /// * lib directory with Dart source code
  /// * Standard Flutter project structure
  ///
  /// The path can be absolute or relative to the current working directory. The
  /// service will validate the project structure before proceeding.
  final String projectPath;

  /// Whether to run the app after setup.
  ///
  /// When true, the setup process will execute 'flutter run' after completing
  /// dependency installation and localization generation. This provides
  /// immediate feedback that the project was created and configured correctly.
  ///
  /// When false, only the setup commands (pub get, gen-l10n) are executed,
  /// leaving the application ready to run manually.
  final bool runApp;

  /// Whether to enable verbose output.
  ///
  /// When true, Flutter commands will be executed with verbose flags to provide
  /// detailed output for debugging purposes. This is useful for troubleshooting
  /// setup issues or understanding the build process.
  ///
  /// When false, commands run with standard output levels for cleaner logs.
  final bool verbose;

  /// Optional device ID to use for flutter run.
  ///
  /// If specified, the flutter run command will target this specific device.
  /// The device ID must match one of the available devices returned by 'flutter
  /// devices' command.
  ///
  /// If not specified, the system will automatically select the best available
  /// device based on platform priority:
  /// 1. Desktop devices (Windows, macOS, Linux) - preferred for development
  /// 2. Web browsers (Chrome) - universal compatibility
  /// 3. Mobile devices (Android, iOS) - platform-specific testing
  /// 4. Other devices - fallback options
  ///
  /// Examples: 'chrome', 'windows', 'android-emulator', 'iPhone-simulator'
  final String? deviceId;
}
