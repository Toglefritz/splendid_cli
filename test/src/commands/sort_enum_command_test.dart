import 'dart:io';

import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for the sort-enum command.
///
/// Validates command-line argument handling, exit codes, and end-to-end
/// sorting behavior for both simple and enhanced Dart enums.
void main() {
  group('SortEnumCommand', () {
    late TempDirectoryHelper tempDirHelper;

    setUp(() {
      tempDirHelper = TempDirectoryHelper();
    });

    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('command validation', () {
      /// Verifies that the command exits with code 64 when no target path is
      /// provided, matching the behavior of other commands in the CLI.
      test('should fail when no target path provided', () async {
        final ProcessResult result = await Process.run(
          'dart',
          <String>['run', 'bin/splendid_cli.dart', 'sort-enum'],
        );

        expect(result.exitCode, equals(64));
        expect(
          result.stderr,
          contains('Target Dart file path is required.'),
        );
      });

      /// Verifies that the enum-sort alias works identically to sort-enum.
      test('should work with command alias', () async {
        final ProcessResult result = await Process.run(
          'dart',
          <String>['run', 'bin/splendid_cli.dart', 'enum-sort'],
        );

        expect(result.exitCode, equals(64));
        expect(
          result.stderr,
          contains('Target Dart file path is required.'),
        );
      });

      /// Verifies that a non-existent file path produces an appropriate error.
      test('should fail when target file does not exist', () async {
        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            'nonexistent.dart',
          ],
        );

        expect(result.exitCode, equals(64));
        expect(
          result.stderr,
          contains('Target path does not exist'),
        );
      });

      /// Verifies that a non-.dart file is rejected.
      test('should fail when target is not a .dart file', () async {
        final File nonDartFile = tempDirHelper.createFile(
          'test.txt',
          'not a dart file',
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            nonDartFile.path,
          ],
        );

        expect(result.exitCode, equals(64));
        expect(
          result.stderr,
          contains('Target file must be a .dart file'),
        );
      });

      /// Verifies that a .dart file with no enums produces an appropriate
      /// error.
      test('should fail when file contains no enums', () async {
        final File noEnumFile = tempDirHelper.createFile(
          'no_enum.dart',
          'class Foo {}\n',
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            noEnumFile.path,
          ],
        );

        expect(result.exitCode, equals(64));
        expect(
          result.stderr,
          contains('No enum declarations found'),
        );
      });
    });

    group('simple enum sorting', () {
      /// Verifies that a simple enum with unsorted values is reordered
      /// alphabetically.
      test('should sort simple enum values alphabetically', () async {
        final File testFile = tempDirHelper.createFile(
          'simple.dart',
          '''
enum Fruit {
  cherry,
  apple,
  banana,
}
''',
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            testFile.path,
          ],
        );

        expect(result.exitCode, equals(0));

        final String content = testFile.readAsStringSync();
        final int appleIndex = content.indexOf('apple');
        final int bananaIndex = content.indexOf('banana');
        final int cherryIndex = content.indexOf('cherry');

        expect(appleIndex, lessThan(bananaIndex));
        expect(bananaIndex, lessThan(cherryIndex));
      });

      /// Verifies that an already-sorted enum is left unchanged and reported
      /// as having zero modifications.
      test('should not modify already sorted enum', () async {
        const String original = '''
enum Fruit {
  apple,
  banana,
  cherry,
}
''';
        final File testFile = tempDirHelper.createFile(
          'sorted.dart',
          original,
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            testFile.path,
          ],
        );

        expect(result.exitCode, equals(0));
        expect(
          result.stdout,
          contains('already properly sorted'),
        );
      });

      /// Verifies that dry-run mode reports changes without modifying the
      /// file.
      test('should not modify file in dry-run mode', () async {
        const String original = '''
enum Fruit {
  cherry,
  apple,
  banana,
}
''';
        final File testFile = tempDirHelper.createFile(
          'dryrun.dart',
          original,
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            testFile.path,
            '--dry-run',
          ],
        );

        expect(result.exitCode, equals(0));
        expect(
          result.stdout,
          contains('would be reordered'),
        );

        final String content = testFile.readAsStringSync();
        expect(content, equals(original));
      });
    });

    group('enhanced enum sorting', () {
      /// Verifies that an enhanced enum with constructor arguments is sorted
      /// correctly, preserving the arguments and the members section.
      test(
        'should sort enhanced enum preserving constructor args',
        () async {
          final File testFile = tempDirHelper.createFile(
            'enhanced.dart',
            '''
enum Priority {
  high(value: 3),
  low(value: 1),
  medium(value: 2);

  final int value;
  const Priority({required this.value});
}
''',
          );

          final ProcessResult result = await Process.run(
            'dart',
            <String>[
              'run',
              'bin/splendid_cli.dart',
              'sort-enum',
              testFile.path,
            ],
          );

          expect(result.exitCode, equals(0));

          final String content = testFile.readAsStringSync();
          final int highIndex = content.indexOf('high(');
          final int lowIndex = content.indexOf('low(');
          final int mediumIndex = content.indexOf('medium(');

          expect(highIndex, lessThan(lowIndex));
          expect(lowIndex, lessThan(mediumIndex));

          // Verify members section is preserved.
          expect(content, contains('final int value;'));
          expect(
            content,
            contains(
              'const Priority({required this.value});',
            ),
          );
        },
      );

      /// Verifies that documentation comments on individual enum values
      /// travel with their values during sorting.
      test(
        'should preserve doc comments on enum values',
        () async {
          final File testFile = tempDirHelper.createFile(
            'documented.dart',
            '''
enum Status {
  /// Represents a completed state.
  completed,
  /// Represents an active state.
  active,
}
''',
          );

          final ProcessResult result = await Process.run(
            'dart',
            <String>[
              'run',
              'bin/splendid_cli.dart',
              'sort-enum',
              testFile.path,
            ],
          );

          expect(result.exitCode, equals(0));

          final String content = testFile.readAsStringSync();

          // Active should come before completed after sorting.
          final int activeDocIndex = content.indexOf(
            '/// Represents an active state.',
          );
          final int activeIndex = content.indexOf('active');
          final int completedDocIndex = content.indexOf(
            '/// Represents a completed state.',
          );
          final int completedIndex = content.indexOf('completed');

          // Doc comment should immediately precede its value.
          expect(activeDocIndex, lessThan(activeIndex));
          expect(completedDocIndex, lessThan(completedIndex));

          // Active should come before completed.
          expect(activeIndex, lessThan(completedIndex));
        },
      );
    });

    group('multiple enums', () {
      /// Verifies that all enum declarations in a file are sorted
      /// independently.
      test('should sort all enums in a file', () async {
        final File testFile = tempDirHelper.createFile(
          'multiple.dart',
          '''
enum First {
  zebra,
  apple,
}

enum Second {
  omega,
  alpha,
}
''',
        );

        final ProcessResult result = await Process.run(
          'dart',
          <String>[
            'run',
            'bin/splendid_cli.dart',
            'sort-enum',
            testFile.path,
          ],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, contains('Enums found: 2'));
        expect(result.stdout, contains('Enums sorted: 2'));

        final String content = testFile.readAsStringSync();

        // First enum: apple before zebra.
        final int appleIndex = content.indexOf('apple');
        final int zebraIndex = content.indexOf('zebra');
        expect(appleIndex, lessThan(zebraIndex));

        // Second enum: alpha before omega.
        final int alphaIndex = content.indexOf('alpha');
        final int omegaIndex = content.indexOf('omega');
        expect(alphaIndex, lessThan(omegaIndex));
      });
    });
  });
}
