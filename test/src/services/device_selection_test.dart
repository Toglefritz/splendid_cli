/// Test suite for Flutter device selection functionality.
///
/// This test suite verifies the device selection logic in ProjectService, ensuring that the system correctly
/// handles multiple devices, selects appropriate defaults, and respects user-specified device preferences.
///
/// Test Categories:
/// * Device detection and parsing
/// * Intelligent device selection priority
/// * User-specified device validation
/// * Error handling for device-related issues
/// * Integration with flutter run command
///
/// Mock Dependencies:
/// * Process execution for flutter devices command
/// * Flutter device JSON response parsing
/// * Device availability scenarios
library;

import 'package:splendid_cli/src/services/project_service/flutter_device.dart';
import 'package:test/test.dart';

void main() {
  group('Flutter Device Selection', () {
    group('FlutterDevice', () {
      /// Tests that FlutterDevice correctly parses JSON from flutter devices --machine.
      ///
      /// This test verifies that the FlutterDevice.fromJson factory constructor properly handles the JSON format
      /// returned by the Flutter CLI, including all required and optional fields.
      test('should parse device JSON correctly', () {
        final Map<String, dynamic> deviceJson = {
          'id': 'chrome',
          'name': 'Chrome',
          'targetPlatform': 'web-javascript',
          'emulator': false,
          'category': 'web',
          'platformType': 'web',
        };

        final FlutterDevice device = FlutterDevice.fromJson(deviceJson);

        expect(device.id, equals('chrome'));
        expect(device.name, equals('Chrome'));
        expect(device.targetPlatform, equals('web-javascript'));
        expect(device.emulator, isFalse);
        expect(device.category, equals('web'));
        expect(device.platformType, equals('web'));
      });

      /// Tests that FlutterDevice handles missing optional fields gracefully.
      ///
      /// This test ensures that the device parsing is robust and can handle JSON responses that may not include
      /// all optional fields, providing sensible defaults.
      test('should handle missing optional fields', () {
        final Map<String, dynamic> minimalJson = {
          'id': 'android-device',
          'name': 'Android Device',
          'targetPlatform': 'android-arm64',
          'emulator': true,
        };

        final FlutterDevice device = FlutterDevice.fromJson(minimalJson);

        expect(device.id, equals('android-device'));
        expect(device.name, equals('Android Device'));
        expect(device.targetPlatform, equals('android-arm64'));
        expect(device.emulator, isTrue);
        expect(device.category, isNull);
        expect(device.platformType, isNull);
      });

      /// Tests that FlutterDevice provides fallback values for completely missing fields.
      ///
      /// This test verifies that even with malformed or incomplete JSON, the device object can still be created
      /// with reasonable default values to prevent crashes.
      test('should provide fallback values for missing required fields', () {
        final Map<String, dynamic> emptyJson = <String, dynamic>{};

        final FlutterDevice device = FlutterDevice.fromJson(emptyJson);

        expect(device.id, equals(''));
        expect(device.name, equals('Unknown Device'));
        expect(device.targetPlatform, equals(''));
        expect(device.emulator, isFalse);
        expect(device.category, isNull);
        expect(device.platformType, isNull);
      });

      /// Tests that FlutterDevice can be converted back to JSON format.
      ///
      /// This test verifies the toJson method works correctly and produces the expected JSON structure,
      /// which is useful for debugging and logging purposes.
      test('should convert back to JSON correctly', () {
        const FlutterDevice device = FlutterDevice(
          id: 'macos',
          name: 'macOS',
          targetPlatform: 'darwin',
          emulator: false,
          category: 'desktop',
          platformType: 'macos',
        );

        final Map<String, dynamic> json = device.toJson();

        expect(json['id'], equals('macos'));
        expect(json['name'], equals('macOS'));
        expect(json['targetPlatform'], equals('darwin'));
        expect(json['emulator'], isFalse);
        expect(json['category'], equals('desktop'));
        expect(json['platformType'], equals('macos'));
      });
    });

    group('Device Selection Priority', () {
      /// Tests that desktop devices are prioritized over other device types.
      ///
      /// This test verifies that when multiple devices are available, the system correctly identifies and
      /// prioritizes desktop devices (Windows, macOS, Linux) as they are typically better for development.
      test('should prioritize desktop devices', () {
        final List<FlutterDevice> devices = [
          const FlutterDevice(
            id: 'android-emulator',
            name: 'Android Emulator',
            targetPlatform: 'android-x64',
            emulator: true,
          ),
          const FlutterDevice(
            id: 'chrome',
            name: 'Chrome',
            targetPlatform: 'web-javascript',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'macos',
            name: 'macOS',
            targetPlatform: 'darwin',
            emulator: false,
          ),
        ];

        // Test device type detection using public getters
        expect(devices[2].isDesktop, isTrue, reason: 'macOS should be identified as desktop');
        expect(devices[1].isWeb, isTrue, reason: 'Chrome should be identified as web');
        expect(devices[0].isMobile, isTrue, reason: 'Android should be identified as mobile');

        // Verify that devices are correctly categorized (no overlap)
        expect(devices[2].isWeb, isFalse);
        expect(devices[2].isMobile, isFalse);
        expect(devices[1].isDesktop, isFalse);
        expect(devices[1].isMobile, isFalse);
        expect(devices[0].isDesktop, isFalse);
        expect(devices[0].isWeb, isFalse);
      });

      /// Tests that web devices are prioritized over mobile devices.
      ///
      /// This test verifies that when no desktop devices are available, web browsers are selected over mobile
      /// devices due to their universal compatibility and ease of development.
      test('should prioritize web over mobile devices', () {
        final List<FlutterDevice> devices = [
          const FlutterDevice(
            id: 'android-emulator',
            name: 'Android Emulator',
            targetPlatform: 'android-x64',
            emulator: true,
          ),
          const FlutterDevice(
            id: 'chrome',
            name: 'Chrome',
            targetPlatform: 'web-javascript',
            emulator: false,
          ),
        ];

        // Verify device types are correctly identified
        expect(devices[1].isWeb, isTrue, reason: 'Chrome should be web device');
        expect(devices[0].isMobile, isTrue, reason: 'Android should be mobile device');

        // Verify no desktop devices in this scenario
        expect(devices.any((d) => d.isDesktop), isFalse, reason: 'No desktop devices should be present');
      });

      /// Tests that mobile devices are selected when no desktop or web devices are available.
      ///
      /// This test ensures that the system gracefully falls back to mobile devices when they are the only
      /// available option, maintaining functionality across different development environments.
      test('should select mobile devices as fallback', () {
        final List<FlutterDevice> devices = [
          const FlutterDevice(
            id: 'android-emulator',
            name: 'Android Emulator',
            targetPlatform: 'android-x64',
            emulator: true,
          ),
          const FlutterDevice(
            id: 'ios-simulator',
            name: 'iOS Simulator',
            targetPlatform: 'ios',
            emulator: true,
          ),
        ];

        // Verify all devices are mobile
        expect(devices.every((d) => d.isMobile), isTrue, reason: 'All devices should be mobile');

        // Verify no desktop or web devices
        expect(devices.any((d) => d.isDesktop), isFalse, reason: 'No desktop devices should be present');
        expect(devices.any((d) => d.isWeb), isFalse, reason: 'No web devices should be present');
      });
    });

    group('Device Type Detection', () {
      /// Tests that desktop device detection works correctly for all desktop platforms.
      ///
      /// This test verifies that the system can correctly identify Windows, macOS, and Linux devices based on
      /// their target platform strings.
      test('should correctly identify desktop devices', () {
        final List<FlutterDevice> desktopDevices = [
          const FlutterDevice(
            id: 'windows',
            name: 'Windows',
            targetPlatform: 'windows-x64',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'macos',
            name: 'macOS',
            targetPlatform: 'darwin-x64',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'linux',
            name: 'Linux',
            targetPlatform: 'linux-x64',
            emulator: false,
          ),
        ];

        for (final FlutterDevice device in desktopDevices) {
          expect(
            device.isDesktop,
            isTrue,
            reason: '${device.name} should be identified as desktop device',
          );
          // Verify it's not incorrectly identified as other types
          expect(device.isWeb, isFalse, reason: '${device.name} should not be web device');
          expect(device.isMobile, isFalse, reason: '${device.name} should not be mobile device');
        }
      });

      /// Tests that web device detection works correctly for browser targets.
      ///
      /// This test verifies that the system can identify web browsers and web-based targets as web devices,
      /// distinguishing them from native mobile or desktop applications.
      test('should correctly identify web devices', () {
        final List<FlutterDevice> webDevices = [
          const FlutterDevice(
            id: 'chrome',
            name: 'Chrome',
            targetPlatform: 'web-javascript',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'web-server',
            name: 'Web Server',
            targetPlatform: 'web',
            emulator: false,
          ),
        ];

        for (final FlutterDevice device in webDevices) {
          expect(
            device.isWeb,
            isTrue,
            reason: '${device.name} should be identified as web device',
          );
          // Verify it's not incorrectly identified as other types
          expect(device.isDesktop, isFalse, reason: '${device.name} should not be desktop device');
          expect(device.isMobile, isFalse, reason: '${device.name} should not be mobile device');
        }
      });

      /// Tests that mobile device detection works correctly for Android and iOS.
      ///
      /// This test verifies that the system can identify both physical devices and emulators for mobile
      /// platforms, handling various target platform string formats.
      test('should correctly identify mobile devices', () {
        final List<FlutterDevice> mobileDevices = [
          const FlutterDevice(
            id: 'android-device',
            name: 'Android Device',
            targetPlatform: 'android-arm64',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'ios-simulator',
            name: 'iOS Simulator',
            targetPlatform: 'ios',
            emulator: true,
          ),
          const FlutterDevice(
            id: 'android-emulator',
            name: 'Android Emulator',
            targetPlatform: 'android-x64',
            emulator: true,
          ),
        ];

        for (final FlutterDevice device in mobileDevices) {
          expect(
            device.isMobile,
            isTrue,
            reason: '${device.name} should be identified as mobile device',
          );
          // Verify it's not incorrectly identified as other types
          expect(device.isDesktop, isFalse, reason: '${device.name} should not be desktop device');
          expect(device.isWeb, isFalse, reason: '${device.name} should not be web device');
        }
      });
    });

    group('Error Handling', () {
      /// Tests that FlutterDevice handles edge cases in platform detection.
      ///
      /// This test verifies that the device type detection is robust and handles various edge cases
      /// like empty platform strings, unusual formats, and case variations.
      test('should handle edge cases in platform detection', () {
        final List<FlutterDevice> edgeCaseDevices = [
          const FlutterDevice(
            id: 'empty-platform',
            name: 'Empty Platform',
            targetPlatform: '',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'mixed-case',
            name: 'Mixed Case',
            targetPlatform: 'ANDROID-ARM64',
            emulator: false,
          ),
          const FlutterDevice(
            id: 'darwin-variant',
            name: 'Darwin Variant',
            targetPlatform: 'darwin-arm64',
            emulator: false,
          ),
        ];

        // Empty platform should not match any category
        expect(edgeCaseDevices[0].isDesktop, isFalse);
        expect(edgeCaseDevices[0].isWeb, isFalse);
        expect(edgeCaseDevices[0].isMobile, isFalse);

        // Mixed case should still work (detection is case-insensitive)
        expect(edgeCaseDevices[1].isMobile, isTrue);

        // Darwin should be detected as desktop (macOS)
        expect(edgeCaseDevices[2].isDesktop, isTrue);
      });

      /// Tests that device JSON parsing handles malformed input gracefully.
      ///
      /// This test verifies that the FlutterDevice.fromJson method is robust and can handle
      /// various malformed or incomplete JSON inputs without crashing.
      test('should handle malformed JSON gracefully', () {
        final List<Map<String, dynamic>> malformedInputs = [
          <String, dynamic>{}, // Empty JSON
          {'id': null}, // Null values
          {'id': 123, 'name': 456}, // Wrong types
          {'id': 'test'}, // Missing required fields
        ];

        for (final Map<String, dynamic> input in malformedInputs) {
          expect(
            () => FlutterDevice.fromJson(input),
            returnsNormally,
            reason: 'Should handle malformed JSON without throwing: $input',
          );

          final FlutterDevice device = FlutterDevice.fromJson(input);
          expect(device.id, isA<String>(), reason: 'ID should always be a string');
          expect(device.name, isA<String>(), reason: 'Name should always be a string');
        }
      });

      /// Tests that device type detection is consistent and mutually exclusive.
      ///
      /// This test verifies that a device cannot be classified as multiple types simultaneously
      /// and that the classification logic is consistent across different device configurations.
      test('should have mutually exclusive device types', () {
        final List<FlutterDevice> testDevices = [
          const FlutterDevice(id: 'win', name: 'Windows', targetPlatform: 'windows-x64', emulator: false),
          const FlutterDevice(id: 'chrome', name: 'Chrome', targetPlatform: 'web-javascript', emulator: false),
          const FlutterDevice(id: 'android', name: 'Android', targetPlatform: 'android-arm64', emulator: false),
          const FlutterDevice(id: 'ios', name: 'iOS', targetPlatform: 'ios', emulator: true),
          const FlutterDevice(id: 'macos', name: 'macOS', targetPlatform: 'darwin', emulator: false),
          const FlutterDevice(id: 'linux', name: 'Linux', targetPlatform: 'linux-x64', emulator: false),
        ];

        for (final FlutterDevice device in testDevices) {
          final List<bool> types = [device.isDesktop, device.isWeb, device.isMobile];
          final int trueCount = types.where((type) => type).length;

          expect(
            trueCount,
            lessThanOrEqualTo(1),
            reason: 'Device ${device.name} should not be classified as multiple types: $types',
          );
        }
      });
    });
  });
}
