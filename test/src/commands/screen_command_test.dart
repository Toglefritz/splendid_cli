import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for ScreenCommand functionality.
///
/// This test suite covers the screen generation command including validation,
/// error handling, and successful screen creation with MVC architecture.
///
/// Test Categories:
/// * Command validation and error handling
/// * Flutter project detection
/// * Screen name validation
/// * File generation and structure
/// * Force flag behavior
///
/// Test Environment:
/// * Uses temporary directories for isolated testing
/// * Creates minimal Flutter project structure for testing
/// * Cleans up all test artifacts after completion
void main() {
  group('ScreenCommand', () {
    late TempDirectoryHelper tempDirHelper;

    /// Set up test environment with temporary directory management.
    ///
    /// Creates a fresh temporary directory for each test to ensure isolation
    /// and prevent test interference.
    setUp(() {
      tempDirHelper = TempDirectoryHelper();
    });

    /// Clean up test environment after each test.
    ///
    /// Removes temporary directories and any generated files to prevent
    /// test artifacts from accumulating on the file system.
    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('validation', () {
      /// Verifies that the command fails when no screen name is provided.
      ///
      /// This test ensures that the command provides clear error messages
      /// when required arguments are missing.
      test('should fail when no screen name provided', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'screen'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Screen name is required.'));
      });

      /// Verifies that the command fails when run outside a Flutter project.
      ///
      /// This test ensures that the command properly detects Flutter project
      /// structure and prevents execution in inappropriate directories.
      test('should fail when not in Flutter project', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'test'],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Not in a Flutter project directory.'));
      });

      /// Verifies that the command rejects invalid screen names.
      ///
      /// This test ensures that screen names follow Dart identifier rules
      /// and provides helpful error messages for invalid names.
      test('should fail with invalid screen name', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', '123invalid'],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Invalid screen name: 123invalid'));
      });
    });

    group('screen generation', () {
      /// Tests successful screen generation with valid input.
      ///
      /// This test verifies the complete happy path workflow:
      /// 1. Screen files are created in correct directory structure
      /// 2. All three MVC files (route, controller, view) are generated
      /// 3. Files contain expected class names and structure
      /// 4. Success message is displayed to user
      test('should generate screen successfully', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'game'],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('✓ Generated screen: game'));

        // Verify screen files were created
        final String screenPath = path.join(tempDirHelper.directoryPath, 'lib', 'screens', 'game');
        expect(Directory(screenPath).existsSync(), isTrue);

        final List<String> expectedFiles = [
          'game_route.dart',
          'game_controller.dart',
          'game_view.dart',
        ];

        for (final String fileName in expectedFiles) {
          final File file = File(path.join(screenPath, fileName));
          expect(file.existsSync(), isTrue, reason: 'File $fileName should exist');

          final String content = file.readAsStringSync();
          expect(content, isNotEmpty, reason: 'File $fileName should not be empty');
          expect(content, contains('Game'), reason: 'File $fileName should contain Game class references');
        }
      });

      /// Tests screen generation with PascalCase input name.
      ///
      /// This test verifies that the command properly handles different naming
      /// conventions and converts them to appropriate file and class names.
      test('should handle PascalCase screen names', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'UserProfile'],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('✓ Generated screen: UserProfile'));

        // Verify files are created with snake_case directory name
        final String screenPath = path.join(tempDirHelper.directoryPath, 'lib', 'screens', 'user_profile');
        expect(Directory(screenPath).existsSync(), isTrue);

        // Verify route file contains correct class name
        final File routeFile = File(path.join(screenPath, 'user_profile_route.dart'));
        final String routeContent = routeFile.readAsStringSync();
        expect(routeContent, contains('class UserProfileRoute'));
        expect(routeContent, contains('UserProfileController'));
      });

      /// Tests force flag behavior when screen already exists.
      ///
      /// This test verifies that:
      /// 1. Command fails when screen exists without --force flag
      /// 2. Command succeeds and overwrites when --force flag is used
      /// 3. Warning message is displayed when overwriting
      test('should handle existing screen with force flag', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        // Create screen first time
        final ProcessResult firstResult = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'game'],
          workingDirectory: tempDirHelper.directoryPath,
        );
        expect(firstResult.exitCode, equals(0));

        // Try to create same screen without force flag
        final ProcessResult secondResult = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'game'],
          workingDirectory: tempDirHelper.directoryPath,
        );
        expect(secondResult.exitCode, equals(1));
        expect(secondResult.stderr, contains('Screen game already exists'));

        // Create same screen with force flag
        final ProcessResult thirdResult = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'game', '--force'],
          workingDirectory: tempDirHelper.directoryPath,
        );
        expect(thirdResult.exitCode, equals(0));
        final String output = '${thirdResult.stdout}${thirdResult.stderr}';
        expect(output, contains('Overwriting existing screen: game'));
        expect(thirdResult.stdout, contains('✓ Generated screen: game'));
      });
    });

    group('file content validation', () {
      /// Verifies that generated files contain expected MVC structure.
      ///
      /// This test ensures that the generated files follow the established
      /// MVC patterns and contain the required classes and methods.
      test('should generate files with correct MVC structure', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'test_screen'],
          workingDirectory: tempDirHelper.directoryPath,
        );
        expect(result.exitCode, equals(0));

        final String screenPath = path.join(tempDirHelper.directoryPath, 'lib', 'screens', 'test_screen');

        // Verify route file structure
        final File routeFile = File(path.join(screenPath, 'test_screen_route.dart'));
        final String routeContent = routeFile.readAsStringSync();
        expect(routeContent, contains('class TestScreenRoute extends StatefulWidget'));
        expect(routeContent, contains('TestScreenController()'));

        // Verify controller file structure
        final File controllerFile = File(path.join(screenPath, 'test_screen_controller.dart'));
        final String controllerContent = controllerFile.readAsStringSync();
        expect(controllerContent, contains('class TestScreenController extends State<TestScreenRoute>'));
        expect(controllerContent, contains('onIconSelected'));
        expect(controllerContent, contains('_resetGame'));
        expect(controllerContent, contains('TestScreenView(this)'));

        // Verify view file structure
        final File viewFile = File(path.join(screenPath, 'test_screen_view.dart'));
        final String viewContent = viewFile.readAsStringSync();
        expect(viewContent, contains('class TestScreenView extends StatelessWidget'));
        expect(viewContent, contains('final TestScreenController controller'));
        expect(viewContent, contains('Icons.rocket_launch'));
        expect(viewContent, contains('Icons.restaurant_menu'));
        expect(viewContent, contains('Icons.palette'));
      });

      /// Verifies that generated files contain the icon selection game logic.
      ///
      /// This test ensures that the placeholder content includes the required
      /// icon selection game with proper randomization and user interaction.
      test('should generate icon selection game content', () async {
        // Create minimal Flutter project structure
        await _createMinimalFlutterProject(tempDirHelper.directoryPath);

        final ProcessResult result = await Process.run(
          'dart',
          ['run', path.join(Directory.current.path, 'bin/splendid_cli.dart'), 'screen', 'game'],
          workingDirectory: tempDirHelper.directoryPath,
        );
        expect(result.exitCode, equals(0));

        final String screenPath = path.join(tempDirHelper.directoryPath, 'lib', 'screens', 'game');

        // Verify controller contains game logic
        final File controllerFile = File(path.join(screenPath, 'game_controller.dart'));
        final String controllerContent = controllerFile.readAsStringSync();
        expect(controllerContent, contains('_availableIcons'));
        expect(controllerContent, contains('_currentIcons'));
        expect(controllerContent, contains('_targetIcon'));
        expect(controllerContent, contains('Random'));
        expect(controllerContent, contains('shuffle'));

        // Verify view contains game UI
        final File viewFile = File(path.join(screenPath, 'game_view.dart'));
        final String viewContent = viewFile.readAsStringSync();
        expect(viewContent, contains('Select the'));
        expect(viewContent, contains('GestureDetector'));
        expect(viewContent, contains('onIconSelected'));
        expect(viewContent, contains('_getIconName'));
      });
    });
  });
}

/// Creates a minimal Flutter project structure for testing.
///
/// This helper function creates the minimum files and directories needed
/// for the screen command to recognize a valid Flutter project.
///
/// Parameters:
/// * [projectPath] - Path where the Flutter project structure should be created
///
/// Creates:
/// * `pubspec.yaml` with Flutter dependency
/// * `lib/` directory for Dart source files
/// * Basic project structure for command validation
Future<void> _createMinimalFlutterProject(String projectPath) async {
  // Create lib directory
  await Directory(path.join(projectPath, 'lib')).create(recursive: true);

  // Create minimal pubspec.yaml with Flutter dependency
  final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_project
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
  uses-material-design: true
''');
}
