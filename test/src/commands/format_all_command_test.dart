import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for FormatAllCommand functionality.
///
/// This test suite covers the unified format command that orchestrates Dartdoc formatting, regular comment formatting,
/// and Dart code formatting in a single operation.
void main() {
  group('FormatAllCommand', () {
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
          ['run', 'bin/splendid_cli.dart', 'format'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });

      test('should work with command alias', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'fmt'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });
    });

    group('file processing', () {
      test('should process all formatting operations successfully', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
/// This is a very long Dartdoc comment that exceeds the typical 80 character line limit and should be wrapped.
// This is a very long regular comment that exceeds the typical 80 character line limit and should be wrapped.
class TestClass {
  void method(){print('hello');}
}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            testFile.path,
            '--line-length',
            '80',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('All formatting operations completed successfully'));
        expect(result.stdout, contains('Step 1/3: Formatting Dartdoc comments'));
        expect(result.stdout, contains('Step 2/3: Formatting regular comments'));
        expect(result.stdout, contains('Step 3/3: Formatting Dart code'));

        final String content = await testFile.readAsString();
        expect(content, contains('void method() {'));
      });

      test('should work in dry-run mode', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        final String originalContent = '''
/// This is a very long Dartdoc comment that exceeds the typical 80 character line limit and should be wrapped.
class TestClass {}
''';
        await testFile.writeAsString(originalContent);

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            testFile.path,
            '--line-length',
            '80',
            '--dry-run',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Dry run complete'));

        final String content = await testFile.readAsString();
        expect(content, equals(originalContent));
      });

      test('should process directory recursively', () async {
        final Directory subDir = Directory(path.join(tempDirHelper.directoryPath, 'lib'));
        await subDir.create();

        final File file1 = File(path.join(subDir.path, 'file1.dart'));
        await file1.writeAsString('''
/// Long Dartdoc comment that exceeds limit
class Class1 {}
''');

        final File file2 = File(path.join(subDir.path, 'file2.dart'));
        await file2.writeAsString('''
// Long regular comment that exceeds limit
class Class2 {}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            tempDirHelper.directoryPath,
            '--line-length',
            '40',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('All formatting operations completed successfully'));
      });

      test('should handle files with no formatting needed', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
/// Short comment.
class TestClass {
  void method() {
    print('hello');
  }
}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            testFile.path,
            '--line-length',
            '120',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('All formatting operations completed successfully'));
      });

      test('should handle invalid line length', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('class TestClass {}');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            testFile.path,
            '--line-length',
            'invalid',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Invalid line length'));
      });
    });

    group('integration', () {
      test('should format all comment types and code together', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
/// This is a very long Dartdoc comment that exceeds the typical 80 character line limit and should be wrapped to multiple lines.

// This is a very long regular comment that exceeds the typical 80 character line limit and should also be wrapped.

class TestClass {
  /// Another long Dartdoc comment here that talks about implementation details and exceeds the line limit.
  void someMethod() {
    // Implementation comment that is quite long and exceeds reasonable line limits.
    final String message='hello world';
    print(message);
  }
}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format',
            testFile.path,
            '--line-length',
            '80',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));

        final String content = await testFile.readAsString();

        expect(content, contains('/// This is a very long Dartdoc comment that exceeds the typical 80'));
        expect(content, contains('/// character line limit'));

        expect(content, contains('// This is a very long regular comment that exceeds the typical 80'));
        expect(content, contains('// character line limit'));

        expect(content, contains("final String message = 'hello world';"));
      });
    });
  });
}
