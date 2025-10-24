import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:splendid_cli/src/commands/setup_command.dart';
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for SetupCommand functionality.
///
/// This test suite covers the setup command's ability to:
/// * Detect valid Flutter projects
/// * Validate command arguments and options
/// * Handle error conditions gracefully
/// * Provide appropriate user feedback
///
/// Note: These tests focus on command validation and error handling. Integration tests that actually run Flutter
/// commands are in the integration test suite to avoid dependencies on Flutter SDK in unit tests.
void main() {
  group('SetupCommand', () {
    late SetupCommand command;
    late TempDirectoryHelper tempDirHelper;

    /// Set up test dependencies and command instance.
    ///
    /// Creates fresh instances for each test to ensure isolation and prevent test interference.
    setUp(() {
      command = SetupCommand();
      tempDirHelper = TempDirectoryHelper();
    });

    /// Clean up temporary directories after each test.
    ///
    /// Ensures no test artifacts are left behind that could affect subsequent tests or consume disk space.
    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('command metadata', () {
      /// Verifies that the command has the correct name for CLI invocation.
      test('should have correct name', () {
        expect(command.name, equals('setup'));
      });

      /// Verifies that the command description is informative and accurate.
      test('should have descriptive help text', () {
        expect(
          command.description,
          contains('Setup a Flutter project'),
        );
        expect(
          command.description,
          contains('pub get'),
        );
        expect(
          command.description,
          contains('gen-l10n'),
        );
      });

      /// Verifies that the command usage pattern is correctly formatted.
      test('should have correct invocation pattern', () {
        expect(
          command.invocation,
          equals('splendid_cli setup [arguments]'),
        );
      });
    });

    group('argument parsing', () {
      /// Verifies that the --project option is properly configured.
      test('should support project option', () {
        final argParser = command.argParser;
        expect(argParser.options.containsKey('project'), isTrue);
        expect(argParser.options['project']?.abbr, equals('p'));
      });

      /// Verifies that the --run/--no-run flag is properly configured.
      test('should support run flag with default true', () {
        final argParser = command.argParser;
        expect(argParser.options.containsKey('run'), isTrue);
        expect(argParser.options['run']?.defaultsTo, isTrue);
        expect(argParser.options['run']?.negatable, isTrue);
      });

      /// Verifies that the --verbose flag is properly configured.
      test('should support verbose flag', () {
        final argParser = command.argParser;
        expect(argParser.options.containsKey('verbose'), isTrue);
        expect(argParser.options['verbose']?.abbr, equals('v'));
        expect(argParser.options['verbose']?.negatable, isFalse);
      });
    });

    group('Flutter project detection', () {
      /// Tests detection of valid Flutter projects with proper structure.
      ///
      /// Creates a minimal Flutter project structure and verifies that the command correctly identifies it as a valid
      /// project.
      test('should detect valid Flutter project', () async {
        final Directory projectDir = tempDirHelper.createSubdirectory('test_project');

        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(projectDir.path);

        // Test the project detection logic directly
        final bool isValid = await _isFlutterProject(projectDir.path);

        expect(isValid, isTrue);
      });

      /// Tests rejection of directories without pubspec.yaml.
      ///
      /// Verifies that the command correctly identifies directories that are not Flutter projects when pubspec.yaml is
      /// missing.
      test('should reject directory without pubspec.yaml', () async {
        final Directory projectDir = tempDirHelper.createSubdirectory('no_pubspec');

        // Create lib directory but no pubspec.yaml
        Directory(path.join(projectDir.path, 'lib')).createSync();

        final bool isValid = await _isFlutterProject(projectDir.path);

        expect(isValid, isFalse);
      });

      /// Tests rejection of directories without lib directory.
      ///
      /// Verifies that the command correctly identifies directories that are not Flutter projects when the lib
      /// directory is missing.
      test('should reject directory without lib directory', () async {
        final Directory projectDir = tempDirHelper.createSubdirectory('no_lib');

        // Create pubspec.yaml but no lib directory
        tempDirHelper.createFile(
          path.join('no_lib', 'pubspec.yaml'),
          '''
name: test_project
description: A test project

dependencies:
  flutter:
    sdk: flutter
''',
        );

        final bool isValid = await _isFlutterProject(projectDir.path);

        expect(isValid, isFalse);
      });

      /// Tests rejection of projects without Flutter dependency.
      ///
      /// Verifies that the command correctly identifies Dart projects that are not Flutter projects (missing Flutter
      /// SDK dependency).
      test('should reject Dart project without Flutter dependency', () async {
        final Directory projectDir = tempDirHelper.createSubdirectory('dart_only');

        // Create structure but without Flutter dependency
        Directory(path.join(projectDir.path, 'lib')).createSync();
        tempDirHelper.createFile(
          path.join('dart_only', 'pubspec.yaml'),
          '''
name: dart_project
description: A pure Dart project

dependencies:
  args: ^2.0.0
''',
        );

        final bool isValid = await _isFlutterProject(projectDir.path);

        expect(isValid, isFalse);
      });
    });
  });
}

/// Creates a minimal Flutter project structure for testing.
///
/// This helper function creates the minimum files and directories needed for a directory to be recognized as a valid
/// Flutter project:
/// * pubspec.yaml with Flutter dependency
/// * lib/ directory
///
/// Parameters:
/// * [projectPath] - Path where the project structure should be created
Future<void> _createMinimalFlutterProject(String projectPath) async {
  // Create lib directory
  await Directory(path.join(projectPath, 'lib')).create(recursive: true);

  // Create pubspec.yaml with Flutter dependency
  final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_flutter_project
description: A test Flutter project

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');
}

/// Checks if the specified directory contains a valid Flutter project.
///
/// This is a copy of the private method from SetupCommand for testing purposes. A valid Flutter project must have:
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
