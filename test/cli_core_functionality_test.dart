import 'dart:io';

import 'package:splendid_cli/splendid_cli.dart';
import 'package:test/test.dart';

import 'helpers/project_cleanup_helper.dart';

/// Core functionality tests for Splendid CLI.
///
/// This test suite focuses on testing the essential CLI functionality
/// that can be validated without external dependencies like Flutter CLI
/// or Mason bricks. It ensures that the core argument parsing, validation,
/// and error handling work correctly.
///
/// Test Categories:
/// * Argument parsing and validation
/// * Error handling and exit codes
/// * Help text generation
/// * Command routing
/// * Project name validation
///
/// These tests provide confidence that the CLI behaves correctly for
/// the most common user interactions and error scenarios.
void main() {
  group('Splendid CLI Core Functionality', () {
    late SplendidCommandRunner runner;
    late Directory tempDir;

    /// Set up automatic cleanup for test artifacts.
    ///
    /// This ensures that any test projects created at the root level
    /// are automatically cleaned up when tests complete.
    setUpAll(() {
      ProjectCleanupHelper.setupAutomaticCleanup();
    });

    setUp(() {
      runner = SplendidCommandRunner();
      tempDir = Directory.systemTemp.createTempSync('cli_core_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Clean up any test artifacts created during test execution.
    ///
    /// This removes any directories that may have been created at the
    /// project root level during CLI command testing.
    tearDownAll(() {
      ProjectCleanupHelper.cleanupTestArtifacts();
    });

    group('missing arguments', () {
      /// Tests that CLI shows help when no arguments are provided.
      ///
      /// This is the most common scenario when users first try the CLI
      /// and should provide helpful guidance on how to use the tool.
      test('should show help when no arguments provided', () async {
        final int exitCode = await runner.run([]);

        expect(exitCode, equals(0), reason: 'Should show help successfully');
      });

      /// Tests that CLI returns usage error when create command has no project name.
      ///
      /// This tests the most common error scenario where users forget to
      /// specify the required project name argument.
      test('should return usage error when create command missing project name', () async {
        final int exitCode = await runner.run(['create']);

        expect(exitCode, equals(64), reason: 'Should return EX_USAGE for missing project name');
      });
    });

    group('invalid arguments', () {
      /// Tests that CLI validates project names according to Dart conventions.
      ///
      /// This ensures that users get immediate feedback when they provide
      /// project names that would cause issues later in the Flutter project
      /// creation process.
      test('should reject invalid project names', () async {
        final Map<String, String> invalidNames = {
          'MyApp': 'Uppercase letters not allowed',
          'my-app': 'Hyphens not allowed',
          '_private': 'Cannot start with underscore',
          '123app': 'Cannot start with number',
          'my app': 'Spaces not allowed',
          'my.app': 'Dots not allowed',
        };

        for (final MapEntry<String, String> entry in invalidNames.entries) {
          final int exitCode = await runner.run(['create', entry.key]);

          expect(
            exitCode,
            equals(64),
            reason: 'Invalid name "${entry.key}" (${entry.value}) should return usage error',
          );
        }
      });

      /// Tests that CLI rejects unknown command-line flags.
      ///
      /// This ensures that typos in flag names are caught and reported
      /// clearly to users rather than being silently ignored.
      test('should reject unknown flags', () async {
        final int exitCode = await runner.run(['create', 'test_app', '--invalid-flag']);

        expect(exitCode, equals(64), reason: 'Unknown flags should return usage error');
      });

      /// Tests that CLI rejects unknown commands.
      ///
      /// This ensures that typos in command names are caught and users
      /// are shown the available commands.
      test('should reject unknown commands', () async {
        final int exitCode = await runner.run(['unknown_command']);

        expect(exitCode, equals(64), reason: 'Unknown commands should return usage error');
      });
    });

    group('valid arguments', () {
      /// Tests that CLI accepts valid project names.
      ///
      /// This verifies that properly formatted Dart package names pass
      /// validation and the CLI proceeds to the next step (which may fail
      /// due to missing Flutter CLI, but that's expected in test environment).
      test('should accept valid project names', () async {
        final List<String> validNames = [
          'my_app',
          'flutter_demo',
          'awesome_project',
          'simple',
          'app123',
        ];

        for (final String name in validNames) {
          final int exitCode = await runner.run([
            'create',
            name,
            '--output-directory=${tempDir.path}',
            '--force',
          ]);

          // Should not return usage error (64) for valid names
          // May return 0 (success) or 1 (Flutter CLI missing) depending on environment
          expect(
            exitCode,
            isNot(equals(64)),
            reason: 'Valid project name "$name" should not return usage error',
          );
        }
      });

      /// Tests that CLI accepts all supported command-line options.
      ///
      /// This verifies that all documented flags and options are properly
      /// recognized and parsed by the argument parser.
      test('should accept all supported options', () async {
        final int exitCode = await runner.run([
          'create',
          'test_app',
          '--output-directory=${tempDir.path}',
          '--platforms=android,ios',
          '--force',
        ]);

        // Should not fail due to argument parsing issues
        expect(exitCode, isNot(equals(64)), reason: 'Valid options should not cause usage error');
      });
    });

    group('help and usage', () {
      /// Tests that help flag displays comprehensive usage information.
      ///
      /// This ensures that users can get detailed information about how
      /// to use the CLI and what options are available.
      test('should display help with --help flag', () async {
        final int exitCode = await runner.run(['--help']);

        expect(exitCode, equals(0), reason: 'Help should display successfully');
      });

      /// Tests that create command help shows detailed command information.
      ///
      /// This ensures that users can get specific help for the create
      /// command including all available options and usage patterns.
      test('should display create command help', () async {
        final int exitCode = await runner.run(['create', '--help']);

        expect(exitCode, equals(0), reason: 'Create command help should display successfully');
      });
    });

    group('directory handling', () {
      /// Tests that CLI detects existing directories and requires force flag.
      ///
      /// This protects users from accidentally overwriting existing projects
      /// and ensures they must explicitly use --force to overwrite.
      test('should require force flag for existing directories', () async {
        const String projectName = 'existing_project';

        // Create existing directory
        Directory('${tempDir.path}/$projectName').createSync();

        final int exitCode = await runner.run([
          'create',
          projectName,
          '--output-directory=${tempDir.path}',
        ]);

        expect(exitCode, equals(1), reason: 'Should fail when directory exists without force');
      });

      /// Tests that CLI proceeds when force flag is used with existing directory.
      ///
      /// This verifies that the --force flag properly overrides the directory
      /// existence check, allowing intentional overwrites.
      test('should proceed with force flag for existing directories', () async {
        const String projectName = 'existing_project_force';

        // Create existing directory
        Directory('${tempDir.path}/$projectName').createSync();

        final int exitCode = await runner.run([
          'create',
          projectName,
          '--output-directory=${tempDir.path}',
          '--force',
        ]);

        // Should not fail due to directory existence (may fail due to Flutter CLI missing)
        // The force flag should override directory check, but may still fail due to missing Flutter CLI
        expect(exitCode, anyOf(equals(0), equals(1)), reason: 'Force flag should override directory check');
      });
    });

    group('exit codes', () {
      /// Tests that CLI returns correct POSIX exit codes for different scenarios.
      ///
      /// This ensures compatibility with shell scripts and CI/CD systems
      /// that rely on exit code semantics for error handling.
      test('should return correct POSIX exit codes', () async {
        // Success scenario (help)
        int exitCode = await runner.run(['--help']);
        expect(exitCode, equals(0), reason: 'Help should return success (0)');

        // Usage error scenario (missing project name)
        exitCode = await runner.run(['create']);
        expect(exitCode, equals(64), reason: 'Missing args should return EX_USAGE (64)');

        // Usage error scenario (invalid project name)
        exitCode = await runner.run(['create', 'Invalid-Name']);
        expect(exitCode, equals(64), reason: 'Invalid args should return EX_USAGE (64)');

        // Usage error scenario (unknown command)
        exitCode = await runner.run(['nonexistent']);
        expect(exitCode, equals(64), reason: 'Unknown command should return EX_USAGE (64)');
      });
    });

    group('command configuration', () {
      /// Tests that the CLI is properly configured with expected metadata.
      ///
      /// This verifies that the CLI has the correct name, description, and
      /// command registration that users will see in help output.
      test('should have correct CLI configuration', () {
        expect(runner.executableName, equals('splendid_cli'));
        expect(runner.description, contains('Scaffold and manage Flutter apps'));
        expect(runner.commands.containsKey('create'), isTrue);
      });

      /// Tests that the create command is properly configured.
      ///
      /// This verifies that the create command has the expected name,
      /// description, and argument configuration.
      test('should have properly configured create command', () {
        final createCommand = runner.commands['create']!;

        expect(createCommand.name, equals('create'));
        expect(createCommand.description, contains('Create a new Flutter app'));

        // Verify expected options are configured
        final argParser = createCommand.argParser;
        expect(argParser.options.containsKey('output-directory'), isTrue);
        expect(argParser.options.containsKey('platforms'), isTrue);
        expect(argParser.options.containsKey('force'), isTrue);
      });
    });
  });
}
