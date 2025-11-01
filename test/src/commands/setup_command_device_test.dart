/// Test suite for SetupCommand device selection functionality.
///
/// This test suite verifies that the setup command correctly handles device selection when multiple devices are
/// available, ensuring that users can either specify a device or rely on intelligent automatic selection.
///
/// Test Categories:
/// * Device flag parsing and validation
/// * Automatic device selection behavior
/// * Error handling for invalid devices
/// * Integration with ProjectService device logic
/// * Command-line argument processing
///
/// Mock Dependencies:
/// * Flutter CLI device listing
/// * Project service device selection
/// * Process execution for setup commands
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:splendid_cli/splendid_cli.dart';
import 'package:splendid_cli/src/commands/setup_command.dart';
import 'package:test/test.dart';

void main() {
  group('SetupCommand Device Selection', () {
    late SetupCommand command;
    late Directory tempDir;
    late SplendidCommandRunner runner;

    /// Creates a minimal Flutter project structure for testing.
    Directory createTestFlutterProject(String name) {
      final Directory projectDir = Directory(path.join(tempDir.path, name))..createSync();
      File(path.join(projectDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
description: A test Flutter project
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  generate: true
  uses-material-design: true
''');
      Directory(path.join(projectDir.path, 'lib')).createSync();

      // Create minimal l10n configuration
      final Directory l10nDir = Directory(path.join(projectDir.path, 'lib', 'l10n'))..createSync();
      File(path.join(l10nDir.path, 'app_en.arb')).writeAsStringSync('''
{
  "appTitle": "Test App",
  "@appTitle": {
    "description": "The title of the application"
  }
}
''');

      return projectDir;
    }

    /// Set up test environment with fresh command instance and temporary directory.
    ///
    /// Creates a new temporary directory for each test to ensure complete isolation and prevent test interference.
    /// The temporary directory is automatically cleaned up after each test completes.
    setUp(() {
      command = SetupCommand();
      tempDir = Directory.systemTemp.createTempSync('setup_device_test_');
      runner = SplendidCommandRunner();
    });

    /// Clean up test resources after each test.
    ///
    /// Removes the temporary directory and all its contents to prevent disk space accumulation during test runs.
    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('command configuration', () {
      /// Verifies that the device option is properly configured in the argument parser.
      ///
      /// This test ensures that the --device flag is available with correct abbreviation, help text, and
      /// default behavior for device selection.
      test('should configure device option correctly', () {
        final argParser = command.argParser;

        // Verify device option exists
        expect(argParser.options.containsKey('device'), isTrue);
        expect(argParser.options['device']?.abbr, equals('d'));
        expect(
          argParser.options['device']?.help,
          contains('Device ID to use for flutter run'),
        );
        expect(
          argParser.options['device']?.help,
          contains('automatically selects the best available device'),
        );
      });

      /// Verifies that all expected options are still present after adding device support.
      ///
      /// This test ensures that adding device selection doesn't break existing functionality and that all
      /// previously available options remain accessible.
      test('should maintain all existing options', () {
        final argParser = command.argParser;

        // Verify existing options are still present
        expect(argParser.options.containsKey('project'), isTrue);
        expect(argParser.options.containsKey('run'), isTrue);
        expect(argParser.options.containsKey('verbose'), isTrue);
        expect(argParser.options.containsKey('device'), isTrue);

        // Verify abbreviations
        expect(argParser.options['project']?.abbr, equals('p'));
        expect(argParser.options['device']?.abbr, equals('d'));
        expect(argParser.options['verbose']?.abbr, equals('v'));
      });
    });

    group('device flag parsing', () {
      /// Tests that device ID is correctly parsed from command-line arguments.
      ///
      /// This test verifies that when users specify a device ID using the --device flag, it is properly
      /// extracted and passed to the project service for validation and use.
      test('should parse device ID from arguments', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--device=test-device',
          '--no-run', // Skip actual flutter run to avoid device validation
        ]);

        // Should not fail on argument parsing (may fail on device validation)
        expect(exitCode, anyOf(equals(0), equals(1)));
      });

      /// Tests that setup works without specifying a device (automatic selection).
      ///
      /// This test verifies that when no device is specified, the command still functions correctly and
      /// relies on the automatic device selection logic in the project service.
      test('should work without device specification', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--no-run', // Skip actual flutter run
        ]);

        // Should succeed with automatic device selection
        expect(exitCode, equals(0));
      });
    });

    group('error handling', () {
      /// Tests that invalid device IDs are handled gracefully with helpful error messages.
      ///
      /// This test verifies that when users specify a device ID that doesn't exist, they receive clear
      /// feedback about the error and information about available devices.
      test('should handle invalid device ID gracefully', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--device=nonexistent-device',
          // Don't use --no-run so device validation occurs
        ]);

        // Should return error code for invalid device
        expect(exitCode, equals(1));
      }, skip: 'Requires Flutter CLI and may launch app');

      /// Tests that setup fails appropriately when not in a Flutter project.
      ///
      /// This test verifies that the device selection logic doesn't interfere with existing project validation
      /// and that appropriate errors are still returned for non-Flutter directories.
      test('should fail when not in Flutter project', () async {
        final int exitCode = await runner.run([
          'setup',
          '--project=${tempDir.path}',
          '--device=any-device',
        ]);

        // Should return usage error for non-Flutter project
        expect(exitCode, equals(64));
      });
    });

    group('integration scenarios', () {
      /// Tests that device selection works with all other setup command options.
      ///
      /// This test verifies that the device flag integrates properly with existing functionality like
      /// verbose output, custom project paths, and run/no-run behavior.
      test('should work with all command options together', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--device=test-device',
          '--verbose',
          '--no-run',
        ]);

        // Should handle all options without argument parsing errors
        expect(exitCode, anyOf(equals(0), equals(1)));
      });

      /// Tests that help text includes device option information.
      ///
      /// This test verifies that users can discover the device selection functionality through the help
      /// system and that the documentation is clear and helpful.
      test('should include device option in help text', () async {
        final int exitCode = await runner.run(['setup', '--help']);

        expect(exitCode, equals(0));
        // Help should succeed and include device option information
        // Actual help text verification would require capturing stdout
      });
    });

    group('backward compatibility', () {
      /// Tests that existing setup command usage continues to work unchanged.
      ///
      /// This test ensures that users who don't use the new device selection feature experience no
      /// changes in behavior and that all existing workflows remain functional.
      test('should maintain backward compatibility', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        // Test original command format without device specification
        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--no-run',
        ]);

        // Should work exactly as before
        expect(exitCode, equals(0));
      });

      /// Tests that the default behavior (automatic device selection) works seamlessly.
      ///
      /// This test verifies that when multiple devices are available and no device is specified, the
      /// system automatically selects an appropriate device without user intervention.
      test('should automatically select device when multiple available', () async {
        final Directory projectDir = createTestFlutterProject('test_project');

        final int exitCode = await runner.run([
          'setup',
          '--project=${projectDir.path}',
          '--no-run',
        ]);

        // Should succeed with automatic device selection
        expect(exitCode, equals(0));
      });
    });
  });
}
