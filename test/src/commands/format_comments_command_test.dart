import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:splendid_cli/src/services/comment_formatter_service.dart';
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for FormatCommentsCommand functionality.
///
/// This test suite covers the format-comments command including validation,
/// error handling, and successful regular comment reformatting operations.
void main() {
  group('FormatCommentsCommand', () {
    late TempDirectoryHelper tempDirHelper;

    setUp(() {
      tempDirHelper = TempDirectoryHelper();
    });

    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('command validation', () {
      test('should fail when no target path provided', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'format-comments'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });

      test('should work with command aliases', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'fmt-comments'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });
    });

    group('file processing', () {
      test('should process single Dart file successfully', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
// This is a very long regular comment that exceeds the typical 80 character
// line limit and should be wrapped.
class TestClass {}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format-comments',
            testFile.path,
            '--line-length',
            '80',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Formatting completed successfully'));
      });

      test('should not modify Dartdoc comments', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
/// This is a very long Dartdoc comment that exceeds the typical 80 character
/// line limit but should NOT be wrapped.
// This is a regular comment that should be wrapped.
class TestClass {}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format-comments',
            testFile.path,
            '--line-length',
            '80',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));

        final String content = await testFile.readAsString();
        expect(content, contains('/// This is a very long Dartdoc comment'));
      });
    });
  });

  group('CommentFormatterService', () {
    late CommentFormatterService service;
    late TempDirectoryHelper tempDirHelper;

    setUp(() {
      service = const CommentFormatterService();
      tempDirHelper = TempDirectoryHelper();
    });

    tearDown(() {
      tempDirHelper.cleanup();
    });

    test('should format regular comments correctly', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      await testFile.writeAsString('''
// This is a very long regular comment that definitely exceeds the typical eighty character line limit and should be wrapped by the formatter.
class TestClass {}
''');

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 80,
      );

      final CommentFormatterResult result = await service.formatComments(request);

      expect(result.success, isTrue);
      expect(result.modifiedFiles, contains(testFile.path));
    });

    test('should preserve Dartdoc comments unchanged', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      const String originalContent = '''
/// This is a Dartdoc comment that should not be modified.
// This is a regular comment.
class TestClass {}
''';
      await testFile.writeAsString(originalContent);

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 80,
      );

      await service.formatComments(request);

      final String content = await testFile.readAsString();
      expect(content, contains('/// This is a Dartdoc comment that should not be modified.'));
    });

    test('should handle multiple comment blocks', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      await testFile.writeAsString('''
// First comment block that is very long and exceeds the line limit.
class FirstClass {}

// Second comment block that is also very long and exceeds the line limit.
class SecondClass {}
''');

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 50,
      );

      final CommentFormatterResult result = await service.formatComments(request);

      expect(result.success, isTrue);
      expect(result.modifiedFiles, contains(testFile.path));

      final String content = await testFile.readAsString();
      final List<String> lines = content.split('\n');
      final List<String> commentLines = lines.where((String line) => line.trim().startsWith('//')).toList();

      for (final String line in commentLines) {
        expect(line.length, lessThanOrEqualTo(53));
      }
    });

    test('should preserve code blocks in comments', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      await testFile.writeAsString('''
// Example usage:
// ```dart
// final String result = someFunction();
// ```
class TestClass {}
''');

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 80,
      );

      final CommentFormatterResult result = await service.formatComments(request);

      expect(result.success, isTrue);

      final String content = await testFile.readAsString();
      expect(content, contains('```dart'));
      expect(content, contains('final String result = someFunction();'));
    });

    test('should handle dry-run mode', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      const String originalContent = '''
// This is a very long regular comment that definitely exceeds the typical eighty character line limit and should be wrapped by the formatter.
class TestClass {}
''';
      await testFile.writeAsString(originalContent);

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 80,
        dryRun: true,
      );

      final CommentFormatterResult result = await service.formatComments(request);

      expect(result.success, isTrue);
      expect(result.dryRun, isTrue);
      expect(result.modifiedFiles, contains(testFile.path));

      final String content = await testFile.readAsString();
      expect(content, equals(originalContent));
    });

    test('should validate line length bounds', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      await testFile.writeAsString('// Comment\nclass TestClass {}');

      final CommentFormatterRequest invalidRequest = CommentFormatterRequest(
        targetPath: testFile.path,
        lineLength: 30,
      );

      expect(
        () => service.formatComments(invalidRequest),
        throwsA(isA<CommentFormatterException>()),
      );
    });

    test('should handle non-existent target path', () async {
      const CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: '/non/existent/path.dart',
        lineLength: 80,
      );

      expect(
        () => service.formatComments(request),
        throwsA(isA<CommentFormatterException>()),
      );
    });

    test('should process directory recursively', () async {
      final Directory subDir = Directory(path.join(tempDirHelper.directoryPath, 'lib'));
      await subDir.create();

      final File file1 = File(path.join(subDir.path, 'file1.dart'));
      await file1.writeAsString('// Long comment that exceeds limit\nclass Class1 {}');

      final File file2 = File(path.join(subDir.path, 'file2.dart'));
      await file2.writeAsString('// Another long comment that exceeds limit\nclass Class2 {}');

      final CommentFormatterRequest request = CommentFormatterRequest(
        targetPath: tempDirHelper.directoryPath,
        lineLength: 40,
      );

      final CommentFormatterResult result = await service.formatComments(request);

      expect(result.success, isTrue);
      expect(result.processedFiles.length, equals(2));
    });
  });
}
