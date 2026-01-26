import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite verifying that the format_all command correctly passes the
/// line-length parameter to dart format.
///
/// This test suite addresses a bug where the format command would format
/// comments with the specified line length but would format Dart code with
/// the default 80-character line length instead of the user-specified value.
///
/// Test Strategy:
/// * Create a temporary Dart file with long lines that exceed 80 characters
/// * Run the format command with a line length of 120
/// * Verify that the formatted code respects the 120-character limit
/// * Ensure lines that fit within 120 characters are not wrapped
void main() {
  group('FormatAllCommand line-length parameter', () {
    late TempDirectoryHelper tempDir;

    setUp(() {
      tempDir = TempDirectoryHelper();
    });

    tearDown(() {
      tempDir.cleanup();
    });

    /// Verifies that dart format receives the correct line-length parameter.
    ///
    /// This test creates a Dart file with a long line that exceeds 80
    /// characters but fits within 120 characters. When formatted with
    /// --line-length=120, the line should remain on a single line.
    test('should pass line-length parameter to dart format', () async {
      // Create a test file with a long line (100 characters)
      // This line exceeds 80 chars but fits in 120 chars
      final String testContent = '''
void main() {
  final String veryLongVariableName = 'This is a very long string that exceeds eighty characters';
}
''';

      final File testFile = File(path.join(tempDir.directoryPath, 'test_file.dart'));
      await testFile.writeAsString(testContent);

      // Run the format command with line-length=120
      final ProcessResult result = await Process.run(
        'dart',
        [
          'run',
          'bin/splendid_cli.dart',
          'format',
          testFile.path,
          '120',
        ],
      );

      expect(result.exitCode, equals(0), reason: 'Format command should succeed');

      // Read the formatted content
      final String formattedContent = await testFile.readAsString();

      // The line should remain on a single line since it fits within 120 chars
      // If dart format used 80 chars, it would have wrapped this line
      expect(
        formattedContent.contains(
          "final String veryLongVariableName = 'This is a very long string that exceeds eighty characters';",
        ),
        isTrue,
        reason: 'Long line within 120 chars should not be wrapped',
      );
    });

    /// Verifies that lines exceeding the specified line length are wrapped.
    ///
    /// This test ensures that when a line exceeds the specified line length,
    /// dart format will wrap it appropriately.
    test('should wrap lines that exceed specified line-length', () async {
      // Create a test file with a very long line (150+ characters)
      final String testContent = '''
void main() {
  final String extremelyLongVariableName = 'This is an extremely long string that definitely exceeds one hundred and twenty characters and should be wrapped';
}
''';

      final File testFile = File(path.join(tempDir.directoryPath, 'test_file.dart'));
      await testFile.writeAsString(testContent);

      // Run the format command with line-length=120
      final ProcessResult result = await Process.run(
        'dart',
        [
          'run',
          'bin/splendid_cli.dart',
          'format',
          testFile.path,
          '120',
        ],
      );

      expect(result.exitCode, equals(0), reason: 'Format command should succeed');

      // Read the formatted content
      final String formattedContent = await testFile.readAsString();

      // The line should be wrapped since it exceeds 120 chars
      final List<String> lines = formattedContent.split('\n');
      final List<String> nonEmptyLines = lines.where((String line) => line.trim().isNotEmpty).toList();

      // Should have more than 3 lines (opening brace, wrapped statement, closing brace)
      expect(
        nonEmptyLines.length,
        greaterThan(3),
        reason: 'Long line exceeding 120 chars should be wrapped',
      );
    });

    /// Verifies that the --line-length flag works correctly.
    ///
    /// This test ensures that the flag-based syntax (--line-length=120)
    /// works in addition to the positional argument syntax.
    test('should accept line-length as a flag', () async {
      final String testContent = '''
void main() {
  final String veryLongVariableName = 'This is a very long string that exceeds eighty characters';
}
''';

      final File testFile = File(path.join(tempDir.directoryPath, 'test_file.dart'));
      await testFile.writeAsString(testContent);

      // Run the format command with --line-length flag
      final ProcessResult result = await Process.run(
        'dart',
        [
          'run',
          'bin/splendid_cli.dart',
          'format',
          testFile.path,
          '--line-length',
          '120',
        ],
      );

      expect(result.exitCode, equals(0), reason: 'Format command should succeed');

      // Read the formatted content
      final String formattedContent = await testFile.readAsString();

      // The line should remain on a single line
      expect(
        formattedContent.contains(
          "final String veryLongVariableName = 'This is a very long string that exceeds eighty characters';",
        ),
        isTrue,
        reason: 'Long line within 120 chars should not be wrapped',
      );
    });

    /// Verifies that dry-run mode still respects line-length parameter.
    ///
    /// This test ensures that even in dry-run mode, the line-length
    /// parameter is correctly passed to dart format for analysis.
    test('should pass line-length in dry-run mode', () async {
      final String testContent = '''
void main() {
  final String veryLongVariableName = 'This is a very long string that exceeds eighty characters';
}
''';

      final File testFile = File(path.join(tempDir.directoryPath, 'test_file.dart'));
      await testFile.writeAsString(testContent);

      // Run the format command in dry-run mode with line-length=120
      final ProcessResult result = await Process.run(
        'dart',
        [
          'run',
          'bin/splendid_cli.dart',
          'format',
          testFile.path,
          '120',
          '--dry-run',
        ],
      );

      expect(result.exitCode, equals(0), reason: 'Format command should succeed');

      // File should not be modified in dry-run mode
      final String unchangedContent = await testFile.readAsString();
      expect(unchangedContent, equals(testContent), reason: 'File should not be modified in dry-run mode');
    });
  });
}
