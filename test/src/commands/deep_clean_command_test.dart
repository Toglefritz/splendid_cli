import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for DeepCleanCommand functionality.
///
/// This test suite covers the deep_clean command including validation, error
/// handling, and proper execution flow for Flutter project cleaning operations.
///
/// Test Categories:
/// * Command validation and argument parsing
/// * Flutter project detection and validation
/// * Error handling for non-Flutter projects
/// * Command aliases and help functionality
/// * Integration with Flutter CLI commands
///
/// Mock Dependencies:
/// * TempDirectoryHelper - Creates temporary test directories
/// * Process.run - Executes CLI commands for testing
///
/// Note: These tests focus on command-line interface behavior rather than
/// actual Flutter command execution, which would require a full Flutter setup.
void main() {
  group('DeepCleanCommand', () {
    late TempDirectoryHelper tempDirHelper;

    /// Set up test dependencies and temporary directory.
    ///
    /// Creates a fresh temporary directory for each test to ensure isolation
    /// and prevent test interference. The directory is automatically cleaned up
    /// after each test completes.
    setUp(() {
      tempDirHelper = TempDirectoryHelper();
    });

    /// Clean up resources after each test.
    ///
    /// Ensures proper disposal of temporary directories and clears any
    /// lingering state that could affect subsequent tests.
    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('command validation', () {
      /// Verifies that the command fails gracefully when run in a non-Flutter
      /// directory.
      ///
      /// This test ensures that the command properly validates the target
      /// directory and provides clear error messages when the directory doesn't
      /// contain a valid Flutter project structure.
      test('should fail when directory is not a Flutter project', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
        expect(output, contains('pubspec.yaml'));
        expect(output, contains('lib/'));
        expect(output, contains('Flutter dependencies'));
      });

      /// Verifies that the command works with the short alias 'dc'.
      ///
      /// This test confirms that both the full command name and the short alias
      /// provide identical functionality and error handling behavior.
      test('should work with command alias "dc"', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'dc', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });

      /// Verifies that the command uses current directory when no path is
      /// provided.
      ///
      /// This test ensures that the command defaults to the current working
      /// directory when no explicit project path is specified as an argument.
      test('should use current directory when no path provided', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean'],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });

      /// Verifies that the verbose flag is accepted without causing errors.
      ///
      /// This test confirms that the --verbose flag is properly parsed and
      /// doesn't interfere with the command's basic validation logic.
      test('should accept verbose flag', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', '--verbose', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });
    });

    group('Flutter project detection', () {
      /// Verifies that the command fails when pubspec.yaml is missing.
      ///
      /// This test ensures that the Flutter project validation correctly
      /// identifies directories that lack the required pubspec.yaml file.
      test('should fail when pubspec.yaml is missing', () async {
        // Create lib directory but no pubspec.yaml
        final Directory libDir = Directory(path.join(tempDirHelper.directoryPath, 'lib'));
        await libDir.create();

        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });

      /// Verifies that the command fails when lib directory is missing.
      ///
      /// This test ensures that the Flutter project validation correctly
      /// identifies directories that lack the required lib/ directory
      /// structure.
      test('should fail when lib directory is missing', () async {
        // Create pubspec.yaml but no lib directory
        final File pubspecFile = File(path.join(tempDirHelper.directoryPath, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
''');

        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });

      /// Verifies that the command fails when Flutter dependencies are missing
      /// from pubspec.yaml.
      ///
      /// This test ensures that the Flutter project validation correctly
      /// identifies Dart projects that don't include Flutter-specific
      /// dependencies.
      test('should fail when Flutter dependencies are missing from pubspec.yaml', () async {
        // Create pubspec.yaml without Flutter dependencies
        final File pubspecFile = File(path.join(tempDirHelper.directoryPath, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0
dependencies:
  http: ^0.13.0
''');

        final Directory libDir = Directory(path.join(tempDirHelper.directoryPath, 'lib'));
        await libDir.create();

        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', tempDirHelper.directoryPath],
        );

        expect(result.exitCode, equals(64));
        final String output = '${result.stderr}${result.stdout}';
        expect(output, contains('is not a Flutter project'));
      });

      /// Verifies that the command recognizes a valid Flutter project
      /// structure.
      ///
      /// This test creates a minimal but valid Flutter project structure and
      /// confirms that the command passes the initial validation phase. Note:
      /// The command will still fail due to Flutter SDK requirements, but it
      /// should pass the project structure validation.
      test('should recognize valid Flutter project structure', () async {
        // Create a valid Flutter project structure
        final File pubspecFile = File(path.join(tempDirHelper.directoryPath, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

        final Directory libDir = Directory(path.join(tempDirHelper.directoryPath, 'lib'));
        await libDir.create();

        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', tempDirHelper.directoryPath],
        );

        // Should pass project validation but may fail on Flutter command
        // execution The error should not be about project structure validation
        final String output = '${result.stderr}${result.stdout}';
        expect(output, isNot(contains('is not a Flutter project')));
      });
    });

    group('help and usage', () {
      /// Verifies that the command shows help when --help flag is used.
      ///
      /// This test ensures that the command provides comprehensive help
      /// information when users request it via the --help flag.
      test('should show help with --help flag', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Perform deep cleaning'));
        expect(result.stdout, contains('flutter clean'));
        expect(result.stdout, contains('pub get'));
        expect(result.stdout, contains('gen-l10n'));
        expect(result.stdout, contains('--verbose'));
      });

      /// Verifies that detailed help is available via the help command.
      ///
      /// This test confirms that users can access comprehensive help
      /// information using the 'help deep_clean' command pattern.
      test('should show detailed help via help command', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'help', 'deep_clean'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('USAGE:'));
        expect(result.stdout, contains('DESCRIPTION:'));
        expect(result.stdout, contains('CLEANING STEPS PERFORMED:'));
        expect(result.stdout, contains('EXAMPLES:'));
        expect(result.stdout, contains('WHEN TO USE:'));
        expect(result.stdout, contains('TROUBLESHOOTING:'));
      });

      /// Verifies that detailed help is available for the alias via the help
      /// command.
      ///
      /// This test confirms that the help system properly handles the command
      /// alias and provides the same comprehensive help information.
      test('should show detailed help for alias via help command', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'help', 'dc'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('USAGE:'));
        expect(result.stdout, contains('splendid_cli dc'));
        expect(result.stdout, contains('CLEANING STEPS PERFORMED:'));
      });
    });

    group('command integration', () {
      /// Verifies that the command appears in the general CLI help.
      ///
      /// This test ensures that the deep_clean command is properly registered
      /// and appears in the main help listing with correct description and
      /// alias.
      test('should appear in general CLI help', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('deep_clean (dc)'));
        expect(result.stdout, contains('Perform deep cleaning'));
        expect(result.stdout, contains('flutter clean, pub get, and gen-l10n'));
      });

      /// Verifies that the command is properly registered in the command
      /// runner.
      ///
      /// This test confirms that the command can be found and executed through
      /// the main command runner system without throwing exceptions.
      test('should be properly registered in command runner', () async {
        // Test that the command exists and can be invoked (even if it fails
        // validation)
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'deep_clean', '--help'],
        );

        // Should not get "Unknown command" error
        expect(result.exitCode, equals(0));
        expect(result.stderr, isNot(contains('Unknown command')));
      });
    });
  });
}
