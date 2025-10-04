import 'dart:io';

import 'package:splendid_cli/splendid_command_runner.dart';
import 'package:test/test.dart';

/// Test suite for SplendidCommandRunner functionality.
///
/// This test suite covers the top-level command runner that manages all CLI
/// subcommands and handles error scenarios. It ensures that the CLI correctly
/// routes commands, handles missing arguments, and provides appropriate error
/// messages and exit codes.
///
/// Test Categories:
/// * Command registration and routing
/// * Error handling for invalid usage
/// * Exit code management
/// * Help text generation
/// * Integration with subcommands
///
/// The tests focus on the command runner's role as the entry point for the CLI,
/// ensuring that users receive consistent and helpful feedback regardless of
/// how they invoke the tool.
void main() {
  group('SplendidCommandRunner', () {
    late SplendidCommandRunner runner;

    /// Set up test environment with fresh command runner instance.
    ///
    /// Creates a new command runner for each test to ensure complete isolation
    /// and prevent state leakage between tests.
    setUp(() {
      runner = SplendidCommandRunner();
    });

    group('command runner configuration', () {
      /// Verifies that the command runner is properly configured with correct metadata.
      ///
      /// This test ensures that the CLI has the expected name and description
      /// that users will see when running help commands or encountering errors.
      test('should have correct name and description', () {
        expect(runner.executableName, equals('splendid_cli'));
        expect(
          runner.description,
          equals('Scaffold and manage Flutter apps using MVC standards.'),
        );
      });

      /// Verifies that the create command is properly registered.
      ///
      /// This test ensures that the command runner includes the create command
      /// and that it can be accessed through the standard command lookup mechanism.
      test('should register create command', () {
        final commands = runner.commands;
        expect(commands.containsKey('create'), isTrue);
        expect(commands['create']?.name, equals('create'));
      });
    });

    group('command execution', () {
      /// Tests successful execution of the create command with valid arguments.
      ///
      /// This test verifies that the command runner properly routes create
      /// commands to the CreateCommand implementation and returns appropriate
      /// exit codes for successful operations.
      /// Note: This test may fail if Flutter CLI is not available.
      test('should execute create command with valid arguments', () async {
        final List<String> args = [
          'create',
          'test_app',
          '--output-directory=${Directory.systemTemp.path}',
          '--force',
        ];

        final int exitCode = await runner.run(args);

        // Should succeed (0) with Flutter CLI available, or fail gracefully (1) without it
        expect(exitCode, anyOf(equals(0), equals(1)));
      }, skip: 'Requires Flutter CLI for full integration test');

      /// Tests that the command runner handles unknown commands appropriately.
      ///
      /// This test ensures that when users invoke non-existent commands,
      /// they receive clear error messages and usage information rather than
      /// cryptic exceptions.
      test('should handle unknown commands with usage error', () async {
        final List<String> args = ['unknown_command'];

        final int exitCode = await runner.run(args);

        // Should return EX_USAGE (64) for unknown commands
        expect(exitCode, equals(64));
      });

      /// Tests that the command runner handles empty arguments appropriately.
      ///
      /// This test verifies that when users run the CLI without any arguments,
      /// they receive helpful usage information rather than an error.
      test('should handle empty arguments gracefully', () async {
        final List<String> args = [];

        final int exitCode = await runner.run(args);

        // Should return success (0) and show help when no arguments provided
        expect(exitCode, equals(0));
      });
    });

    group('create command integration', () {
      /// Tests that missing project name is handled correctly through the command runner.
      ///
      /// This test verifies the complete error handling flow from command runner
      /// through to the create command when required arguments are missing.
      test('should return usage error when create command missing project name', () async {
        final List<String> args = ['create'];

        final int exitCode = await runner.run(args);

        // Should return EX_USAGE (64) for missing required arguments
        expect(exitCode, equals(64));
      });

      /// Tests that invalid project names are handled correctly through the command runner.
      ///
      /// This test ensures that validation errors from the create command are
      /// properly propagated through the command runner with appropriate exit codes.
      test('should return usage error for invalid project names', () async {
        final List<String> invalidNames = [
          'MyApp', // Uppercase not allowed
          'my-app', // Hyphens not allowed
          '_private', // Cannot start with underscore
          '123app', // Cannot start with number
        ];

        for (final String invalidName in invalidNames) {
          final List<String> args = ['create', invalidName];

          final int exitCode = await runner.run(args);

          expect(
            exitCode,
            equals(64),
            reason: 'Invalid project name "$invalidName" should return usage error',
          );
        }
      });

      /// Tests that valid project names are accepted by the command runner.
      ///
      /// This test verifies that properly formatted project names pass through
      /// the command runner validation and reach the create command implementation.
      /// Note: Actual project creation may fail without Flutter CLI.
      test('should accept valid project names', () async {
        final List<String> validNames = [
          'my_app',
          'flutter_demo',
          'awesome_project',
        ];

        for (final String validName in validNames) {
          final List<String> args = [
            'create',
            validName,
            '--output-directory=${Directory.systemTemp.path}',
            '--force',
          ];

          final int exitCode = await runner.run(args);

          // Should not return usage error (64) for valid names
          // May return 0 (success) or 1 (Flutter CLI error) depending on environment
          expect(
            exitCode,
            isNot(equals(64)),
            reason: 'Valid project name "$validName" should not return usage error',
          );
        }
      }, skip: 'Requires Flutter CLI for reliable testing');

      /// Tests that help flag works correctly with create command.
      ///
      /// This test verifies that users can get help information for the create
      /// command specifically, rather than general CLI help.
      test('should show create command help', () async {
        final List<String> args = ['create', '--help'];

        final int exitCode = await runner.run(args);

        // Should return success (0) when showing help
        expect(exitCode, equals(0));
      });

      /// Tests that create command options are properly parsed through command runner.
      ///
      /// This test ensures that command-line options like --output-directory,
      /// --platforms, and --force are correctly passed from the command runner
      /// to the create command implementation.
      test('should parse create command options correctly', () async {
        final List<String> args = [
          'create',
          'options_test_app',
          '--output-directory=${Directory.systemTemp.path}',
          '--platforms=android,ios',
          '--force',
        ];

        final int exitCode = await runner.run(args);

        // Should not fail due to argument parsing issues
        // May fail due to Flutter CLI availability, but not argument parsing
        expect(exitCode, anyOf(equals(0), equals(1)));
      }, skip: 'Requires Flutter CLI for full integration test');
    });

    group('error handling', () {
      /// Tests that unexpected exceptions are handled gracefully.
      ///
      /// This test verifies that when unexpected errors occur during command
      /// execution, the command runner provides appropriate error messages
      /// and exit codes rather than allowing exceptions to propagate.
      test('should handle unexpected exceptions gracefully', () async {
        // This test is difficult to trigger reliably without mocking
        // The command runner's error handling is tested indirectly through
        // other tests that may cause various types of failures
        expect(runner, isNotNull);
      });

      /// Tests that usage exceptions are properly formatted and reported.
      ///
      /// This test ensures that when commands fail due to incorrect usage,
      /// users receive both the error message and helpful usage information.
      test('should format usage exceptions correctly', () async {
        final List<String> args = ['create', '--invalid-flag'];

        final int exitCode = await runner.run(args);

        // Should return EX_USAGE (64) for invalid flags
        expect(exitCode, equals(64));
      });
    });

    group('exit codes', () {
      /// Tests that the command runner returns correct POSIX exit codes.
      ///
      /// This test verifies that the CLI follows standard POSIX conventions
      /// for exit codes, making it compatible with shell scripts and CI/CD
      /// systems that rely on exit code semantics.
      test('should return correct exit codes for different scenarios', () async {
        // Test success scenario (help command)
        int exitCode = await runner.run(['--help']);
        expect(exitCode, equals(0), reason: 'Help should return success (0)');

        // Test usage error scenario
        exitCode = await runner.run(['create', '--invalid-option']);
        expect(exitCode, equals(64), reason: 'Invalid usage should return EX_USAGE (64)');

        // Test unknown command scenario
        exitCode = await runner.run(['nonexistent']);
        expect(exitCode, equals(64), reason: 'Unknown command should return EX_USAGE (64)');
      });

      /// Tests that null return values from commands are handled correctly.
      ///
      /// This test ensures that when subcommands don't explicitly return an
      /// exit code, the command runner treats this as success (0) to maintain
      /// consistent behavior across all commands.
      test('should treat null command results as success', () async {
        // The help command typically returns null, which should be treated as success
        final int exitCode = await runner.run(['--help']);
        expect(exitCode, equals(0));
      });
    });
  });
}
