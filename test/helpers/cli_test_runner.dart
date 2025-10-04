import 'dart:io';
import 'package:path/path.dart' as path;

/// Utilities for executing CLI commands in tests.
///
/// This class provides helper methods for running the CLI in test environments, handling common scenarios like
/// timeout management and output capture.
class CliTestRunner {
  /// Path to the CLI executable for testing.
  ///
  /// This is determined based on the current test environment and points to the main CLI entry point.
  static String get cliExecutable {
    final String scriptPath = Platform.script.path;
    final String projectRoot = path.dirname(path.dirname(scriptPath));

    return path.join(projectRoot, 'bin', 'splendid_cli.dart');
  }

  /// Executes a CLI command with the specified arguments.
  ///
  /// This method provides a convenient way to run CLI commands in tests with proper timeout handling and error
  /// capture.
  ///
  /// Parameters:
  /// * [args] - Command-line arguments to pass to the CLI
  /// * [workingDirectory] - Optional working directory for command execution
  /// * [timeout] - Optional timeout for command execution
  ///
  /// Returns:
  /// * [Future<ProcessResult>] containing exit code, stdout, and stderr
  static Future<ProcessResult> run(
    List<String> args, {
    String? workingDirectory,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    return Process.run(
      'dart',
      [cliExecutable, ...args],
      workingDirectory: workingDirectory,
    ).timeout(timeout);
  }

  /// Executes the create command with specified project name and options.
  ///
  /// This is a convenience method for the most common CLI operation in tests, reducing boilerplate code in test
  /// files.
  ///
  /// Parameters:
  /// * [projectName] - Name of the project to create
  /// * [outputDirectory] - Directory where project should be created
  /// * [platforms] - Optional platform selection
  /// * [force] - Whether to use force flag
  ///
  /// Returns:
  /// * [Future<ProcessResult>] from the create command execution
  static Future<ProcessResult> createProject(
    String projectName,
    String outputDirectory, {
    String? platforms,
    bool force = false,
  }) async {
    final List<String> args = [
      'create',
      projectName,
      '--output-directory=$outputDirectory',
    ];

    if (platforms != null) {
      args.add('--platforms=$platforms');
    }

    if (force) {
      args.add('--force');
    }

    return run(args);
  }
}
