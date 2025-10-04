import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Assertion helpers for CLI-specific testing.
///
/// This class provides custom assertion methods that are commonly used when testing CLI applications, making test
/// code more readable and reducing duplication.
class CliAssertions {
  /// Asserts that a process result indicates success.
  ///
  /// This helper checks that the exit code is 0 and provides helpful error messages if the process failed, including
  /// stdout and stderr.
  ///
  /// Parameters:
  /// * [result] - ProcessResult from executing a CLI command
  /// * [message] - Optional custom message for assertion failure
  static void expectSuccess(ProcessResult result, [String? message]) {
    expect(
      result.exitCode,
      equals(0),
      reason:
          message ??
          'Process should succeed (exit code 0)\n'
              'stdout: ${result.stdout}\n'
              'stderr: ${result.stderr}',
    );
  }

  /// Asserts that a process result indicates a usage error.
  ///
  /// This helper checks that the exit code is 64 (EX_USAGE) which is the standard POSIX exit code for command usage
  /// errors.
  ///
  /// Parameters:
  /// * [result] - ProcessResult from executing a CLI command
  /// * [message] - Optional custom message for assertion failure
  static void expectUsageError(ProcessResult result, [String? message]) {
    expect(
      result.exitCode,
      equals(64),
      reason:
          message ??
          'Process should return usage error (exit code 64)\n'
              'stdout: ${result.stdout}\n'
              'stderr: ${result.stderr}',
    );
  }

  /// Asserts that a process result indicates a general error.
  ///
  /// This helper checks that the exit code is 1, which is used for general errors that are not usage-related.
  ///
  /// Parameters:
  /// * [result] - ProcessResult from executing a CLI command
  /// * [message] - Optional custom message for assertion failure
  static void expectGeneralError(ProcessResult result, [String? message]) {
    expect(
      result.exitCode,
      equals(1),
      reason:
          message ??
          'Process should return general error (exit code 1)\n'
              'stdout: ${result.stdout}\n'
              'stderr: ${result.stderr}',
    );
  }

  /// Asserts that a directory contains expected Flutter project structure.
  ///
  /// This helper verifies that a directory contains the basic files and folders expected in a Flutter project,
  /// making it easier to validate project creation in tests.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the project directory to validate
  static void expectFlutterProjectStructure(String projectPath) {
    expect(Directory(projectPath).existsSync(), isTrue, reason: 'Project directory should exist');

    expect(File(path.join(projectPath, 'pubspec.yaml')).existsSync(), isTrue, reason: 'pubspec.yaml should exist');

    expect(Directory(path.join(projectPath, 'lib')).existsSync(), isTrue, reason: 'lib directory should exist');

    expect(Directory(path.join(projectPath, 'test')).existsSync(), isTrue, reason: 'test directory should exist');
  }

  /// Asserts that a directory contains expected MVC architecture structure.
  ///
  /// This helper verifies that a project directory contains the specific files and folders expected in the MVC
  /// architecture pattern used by the Splendid CLI.
  ///
  /// Parameters:
  /// * [projectPath] - Path to the project directory to validate
  static void expectMvcArchitectureStructure(String projectPath) {
    // First verify basic Flutter structure
    expectFlutterProjectStructure(projectPath);

    // Verify MVC-specific files
    expect(File(path.join(projectPath, 'lib', 'main.dart')).existsSync(), isTrue, reason: 'main.dart should exist');

    expect(File(path.join(projectPath, 'lib', 'app.dart')).existsSync(), isTrue, reason: 'app.dart should exist');

    expect(
      Directory(path.join(projectPath, 'lib', 'screens')).existsSync(),
      isTrue,
      reason: 'screens directory should exist',
    );

    expect(
      Directory(path.join(projectPath, 'lib', 'screens', 'home')).existsSync(),
      isTrue,
      reason: 'home screen directory should exist',
    );

    // Verify MVC files for home screen
    final String homeScreenPath = path.join(projectPath, 'lib', 'screens', 'home');
    expect(
      File(path.join(homeScreenPath, 'home_route.dart')).existsSync(),
      isTrue,
      reason: 'home_route.dart should exist',
    );

    expect(
      File(path.join(homeScreenPath, 'home_controller.dart')).existsSync(),
      isTrue,
      reason: 'home_controller.dart should exist',
    );

    expect(
      File(path.join(homeScreenPath, 'home_view.dart')).existsSync(),
      isTrue,
      reason: 'home_view.dart should exist',
    );

    // Verify theme structure
    expect(
      Directory(path.join(projectPath, 'lib', 'theme')).existsSync(),
      isTrue,
      reason: 'theme directory should exist',
    );

    expect(
      File(path.join(projectPath, 'lib', 'theme', 'app_theme.dart')).existsSync(),
      isTrue,
      reason: 'app_theme.dart should exist',
    );

    expect(
      File(path.join(projectPath, 'lib', 'theme', 'insets.dart')).existsSync(),
      isTrue,
      reason: 'insets.dart should exist',
    );

    // Verify localization structure
    expect(
      Directory(path.join(projectPath, 'lib', 'l10n')).existsSync(),
      isTrue,
      reason: 'l10n directory should exist',
    );

    expect(
      File(path.join(projectPath, 'lib', 'l10n', 'app_en.arb')).existsSync(),
      isTrue,
      reason: 'app_en.arb should exist',
    );

    expect(File(path.join(projectPath, 'l10n.yaml')).existsSync(), isTrue, reason: 'l10n.yaml should exist');

    // Verify analysis options
    expect(
      File(path.join(projectPath, 'analysis_options.yaml')).existsSync(),
      isTrue,
      reason: 'analysis_options.yaml should exist',
    );
  }
}
