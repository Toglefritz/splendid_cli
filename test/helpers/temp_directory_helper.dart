import 'dart:io';
import 'package:path/path.dart' as path;

/// Helper class for managing temporary directories in tests.
///
/// This class provides a convenient way to create and clean up temporary
/// directories for tests that need to interact with the file system. It ensures
/// proper cleanup even if tests fail or throw exceptions.
class TempDirectoryHelper {
  /// The temporary directory created for testing.
  ///
  /// This directory is automatically created when the helper is instantiated
  /// and should be cleaned up by calling [cleanup] when testing is complete.
  late final Directory directory;

  /// Creates a new temporary directory helper.
  ///
  /// The directory is created immediately and can be accessed through the
  /// [directory] property. A unique prefix is used to avoid conflicts between
  /// concurrent test runs.
  ///
  /// Parameters:
  /// * [prefix] - Optional prefix for the temporary directory name
  TempDirectoryHelper([String prefix = 'splendid_cli_test_']) {
    directory = Directory.systemTemp.createTempSync(prefix);
  }

  /// Returns the absolute path to the temporary directory.
  ///
  /// This is a convenience method for accessing the directory path without
  /// needing to call `directory.path` directly.
  String get directoryPath => directory.path;

  /// Creates a subdirectory within the temporary directory.
  ///
  /// This method is useful for creating nested directory structures needed for
  /// testing complex project layouts.
  ///
  /// Parameters:
  /// * [name] - Name of the subdirectory to create
  ///
  /// Returns:
  /// * [Directory] object representing the created subdirectory
  Directory createSubdirectory(String name) {
    final Directory subdir = Directory(path.join(directoryPath, name))..createSync(recursive: true);

    return subdir;
  }

  /// Creates a file within the temporary directory with specified content.
  ///
  /// This method is useful for setting up test fixtures and mock files that
  /// tests can interact with.
  ///
  /// Parameters:
  /// * [relativePath] - Path relative to the temporary directory
  /// * [content] - Content to write to the file
  ///
  /// Returns:
  /// * [File] object representing the created file
  File createFile(String relativePath, String content) {
    final File file = File(path.join(directoryPath, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);

    return file;
  }

  /// Cleans up the temporary directory and all its contents.
  ///
  /// This method should be called in test tearDown methods to ensure proper
  /// cleanup of test resources. It safely handles cases where the directory has
  /// already been deleted or doesn't exist.
  void cleanup() {
    if (directory.existsSync()) {
      try {
        directory.deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors to prevent test failures This can happen on
        // Windows if files are still locked
      }
    }
  }
}
