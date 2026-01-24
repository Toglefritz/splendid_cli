/// Flutter Device Model
///
/// This file contains the Flutter device model for representing devices
/// available for Flutter application execution within the Splendid CLI project
/// service. It provides structured access to device information returned by
/// Flutter CLI commands and intelligent device categorization for automated
/// device selection.
library;

/// Represents a Flutter device available for running applications.
///
/// This class encapsulates device information returned by `flutter devices
/// --machine`, providing structured access to device properties for intelligent
/// device selection and user feedback. It includes device identification,
/// platform information, and categorization methods for automated selection
/// logic.
///
/// The device information includes:
/// * Unique device identifiers for Flutter CLI commands
/// * Human-readable device names for user display
/// * Platform and target information for compatibility checking
/// * Emulator vs physical device classification
/// * Intelligent device categorization (desktop, web, mobile)
///
/// Device categories are used for selection priority:
/// 1. Desktop devices (Windows, macOS, Linux) - preferred for development
/// 2. Web browsers (Chrome) - universal compatibility
/// 3. Mobile devices (Android, iOS) - platform-specific testing
/// 4. Other devices - fallback options
class FlutterDevice {
  /// Creates a Flutter device instance.
  ///
  /// This constructor creates a device representation with all the information
  /// needed for device selection and user feedback. All required fields must be
  /// provided, while optional fields can be null.
  ///
  /// Parameters:
  /// * [id] - Unique device identifier for Flutter CLI commands
  /// * [name] - Human-readable device name for display
  /// * [targetPlatform] - Platform identifier (e.g., 'android-arm64', 'web-javascript')
  /// * [emulator] - Whether this is an emulator or physical device
  /// * [category] - Optional device category classification
  /// * [platformType] - Optional platform type classification
  const FlutterDevice({
    required this.id,
    required this.name,
    required this.targetPlatform,
    required this.emulator,
    this.category,
    this.platformType,
  });

  /// Creates a Flutter device from JSON data returned by `flutter devices
  /// --machine`.
  ///
  /// This factory constructor parses the JSON structure returned by Flutter's
  /// device listing command, handling type safety and providing defaults for
  /// missing or malformed data.
  ///
  /// The JSON structure follows Flutter's device listing format:
  /// ```json
  /// {
  /// "id": "chrome",
  /// "name": "Chrome",
  /// "targetPlatform": "web-javascript",
  /// "emulator": false,
  /// "category": "web",
  /// "platformType": "web"
  /// }
  /// ```
  ///
  /// The parser handles:
  /// * Type mismatches by converting values to expected types
  /// * Missing fields by providing sensible defaults
  /// * Null values by using fallback values
  ///
  /// Parameters:
  /// * [json] - JSON map containing device information from Flutter CLI
  ///
  /// Returns a FlutterDevice instance with parsed and validated data.
  factory FlutterDevice.fromJson(Map<String, dynamic> json) {
    return FlutterDevice(
      id: _safeStringFromJson(json['id']) ?? '',
      name: _safeStringFromJson(json['name']) ?? 'Unknown Device',
      targetPlatform: _safeStringFromJson(json['targetPlatform']) ?? '',
      emulator: _safeBoolFromJson(json['emulator']) ?? false,
      category: _safeStringFromJson(json['category']),
      platformType: _safeStringFromJson(json['platformType']),
    );
  }

  /// Safely extracts a string value from JSON, handling type mismatches.
  ///
  /// This helper method provides robust string extraction from JSON data,
  /// handling cases where the value might be null, a different type, or need
  /// conversion to string format.
  ///
  /// Parameters:
  /// * [value] - The JSON value to convert to string
  ///
  /// Returns the string value or null if the value is null.
  static String? _safeStringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// Safely extracts a boolean value from JSON, handling type mismatches.
  ///
  /// This helper method provides robust boolean extraction from JSON data,
  /// handling cases where the value might be a string, integer, or other type
  /// that needs conversion to boolean.
  ///
  /// Parameters:
  /// * [value] - The JSON value to convert to boolean
  ///
  /// Returns the boolean value or null if the value is null. String values are
  /// parsed case-insensitively ('true' -> true). Integer values use standard
  /// truthiness (0 -> false, non-zero -> true).
  static bool? _safeBoolFromJson(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value != 0;
    }
    return false;
  }

  /// Unique identifier for the device (used with flutter run -d).
  ///
  /// This ID is used in Flutter CLI commands to specify which device should be
  /// used for running applications. It must match exactly with the ID returned
  /// by 'flutter devices' command.
  ///
  /// Examples: 'chrome', 'windows', 'android-emulator', 'iPhone-simulator'
  final String id;

  /// Human-readable name of the device.
  ///
  /// This name is displayed to users in device selection interfaces and
  /// feedback messages. It should be descriptive enough for users to identify
  /// the device among multiple options.
  ///
  /// Examples: 'Chrome', 'Windows (desktop)', 'Pixel 4 API 30', 'iPhone 12 Pro
  /// Max'
  final String name;

  /// Target platform identifier (e.g., 'android-arm64', 'web-javascript').
  ///
  /// This identifier specifies the target platform and architecture for the
  /// device. It's used internally by Flutter for build configuration and
  /// compatibility checking.
  ///
  /// Common values:
  /// * 'web-javascript' - Web browsers
  /// * 'android-arm64' - Android devices (64-bit ARM)
  /// * 'ios' - iOS devices and simulators
  /// * 'windows-x64' - Windows desktop (64-bit)
  /// * 'macos' - macOS desktop
  /// * 'linux-x64' - Linux desktop (64-bit)
  final String targetPlatform;

  /// Whether this device is an emulator or physical device.
  ///
  /// This flag distinguishes between physical hardware and emulated/simulated
  /// devices. It can be useful for:
  /// * Performance considerations (physical devices typically perform better)
  /// * Testing strategies (emulators for automated testing, devices for user testing)
  /// * Development workflows (emulators for quick iteration, devices for final testing)
  final bool emulator;

  /// Optional category classification of the device.
  ///
  /// This field provides a high-level categorization of the device type, which
  /// can be used for grouping and selection logic. Common categories include
  /// 'web', 'mobile', 'desktop'.
  ///
  /// This field may be null if the Flutter CLI doesn't provide category
  /// information for the device.
  final String? category;

  /// Optional platform type classification.
  ///
  /// This field provides additional platform type information that may differ
  /// from or supplement the category field. It's used for more granular device
  /// classification and selection logic.
  ///
  /// This field may be null if the Flutter CLI doesn't provide platform type
  /// information for the device.
  final String? platformType;

  /// Returns a string representation of the device for debugging.
  ///
  /// This provides a concise representation of the device including its key
  /// identifying information. It's useful for logging, debugging, and
  /// development purposes.
  ///
  /// Format: 'FlutterDevice(id: [id], name: [name], platform:
  /// [targetPlatform])'
  @override
  String toString() => 'FlutterDevice(id: $id, name: $name, platform: $targetPlatform)';

  /// Converts the device back to JSON format.
  ///
  /// This method serializes the device information back to the JSON format
  /// expected by Flutter CLI tools. It includes all non-null fields and
  /// maintains compatibility with the original JSON structure.
  ///
  /// Returns a `Map<String, dynamic>` suitable for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetPlatform': targetPlatform,
      'emulator': emulator,
      if (category != null) 'category': category,
      if (platformType != null) 'platformType': platformType,
    };
  }

  /// Checks if this device is a desktop device.
  ///
  /// Desktop devices include Windows, macOS, and Linux platforms. These are
  /// typically preferred for development due to better tooling, performance,
  /// and debugging capabilities.
  ///
  /// The detection is based on the targetPlatform string, checking for
  /// platform-specific keywords in a case-insensitive manner.
  ///
  /// Returns true if this is a desktop device, false otherwise.
  bool get isDesktop {
    final String platform = targetPlatform.toLowerCase();
    return platform.contains('windows') ||
        platform.contains('macos') ||
        platform.contains('linux') ||
        platform.contains('darwin');
  }

  /// Checks if this device is a web device.
  ///
  /// Web devices include browsers and web-based targets. These provide
  /// universal compatibility and are good for testing responsive designs and
  /// cross-platform functionality.
  ///
  /// The detection is based on the targetPlatform string, checking for
  /// web-specific keywords in a case-insensitive manner.
  ///
  /// Returns true if this is a web device, false otherwise.
  bool get isWeb {
    final String platform = targetPlatform.toLowerCase();
    return platform.contains('web') || platform.contains('chrome');
  }

  /// Checks if this device is a mobile device.
  ///
  /// Mobile devices include Android and iOS platforms, both physical devices
  /// and emulators/simulators. These are essential for testing mobile-specific
  /// functionality, performance, and user experience.
  ///
  /// The detection is based on the targetPlatform string, checking for mobile
  /// platform keywords in a case-insensitive manner.
  ///
  /// Returns true if this is a mobile device, false otherwise.
  bool get isMobile {
    final String platform = targetPlatform.toLowerCase();
    return platform.contains('android') || platform.contains('ios');
  }
}
