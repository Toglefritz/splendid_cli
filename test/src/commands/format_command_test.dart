import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:splendid_cli/src/services/dartdoc_formatter_service.dart';
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for FormatCommand functionality.
///
/// This test suite covers the format-dartdoc command including validation,
/// error handling, and successful Dartdoc comment reformatting operations.
void main() {
  group('FormatCommand', () {
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
          ['run', 'bin/splendid_cli.dart', 'format-dartdoc'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });

      test('should work with command aliases', () async {
        final ProcessResult result = await Process.run(
          'dart',
          ['run', 'bin/splendid_cli.dart', 'fmt-doc'],
        );

        expect(result.exitCode, equals(64));
        expect(result.stderr, contains('Target path is required.'));
      });
    });

    group('file processing', () {
      test('should process single Dart file successfully', () async {
        final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
        await testFile.writeAsString('''
/// This is a very long comment that exceeds the typical 80 character line limit
/// and should be wrapped.
class TestClass {}
''');

        final ProcessResult result = await Process.run(
          'dart',
          [
            'run',
            path.join(Directory.current.path, 'bin/splendid_cli.dart'),
            'format-dartdoc',
            testFile.path,
            '--line-length',
            '80',
          ],
          workingDirectory: tempDirHelper.directoryPath,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Formatting completed successfully'));
      });
    });
  });

  group('DartdocFormatterService', () {
    late DartdocFormatterService service;
    late TempDirectoryHelper tempDirHelper;

    setUp(() {
      service = const DartdocFormatterService();
      tempDirHelper = TempDirectoryHelper();
    });

    test('should format single-line comments correctly', () async {
      final File testFile = File(path.join(tempDirHelper.directoryPath, 'test.dart'));
      await testFile.writeAsString('''
/// This is a very long single-line comment that exceeds the typical 80
/// character line limit and should be wrapped.
class TestClass {}
''');

      final DartdocFormatterRequest request = DartdocFormatterRequest(
        targetPath: testFile.path,
        lineLength: 80,
      );

      final DartdocFormatterResult result = await service.formatDartdoc(request);

      expect(result.success, isTrue);
      expect(result.modifiedFiles, contains(testFile.path));
    });
  });
}
