import 'dart:io';

/// Helper class for cleaning up test artifacts created during test runs.
///
/// This class provides utilities for cleaning up directories and files that may
/// be created during test execution, particularly when tests run CLI commands
/// that create projects or other artifacts at the root level.
class ProjectCleanupHelper {
  /// List of directory names that should be cleaned up after tests.
  ///
  /// These are common directory names that tests might create when running CLI
  /// commands or testing project creation functionality.
  static const List<String> _testDirectories = [
    'test_project',
    'integration_test_app',
    'mobile_only_app',
    'force_overwrite_app',
    'existing_directory_app',
    'mvc_structure_test',
    'test_app',
    'my_app',
    'flutter_demo',
    'awesome_project',
    'simple',
    'app123',
    'existing_project',
    'existing_project_force',
    'options_test_app',
    'game',
    'user_profile',
    'test_screen',
  ];

  /// Cleans up test artifacts from the current working directory.
  ///
  /// This method removes any directories that may have been created during test
  /// execution. It's designed to be safe to call even if the directories don't
  /// exist, and it handles errors gracefully to prevent test failures due to
  /// cleanup issues.
  ///
  /// This method should be called in `tearDownAll` or similar cleanup hooks to
  /// ensure test artifacts don't accumulate on the file system.
  static void cleanupTestArtifacts() {
    final String currentDir = Directory.current.path;

    for (final String dirName in _testDirectories) {
      final Directory testDir = Directory('$currentDir/$dirName');

      if (testDir.existsSync()) {
        try {
          testDir.deleteSync(recursive: true);
          print('Cleaned up test directory: $dirName');
        } catch (e) {
          // Log the error but don't fail the test
          print('Warning: Could not clean up test directory $dirName: $e');
        }
      }
    }
  }

  /// Cleans up a specific test directory by name.
  ///
  /// This method removes a specific directory from the current working
  /// directory. It's useful for cleaning up directories with dynamic names or
  /// for targeted cleanup in specific tests.
  ///
  /// Parameters:
  /// * [directoryName] - Name of the directory to clean up
  ///
  /// Returns:
  /// * `true` if the directory was successfully removed or didn't exist
  /// * `false` if there was an error during removal
  static bool cleanupSpecificDirectory(String directoryName) {
    final String currentDir = Directory.current.path;
    final Directory testDir = Directory('$currentDir/$directoryName');

    if (!testDir.existsSync()) {
      return true; // Already clean
    }

    try {
      testDir.deleteSync(recursive: true);
      print('Cleaned up test directory: $directoryName');
      return true;
    } catch (e) {
      print('Warning: Could not clean up test directory $directoryName: $e');
      return false;
    }
  }

  /// Cleans up all directories matching a pattern.
  ///
  /// This method removes all directories in the current working directory that
  /// match the specified pattern. It's useful for cleaning up directories with
  /// generated names or prefixes.
  ///
  /// Parameters:
  /// * [pattern] - RegExp pattern to match directory names
  ///
  /// Returns:
  /// * Number of directories that were successfully cleaned up
  static int cleanupDirectoriesMatching(RegExp pattern) {
    final String currentDir = Directory.current.path;
    final Directory workingDir = Directory(currentDir);
    int cleanedCount = 0;

    try {
      final List<FileSystemEntity> entities = workingDir.listSync();

      for (final FileSystemEntity entity in entities) {
        if (entity is Directory) {
          final String dirName = entity.path.split('/').last;

          if (pattern.hasMatch(dirName)) {
            try {
              entity.deleteSync(recursive: true);
              print('Cleaned up test directory: $dirName');
              cleanedCount++;
            } catch (e) {
              print('Warning: Could not clean up test directory $dirName: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Warning: Error scanning for test directories: $e');
    }

    return cleanedCount;
  }

  /// Sets up automatic cleanup for test suites.
  ///
  /// This method should be called in `setUpAll` to register cleanup handlers
  /// that will run when the test process exits. This ensures cleanup happens
  /// even if tests are interrupted or fail unexpectedly.
  static void setupAutomaticCleanup() {
    // Register cleanup to run when the process exits
    ProcessSignal.sigint.watch().listen((_) {
      cleanupTestArtifacts();
      exit(0);
    });

    ProcessSignal.sigterm.watch().listen((_) {
      cleanupTestArtifacts();
      exit(0);
    });
  }

  /// Checks if any test artifacts exist in the current directory.
  ///
  /// This method can be used to verify that cleanup is working correctly or to
  /// warn about leftover test artifacts.
  ///
  /// Returns:
  /// * List of test directory names that currently exist
  static List<String> findExistingTestArtifacts() {
    final String currentDir = Directory.current.path;
    final List<String> existingDirs = [];

    for (final String dirName in _testDirectories) {
      final Directory testDir = Directory('$currentDir/$dirName');

      if (testDir.existsSync()) {
        existingDirs.add(dirName);
      }
    }

    return existingDirs;
  }
}
