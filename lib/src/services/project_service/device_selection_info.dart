/// Device Selection Information Model
///
/// This file contains the device selection information model for Flutter project
/// service operations within the Splendid CLI project service. It encapsulates
/// the results of device selection logic, providing comprehensive information
/// about which device was chosen and why, along with all available alternatives.
library;

import 'flutter_device.dart';

/// Information about device selection during flutter run operations.
///
/// This class encapsulates the results of device selection logic used when
/// running Flutter applications. It provides comprehensive information about:
/// * Which device was selected for application execution
/// * All devices that were available during selection
/// * The reasoning behind the selection decision
///
/// This information is valuable for:
/// * User feedback about automatic device selection
/// * Debugging device selection issues
/// * Understanding why specific devices were chosen
/// * Providing transparency in multi-device environments
///
/// The device selection process follows a priority-based approach:
/// 1. User-specified devices (highest priority)
/// 2. Desktop devices (preferred for development)
/// 3. Web browsers (universal compatibility)
/// 4. Mobile devices (platform-specific testing)
/// 5. Other available devices (fallback)
class DeviceSelectionInfo {
  /// Creates device selection information.
  ///
  /// This constructor captures the complete context of a device selection
  /// operation, including the chosen device, all available alternatives,
  /// and the reasoning behind the selection.
  ///
  /// Parameters:
  /// * [selectedDevice] - The device that was chosen for execution
  /// * [availableDevices] - All devices available during selection
  /// * [selectionReason] - Human-readable explanation of the selection logic
  ///
  /// Example:
  /// ```dart
  /// final info = DeviceSelectionInfo(
  ///   selectedDevice: chromeDevice,
  ///   availableDevices: [chromeDevice, androidDevice, iosDevice],
  ///   selectionReason: 'Automatically selected (web preferred over mobile)',
  /// );
  /// ```
  const DeviceSelectionInfo({
    required this.selectedDevice,
    required this.availableDevices,
    required this.selectionReason,
  });

  /// The device that was selected for running the application.
  ///
  /// This is the device that will be used (or was used) for executing the
  /// Flutter application. It contains complete device information including:
  /// * Device ID for Flutter CLI commands
  /// * Human-readable device name
  /// * Platform and target information
  /// * Emulator vs physical device status
  ///
  /// This device was chosen based on the selection algorithm considering
  /// user preferences, device availability, and platform priorities.
  final FlutterDevice selectedDevice;

  /// List of all available devices when selection occurred.
  ///
  /// This provides complete context about the device selection environment,
  /// showing all options that were considered during the selection process.
  /// It includes devices across all platforms: desktop, web, mobile, and others.
  ///
  /// This information is useful for:
  /// * Understanding why a particular device was chosen
  /// * Debugging device detection issues
  /// * Providing users with information about available alternatives
  /// * Logging and analytics about device usage patterns
  ///
  /// The list includes both physical devices and emulators/simulators that
  /// were detected by the Flutter CLI at the time of selection.
  final List<FlutterDevice> availableDevices;

  /// Human-readable explanation of why this device was selected.
  ///
  /// This provides transparency about the device selection logic, helping
  /// users understand automatic selection decisions. The explanation varies
  /// based on the selection scenario:
  ///
  /// User-specified selection:
  /// * "User specified" - Device was explicitly chosen by the user
  ///
  /// Automatic selection scenarios:
  /// * "Only device available" - Single device detected
  /// * "Automatically selected (desktop preferred for development)" - Desktop device chosen
  /// * "Automatically selected (web preferred over mobile)" - Web device chosen over mobile
  /// * "Automatically selected (mobile device)" - Mobile device chosen as best available
  /// * "Automatically selected" - Generic fallback explanation
  ///
  /// This information helps users understand the system's decision-making
  /// process and provides context for why their application is running on
  /// a particular device.
  final String selectionReason;
}
