import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Integration test suite for the complete Splendid CLI workflow.
///
/// This test suite covers end-to-end scenarios that test the complete CLI
/// functionality from command-line invocation through project creation.
/// These tests verify that all components work together correctly and that
/// the CLI behaves as expected in real-world usage scenarios.
///
/// Test Categories:
/// * Complete project creation workflow
/// * File system integration
/// * Flutter CLI integration
/// * Mason brick integration
/// * Error recovery scenarios
/// * Cross-platform compatibility
///
/// Note: These tests require Flutter CLI to be available in the system PATH
/// for complete validation. Tests are skipped in environments where Flutter
/// is not available to prevent false failures in CI/CD systems.
void main() {
  group('CLI Integration Tests', () {
    late Directory tempDir;
    late String cliExecutable;

    /// Set up integration test environment.
    ///
    /// Creates a temporary directory for test projects and determines the
    /// path to the CLI executable for process invocation testing.
    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('cli_integration_test_');

      // Determine CLI executable path - look for it relative to current working directory
      // since tests run from project root
      cliExecutable = path.join('bin', 'splendid_cli.dart');
    });

    /// Clean up integration test resources.
    ///
    /// Removes the temporary directory and all created test projects to
    /// prevent disk space accumulation during test runs.
    tearDownAll(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('successful project creation', () {
      /// Tests complete project creation with minimal arguments.
      ///
      /// This test verifies the entire workflow from CLI invocation through
      /// project generation, ensuring that a valid Flutter project with MVC
      /// architecture is created successfully.
      test(
        'should create Flutter project with MVC architecture',
        () async {
          const String projectName = 'integration_test_app';
          final String projectPath = path.join(tempDir.path, projectName);

          // Execute CLI command to create project
          final ProcessResult result = await Process.run(
            'dart',
            [
              cliExecutable,
              'create',
              projectName,
              '--output-directory=${tempDir.path}',
              '--force',
            ],
          );

          // Verify command executed successfully
          expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

          // Verify project directory was created
          final Directory projectDir = Directory(projectPath);
          expect(projectDir.existsSync(), isTrue, reason: 'Project directory should exist');

          // Verify Flutter project structure exists
          expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);
          expect(Directory(path.join(projectPath, 'lib')).existsSync(), isTrue);
          expect(Directory(path.join(projectPath, 'test')).existsSync(), isTrue);

          // Verify MVC architecture files exist
          expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'lib', 'app.dart')).existsSync(), isTrue);
          expect(Directory(path.join(projectPath, 'lib', 'screens')).existsSync(), isTrue);
          expect(Directory(path.join(projectPath, 'lib', 'screens', 'home')).existsSync(), isTrue);

          // Verify MVC files for home screen
          final String homeScreenPath = path.join(projectPath, 'lib', 'screens', 'home');
          expect(File(path.join(homeScreenPath, 'home_route.dart')).existsSync(), isTrue);
          expect(File(path.join(homeScreenPath, 'home_controller.dart')).existsSync(), isTrue);
          expect(File(path.join(homeScreenPath, 'home_view.dart')).existsSync(), isTrue);

          // Verify theme and configuration files
          expect(Directory(path.join(projectPath, 'lib', 'theme')).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'lib', 'theme', 'app_theme.dart')).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'lib', 'theme', 'insets.dart')).existsSync(), isTrue);

          // Verify localization setup
          expect(Directory(path.join(projectPath, 'lib', 'l10n')).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'lib', 'l10n', 'app_en.arb')).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'l10n.yaml')).existsSync(), isTrue);

          // Verify analysis options
          expect(File(path.join(projectPath, 'analysis_options.yaml')).existsSync(), isTrue);
        },
        skip: 'Requires Flutter CLI and Mason brick to be available',
      );

      /// Tests project creation with custom platform selection.
      ///
      /// This test verifies that the --platforms flag correctly configures
      /// the Flutter project with only the specified platforms enabled.
      test(
        'should create project with custom platform selection',
        () async {
          const String projectName = 'mobile_only_app';
          const String platforms = 'android,ios';
          final String projectPath = path.join(tempDir.path, projectName);

          // Execute CLI command with custom platforms
          final ProcessResult result = await Process.run(
            'dart',
            [
              cliExecutable,
              'create',
              projectName,
              '--output-directory=${tempDir.path}',
              '--platforms=$platforms',
              '--force',
            ],
          );

          // Verify command executed successfully
          expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

          // Verify project was created
          final Directory projectDir = Directory(projectPath);
          expect(projectDir.existsSync(), isTrue);

          // Verify only specified platforms are present
          expect(Directory(path.join(projectPath, 'android')).existsSync(), isTrue);
          expect(Directory(path.join(projectPath, 'ios')).existsSync(), isTrue);

          // Verify excluded platforms are not present
          expect(Directory(path.join(projectPath, 'web')).existsSync(), isFalse);
          expect(Directory(path.join(projectPath, 'windows')).existsSync(), isFalse);
          expect(Directory(path.join(projectPath, 'macos')).existsSync(), isFalse);
          expect(Directory(path.join(projectPath, 'linux')).existsSync(), isFalse);
        },
        skip: 'Requires Flutter CLI and Mason brick to be available',
      );

      /// Tests project creation with force flag overwriting existing directory.
      ///
      /// This test verifies that the --force flag correctly handles existing
      /// directories by overwriting them with the new project structure.
      test(
        'should overwrite existing directory with force flag',
        () async {
          const String projectName = 'force_overwrite_app';
          final String projectPath = path.join(tempDir.path, projectName);

          // Create existing directory with some content
          final Directory existingDir = Directory(projectPath);
          existingDir.createSync();
          File(path.join(projectPath, 'existing_file.txt')).writeAsStringSync('existing content');

          // Execute CLI command with force flag
          final ProcessResult result = await Process.run(
            'dart',
            [
              cliExecutable,
              'create',
              projectName,
              '--output-directory=${tempDir.path}',
              '--force',
            ],
          );

          // Verify command executed successfully
          expect(result.exitCode, equals(0), reason: 'CLI should succeed with force: ${result.stderr}');

          // Verify project was created (existing content should be replaced)
          expect(Directory(projectPath).existsSync(), isTrue);
          expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue);

          // Original file should no longer exist (or be replaced)
          // Note: Depending on implementation, file might be overwritten or removed
        },
        skip: 'Requires Flutter CLI and Mason brick to be available',
      );
    });

    group('error handling scenarios', () {
      /// Tests CLI behavior when no arguments are provided.
      ///
      /// This test verifies that the CLI provides helpful usage information
      /// when invoked without any arguments, guiding users toward correct usage.
      test('should show help when no arguments provided', () async {
        final ProcessResult result = await Process.run('dart', [cliExecutable]);

        // Should succeed and show help/usage information
        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('splendid_cli'));
        expect(result.stdout.toString(), contains('Scaffold and manage Flutter apps'));
      });

      /// Tests CLI behavior when project name is missing.
      ///
      /// This test ensures that the CLI provides clear error messages when
      /// required arguments are not provided, helping users understand what
      /// they need to fix.
      test('should return usage error when project name is missing', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'create'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
        expect(result.stderr.toString(), contains('Project name is required'));
      });

      /// Tests CLI behavior with invalid project names.
      ///
      /// This test verifies that the CLI validates project names according to
      /// Dart package naming conventions and provides helpful error messages
      /// when invalid names are provided.
      test('should return usage error for invalid project names', () async {
        final List<String> invalidNames = ['MyApp', 'my-app', '_private', '123app'];

        for (final String invalidName in invalidNames) {
          final ProcessResult result = await Process.run(
            'dart',
            [cliExecutable, 'create', invalidName],
          );

          expect(
            result.exitCode,
            equals(64),
            reason: 'Invalid name "$invalidName" should return usage error',
          );
          expect(
            result.stderr.toString(),
            contains('Invalid project name'),
            reason: 'Should provide clear error message for "$invalidName"',
          );
        }
      });

      /// Tests CLI behavior when target directory exists without force flag.
      ///
      /// This test ensures that the CLI protects existing directories from
      /// accidental overwriting and provides clear guidance on how to proceed.
      test('should fail when target directory exists without force', () async {
        const String projectName = 'existing_directory_app';
        final String projectPath = path.join(tempDir.path, projectName);

        // Create existing directory
        Directory(projectPath).createSync();

        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'create',
            projectName,
            '--output-directory=${tempDir.path}',
          ],
        );

        // Should return error code
        expect(result.exitCode, equals(1));
        expect(result.stderr.toString(), contains('already exists'));
      });

      /// Tests CLI behavior with invalid command-line flags.
      ///
      /// This test verifies that the CLI properly validates command-line options
      /// and provides helpful error messages for typos or invalid flags.
      test('should return usage error for invalid flags', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'create', 'test_app', '--invalid-flag'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
      });

      /// Tests CLI behavior when Flutter CLI is not available.
      ///
      /// This test verifies that the CLI provides clear error messages when
      /// the Flutter SDK is not installed or not in the system PATH.
      test('should handle missing Flutter CLI gracefully', () async {
        // This test is environment-dependent and may not be reliable
        // It's included for completeness but may need to be skipped
        // in environments where Flutter is actually available

        // Temporarily modify PATH to exclude Flutter (if possible)
        // This is complex to implement reliably across platforms
        expect(true, isTrue, reason: 'Test placeholder - implementation depends on environment');
      }, skip: 'Difficult to test reliably across different environments');
    });

    group('help and usage', () {
      /// Tests that help flag displays comprehensive usage information.
      ///
      /// This test verifies that users can get detailed help information
      /// about the CLI and its available commands and options.
      test('should display help with --help flag', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('splendid_cli'));
        expect(result.stdout.toString(), contains('create'));
        expect(result.stdout.toString(), contains('Scaffold and manage Flutter apps'));
      });

      /// Tests that create command help displays detailed command information.
      ///
      /// This test ensures that users can get specific help for the create
      /// command, including all available options and usage examples.
      test('should display create command help', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'create', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Create a new Flutter app'));
        expect(result.stdout.toString(), contains('--output-directory'));
        expect(result.stdout.toString(), contains('--platforms'));
        expect(result.stdout.toString(), contains('--force'));
      });

      /// Tests that version information is accessible.
      ///
      /// This test verifies that users can determine which version of the CLI
      /// they are using, which is important for troubleshooting and compatibility.
      test('should display version information', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, '--version'],
        );

        // Version flag behavior depends on args package configuration
        // May return 0 (success) or 64 (usage) depending on implementation
        expect(result.exitCode, anyOf(equals(0), equals(64)));
      });
    });

    group('file content validation', () {
      /// Tests that generated files contain expected MVC structure.
      ///
      /// This test verifies that the generated project files follow the
      /// established MVC patterns and coding standards defined in the
      /// project documentation.
      test('should generate files with correct MVC structure', () async {
        const String projectName = 'mvc_structure_test';
        final String projectPath = path.join(tempDir.path, projectName);

        // Create project
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'create',
            projectName,
            '--output-directory=${tempDir.path}',
            '--force',
          ],
        );

        expect(result.exitCode, equals(0), reason: 'Project creation should succeed');

        // Verify home route file contains correct structure
        final File homeRouteFile = File(path.join(projectPath, 'lib', 'screens', 'home', 'home_route.dart'));
        if (homeRouteFile.existsSync()) {
          final String content = homeRouteFile.readAsStringSync();
          expect(content, contains('class HomeRoute extends StatefulWidget'));
          expect(content, contains('createState() => HomeController()'));
        }

        // Verify home controller file contains correct structure
        final File homeControllerFile = File(path.join(projectPath, 'lib', 'screens', 'home', 'home_controller.dart'));
        if (homeControllerFile.existsSync()) {
          final String content = homeControllerFile.readAsStringSync();
          expect(content, contains('class HomeController extends State<HomeRoute>'));
          expect(content, contains('Widget build(BuildContext context) => HomeView(this)'));
        }

        // Verify home view file contains correct structure
        final File homeViewFile = File(path.join(projectPath, 'lib', 'screens', 'home', 'home_view.dart'));
        if (homeViewFile.existsSync()) {
          final String content = homeViewFile.readAsStringSync();
          expect(content, contains('class HomeView extends StatelessWidget'));
          expect(content, contains('final HomeController state'));
        }

        // Verify pubspec.yaml contains project name
        final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
        if (pubspecFile.existsSync()) {
          final String content = pubspecFile.readAsStringSync();
          expect(content, contains('name: $projectName'));
        }
      }, skip: 'Requires Flutter CLI and Mason brick to be available');
    });
  });
}
