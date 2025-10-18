import 'dart:io';

import 'package:process/process.dart';

/// Service for executing Splendid CLI commands from the GUI.
///
/// This service provides a programmatic interface to the Splendid CLI tools, allowing the GUI to execute commands and
/// capture their output. It handles process management, error handling, and output formatting for display in the
/// dashboard interface.
///
/// All CLI operations are executed as separate processes to ensure the GUI remains responsive and to properly capture
/// command output and errors. The service manages working directories, command arguments, and result processing for
/// each supported CLI operation.
class CliService {
  /// Creates a new CLI service instance.
  const CliService({ProcessManager? processManager}) : _processManager = processManager ?? const LocalProcessManager();

  /// Process manager for executing CLI commands.
  ///
  /// Allows for dependency injection of process managers for testing and provides a consistent interface for process
  /// execution.
  final ProcessManager _processManager;

  /// Creates a new Flutter project using the CLI create command.
  ///
  /// Executes `splendid_cli create` with the specified parameters to generate a new Flutter project with MVC
  /// architecture and platform support.
  ///
  /// Parameters:
  /// * [projectName] - Name for the new Flutter project
  /// * [outputDirectory] - Directory where the project should be created
  /// * [platforms] - Comma-separated list of target platforms
  /// * [force] - Whether to overwrite existing directories
  ///
  /// Returns:
  /// * [CliResult] containing success status, output, and any error messages
  Future<CliResult> createProject({
    required String projectName,
    required String outputDirectory,
    required String platforms,
    required bool force,
  }) async {
    final List<String> arguments = [
      'create',
      projectName,
      '--output-directory',
      outputDirectory,
      '--platforms',
      platforms,
    ];

    if (force) {
      arguments.add('--force');
    }

    return _executeCliCommand(arguments);
  }

  /// Adds a new screen to an existing Flutter project.
  ///
  /// Executes `splendid_cli screen` to generate MVC architecture files for a new screen in the specified project
  /// directory.
  ///
  /// Parameters:
  /// * [screenName] - Name for the new screen
  /// * [projectPath] - Path to the Flutter project directory
  /// * [force] - Whether to overwrite existing screen files
  ///
  /// Returns:
  /// * [CliResult] containing success status, output, and any error messages
  Future<CliResult> addScreen({
    required String screenName,
    required String projectPath,
    required bool force,
  }) async {
    final List<String> arguments = ['screen', screenName];

    if (force) {
      arguments.add('--force');
    }

    return _executeCliCommand(arguments, workingDirectory: projectPath);
  }

  /// Generates a test file for the specified Dart file.
  ///
  /// Executes `splendid_cli generate-test` to create appropriate test templates for widgets or classes with
  /// comprehensive documentation.
  ///
  /// Parameters:
  /// * [targetFile] - Path to the Dart file to generate tests for
  /// * [projectPath] - Path to the Flutter project directory
  /// * [testType] - Type of test to generate ('auto', 'widget', 'class')
  /// * [force] - Whether to overwrite existing test files
  ///
  /// Returns:
  /// * [CliResult] containing success status, output, and any error messages
  Future<CliResult> generateTest({
    required String targetFile,
    required String projectPath,
    required String testType,
    required bool force,
  }) async {
    final List<String> arguments = [
      'generate-test',
      targetFile,
      '--type',
      testType,
    ];

    if (force) {
      arguments.add('--force');
    }

    return _executeCliCommand(arguments, workingDirectory: projectPath);
  }

  /// Runs project setup commands for the specified Flutter project.
  ///
  /// Executes `splendid_cli setup` to run pub get, code generation, and other project initialization tasks.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the Flutter project directory
  ///
  /// Returns:
  /// * [CliResult] containing success status, output, and any error messages
  Future<CliResult> setupProject({
    required String projectPath,
  }) async {
    return _executeCliCommand(['setup'], workingDirectory: projectPath);
  }

  /// Formats Dartdoc comments in the specified Flutter project.
  ///
  /// Executes `splendid_cli format-dartdoc` to reformat and rewrap Dartdoc comments to the specified line length
  /// across all Dart files in the project.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the Flutter project directory
  ///
  /// Returns:
  /// * [CliResult] containing success status, output, and any error messages
  Future<CliResult> formatProject({
    required String projectPath,
  }) async {
    return _executeCliCommand(['format-dartdoc', projectPath], workingDirectory: projectPath);
  }

  /// Executes a Splendid CLI command with the specified arguments.
  ///
  /// This method handles the low-level process execution, output capture, and error handling for all CLI operations. It
  /// provides a consistent interface for running CLI commands from the GUI.
  ///
  /// Parameters:
  /// * [arguments] - Command line arguments to pass to the CLI
  /// * [workingDirectory] - Optional working directory for command execution
  ///
  /// Returns:
  /// * [CliResult] containing the execution results and output
  Future<CliResult> _executeCliCommand(
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    try {
      // Determine the CLI executable path
      final String cliExecutable = await _findCliExecutable();

      // Execute the command
      final ProcessResult result = await _processManager.run(
        [cliExecutable, ...arguments],
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      // Combine stdout and stderr for complete output
      final String output = _combineOutput(result.stdout, result.stderr);

      return CliResult(
        success: result.exitCode == 0,
        output: output,
        error: result.exitCode != 0 ? _extractErrorMessage(output) : null,
        exitCode: result.exitCode,
      );
    } catch (error) {
      return CliResult(
        success: false,
        output: 'Failed to execute CLI command: $error',
        error: error.toString(),
        exitCode: -1,
      );
    }
  }

  /// Finds the Splendid CLI executable in the system.
  ///
  /// Attempts to locate the CLI executable using various strategies:
  /// 1. Check if 'splendid_cli' is available in PATH
  /// 2. Look for the executable relative to the GUI application
  /// 3. Fall back to 'dart run' with the CLI package
  ///
  /// Returns:
  /// * Path to the CLI executable or command to run it
  Future<String> _findCliExecutable() async {
    // Try to find splendid_cli in PATH
    try {
      final ProcessResult result = await _processManager.run(
        ['which', 'splendid_cli'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return 'splendid_cli';
      }
    } catch (error) {
      // Continue to next strategy
    }

    // Try to find the CLI relative to the GUI application
    try {
      final String scriptPath = Platform.script.toFilePath();
      final String cliPath =
          '${scriptPath.replaceAll('/example/gui_dashboard/', '/bin/').replaceAll(r'\example\gui_dashboard\', r'\bin\')}splendid_cli.dart';

      final File cliFile = File(cliPath);
      if (cliFile.existsSync()) {
        return 'dart run $cliPath';
      }
    } catch (error) {
      // Continue to fallback
    }

    // Fallback to assuming CLI is available in PATH
    return 'splendid_cli';
  }

  /// Combines stdout and stderr into a single formatted output string.
  ///
  /// This method merges the standard output and error streams from CLI command execution, providing a complete view of
  /// the command results for display in the GUI.
  ///
  /// Parameters:
  /// * [stdout] - Standard output from the command
  /// * [stderr] - Standard error from the command
  ///
  /// Returns:
  /// * Combined and formatted output string
  String _combineOutput(dynamic stdout, dynamic stderr) {
    final StringBuffer buffer = StringBuffer();

    if (stdout != null && stdout.toString().trim().isNotEmpty) {
      buffer.writeln(stdout.toString().trim());
    }

    if (stderr != null && stderr.toString().trim().isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('--- Errors ---');
      }
      buffer.writeln(stderr.toString().trim());
    }

    return buffer.toString();
  }

  /// Extracts a user-friendly error message from command output.
  ///
  /// Analyzes the command output to identify and extract the most relevant error message for display to users,
  /// filtering out technical details and stack traces when possible.
  ///
  /// Parameters:
  /// * [output] - The complete command output to analyze
  ///
  /// Returns:
  /// * Extracted error message suitable for user display
  String _extractErrorMessage(String output) {
    final List<String> lines = output.split('\n');

    // Look for common error patterns
    for (final String line in lines) {
      final String trimmedLine = line.trim();

      // Skip empty lines and stack trace lines
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      // Look for error indicators
      if (trimmedLine.toLowerCase().contains('error:') ||
          trimmedLine.toLowerCase().contains('failed:') ||
          trimmedLine.toLowerCase().contains('exception:')) {
        return trimmedLine;
      }
    }

    // If no specific error found, return the first non-empty line
    for (final String line in lines) {
      final String trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
        return trimmedLine;
      }
    }

    return 'Command failed with unknown error';
  }
}

/// Result of a CLI command execution.
///
/// This class encapsulates the results of executing a Splendid CLI command, including success status, output content,
/// error messages, and exit codes. It provides a structured way to handle command results in the GUI.
class CliResult {
  /// Creates a new CLI result.
  ///
  /// Parameters:
  /// * [success] - Whether the command executed successfully
  /// * [output] - Combined stdout and stderr from the command
  /// * [error] - Extracted error message if the command failed
  /// * [exitCode] - Process exit code from the command execution
  const CliResult({
    required this.success,
    required this.output,
    required this.exitCode,
    this.error,
  });

  /// Whether the CLI command executed successfully.
  ///
  /// Based on the process exit code, with 0 indicating success and any other value indicating failure.
  final bool success;

  /// Combined output from the CLI command.
  ///
  /// Includes both standard output and error streams, formatted for display in the GUI's output panel.
  final String output;

  /// Error message extracted from the command output.
  ///
  /// Null if the command succeeded. Contains a user-friendly error message when the command fails.
  final String? error;

  /// Process exit code from the CLI command execution.
  ///
  /// Follows standard POSIX conventions with 0 indicating success and non-zero values indicating various types of
  /// failures.
  final int exitCode;
}
