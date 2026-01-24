/// Project Setup Result Model
///
/// This file contains the result model for Flutter project setup operations
/// within the Splendid CLI project service. It encapsulates the outcome of
/// project setup attempts, including success/failure status, executed commands,
/// and device selection information for comprehensive user feedback.
library;

import 'flutter_device.dart';

/// Result of project setup operation.
///
/// This class encapsulates the outcome of a Flutter project setup attempt,
/// providing structured information about the setup process including:
/// * Success/failure status and error details
/// * List of commands that were executed during setup
/// * Device selection information when the app was run
/// * Comprehensive metadata for user feedback and debugging
///
/// The setup process typically involves multiple steps (pub get, gen-l10n,
/// run), and this result provides visibility into which steps completed
/// successfully.
class ProjectSetupResult {
  /// Creates a project setup result.
  ///
  /// This constructor is typically used internally by the factory constructors
  /// [ProjectSetupResult.success] and [ProjectSetupResult.failure] which
  /// provide more convenient and type-safe ways to create results.
  ///
  /// Parameters:
  /// * [success] - Whether the operation was successful
  /// * [projectPath] - Path to the project that was setup
  /// * [executedCommands] - List of commands that were executed
  /// * [error] - Error message if operation failed (null for success)
  /// * [selectedDevice] - Device used for running the app (if applicable)
  /// * [availableDevices] - All devices available during selection
  /// * [deviceSelectionReason] - Explanation of device selection logic
  const ProjectSetupResult({
    required this.success,
    required this.projectPath,
    required this.executedCommands,
    this.error,
    this.selectedDevice,
    this.availableDevices,
    this.deviceSelectionReason,
  });

  /// Creates a successful result.
  ///
  /// Use this factory constructor when project setup completes successfully. It
  /// automatically sets success to true and ensures no error message is
  /// included.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the successfully setup project
  /// * [executedCommands] - List of commands that were executed
  /// * [selectedDevice] - Device used for running the app (optional)
  /// * [availableDevices] - All devices available during selection (optional)
  /// * [deviceSelectionReason] - Explanation of device selection (optional)
  const ProjectSetupResult.success({
    required String projectPath,
    required List<String> executedCommands,
    FlutterDevice? selectedDevice,
    List<FlutterDevice>? availableDevices,
    String? deviceSelectionReason,
  }) : this(
         success: true,
         projectPath: projectPath,
         executedCommands: executedCommands,
         selectedDevice: selectedDevice,
         availableDevices: availableDevices,
         deviceSelectionReason: deviceSelectionReason,
       );

  /// Creates a failed result.
  ///
  /// Use this factory constructor when project setup fails for any reason. It
  /// automatically sets success to false, clears the executed commands list,
  /// and requires an error message for user feedback and debugging.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the project where setup was attempted
  /// * [error] - Descriptive error message explaining the failure
  const ProjectSetupResult.failure({
    required String projectPath,
    required String error,
  }) : this(
         success: false,
         projectPath: projectPath,
         executedCommands: const [],
         error: error,
       );

  /// Whether the operation was successful.
  ///
  /// True indicates the project setup completed successfully and the project is
  /// ready for development. False indicates the operation failed and the error
  /// field contains details about what went wrong.
  final bool success;

  /// Path to the project that was setup.
  ///
  /// This is the path to the Flutter project directory where setup operations
  /// were performed, regardless of whether the operation succeeded or failed.
  /// It's useful for user feedback and logging purposes.
  final String projectPath;

  /// List of commands that were executed.
  ///
  /// This provides visibility into which setup steps were completed before any
  /// failure occurred. Common commands include:
  /// * 'flutter pub get' - Dependency installation
  /// * 'flutter gen-l10n' - Localization file generation
  /// * 'flutter run' - Application execution
  ///
  /// For failed operations, this list shows which commands succeeded before the
  /// failure, helping with debugging and recovery.
  final List<String> executedCommands;

  /// Error message if operation failed.
  ///
  /// This field is null for successful operations and contains a descriptive
  /// error message for failed operations. The message should be user-friendly
  /// and provide actionable information when possible.
  ///
  /// Examples:
  /// * 'Directory is not a Flutter project'
  /// * 'flutter pub get failed: network connection timeout'
  /// * 'No devices available for flutter run'
  final String? error;

  /// The device that was selected for running the application.
  ///
  /// This is null if the app was not run (runApp: false) or if device selection
  /// was not needed. When present, it provides information about which device
  /// was chosen for application execution.
  ///
  /// This information is useful for user feedback, especially when automatic
  /// device selection occurs with multiple available devices.
  final FlutterDevice? selectedDevice;

  /// List of all available devices when selection occurred.
  ///
  /// This is null if device detection was not performed or if the app was not
  /// run. When present, it provides complete context about the device selection
  /// process, showing all options that were available.
  ///
  /// This information helps users understand why a particular device was chosen
  /// and what other options were available.
  final List<FlutterDevice>? availableDevices;

  /// Human-readable explanation of why this device was selected.
  ///
  /// This field provides context about the device selection logic, helping
  /// users understand automatic selection decisions. It's null when no device
  /// selection occurred or when device selection was not needed.
  ///
  /// Examples:
  /// * "Automatically selected (desktop preferred for development)"
  /// * "User specified"
  /// * "Only device available"
  /// * "Automatically selected (web preferred over mobile)"
  final String? deviceSelectionReason;
}
