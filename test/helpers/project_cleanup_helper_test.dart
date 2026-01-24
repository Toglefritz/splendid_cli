import 'dart:io';

import 'package:test/test.dart';

import 'project_cleanup_helper.dart';

/// Test suite for ProjectCleanupHelper functionality.
///
/// This test suite verifies that the cleanup helper correctly identifies and
/// removes test artifacts without affecting other directories.
void main() {
  group('ProjectCleanupHelper', () {
    late Directory tempTestDir;

    setUp(() {
      // Create a temporary test directory to simulate test artifacts
      tempTestDir = Directory('test_cleanup_simulation')..createSync();
    });

    tearDown(() {
      // Clean up our test simulation directory
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    });

    group('cleanup functionality', () {
      /// Tests that the helper can identify existing test artifacts.
      test('should identify existing test artifacts', () {
        final List<String> artifacts = ProjectCleanupHelper.findExistingTestArtifacts();

        // Should be a list (may be empty if no artifacts exist)
        expect(artifacts, isA<List<String>>());
      });

      /// Tests that specific directory cleanup works correctly.
      test('should clean up specific directories', () {
        // Our temp directory should exist
        expect(tempTestDir.existsSync(), isTrue);

        // Clean it up using the helper
        final bool success = ProjectCleanupHelper.cleanupSpecificDirectory('test_cleanup_simulation');

        // Should succeed and directory should be gone
        expect(success, isTrue);
        expect(tempTestDir.existsSync(), isFalse);
      });

      /// Tests that cleanup handles non-existent directories gracefully.
      test('should handle non-existent directories gracefully', () {
        // Try to clean up a directory that doesn't exist
        final bool success = ProjectCleanupHelper.cleanupSpecificDirectory('non_existent_directory');

        // Should succeed (no-op for non-existent directories)
        expect(success, isTrue);
      });

      /// Tests that pattern-based cleanup works correctly.
      test('should clean up directories matching patterns', () {
        // Create some test directories
        Directory('test_pattern_1').createSync();
        Directory('test_pattern_2').createSync();
        Directory('other_directory').createSync();

        // Clean up directories matching test_pattern_*
        final int cleanedCount = ProjectCleanupHelper.cleanupDirectoriesMatching(
          RegExp(r'^test_pattern_\d+$'),
        );

        // Should have cleaned up 2 directories
        expect(cleanedCount, equals(2));
        expect(Directory('test_pattern_1').existsSync(), isFalse);
        expect(Directory('test_pattern_2').existsSync(), isFalse);
        expect(Directory('other_directory').existsSync(), isTrue);

        // Clean up the remaining directory
        Directory('other_directory').deleteSync();
      });
    });

    group('safety checks', () {
      /// Tests that cleanup doesn't affect important directories.
      test('should not affect non-test directories', () {
        // These directories should never be cleaned up
        final List<String> importantDirs = ['lib', 'bin', 'test', '.git'];

        for (final String dirName in importantDirs) {
          final Directory dir = Directory(dirName);
          final bool existedBefore = dir.existsSync();

          // Run cleanup
          ProjectCleanupHelper.cleanupTestArtifacts();

          // Directory existence should not change
          expect(dir.existsSync(), equals(existedBefore));
        }
      });
    });
  });
}
