import 'dart:io';

import 'package:splendid_cli/src/services/enum_sorter_service.dart';
import 'package:test/test.dart';

import '../../helpers/temp_directory_helper.dart';

/// Test suite for [EnumSorterService].
///
/// Validates the core sorting logic for simple enums, enhanced enums with
/// constructor arguments, enums with documentation comments, and edge cases
/// like already-sorted enums and files with multiple enum declarations.
void main() {
  group('EnumSorterService', () {
    late EnumSorterService service;
    late TempDirectoryHelper tempDirHelper;

    setUp(() {
      service = const EnumSorterService();
      tempDirHelper = TempDirectoryHelper();
    });

    tearDown(() {
      tempDirHelper.cleanup();
    });

    group('simple enums', () {
      /// Verifies basic alphabetical sorting of plain enum values.
      test('should sort values alphabetically', () async {
        final File file = tempDirHelper.createFile(
          'simple.dart',
          '''
enum Color {
  red,
  green,
  blue,
}
''',
        );

        final EnumSorterResult result = await service.sortEnums(
          EnumSorterRequest(targetPath: file.path),
        );

        expect(result.enumsFound, equals(1));
        expect(result.enumsSorted, equals(1));
        expect(result.success, isTrue);

        final String content = file.readAsStringSync();
        final int blueIndex = content.indexOf('blue');
        final int greenIndex = content.indexOf('green');
        final int redIndex = content.indexOf('red,');

        expect(blueIndex, lessThan(greenIndex));
        expect(greenIndex, lessThan(redIndex));
      });

      /// Verifies that an already-sorted enum reports zero modifications.
      test('should report no changes for sorted enum', () async {
        final File file = tempDirHelper.createFile(
          'sorted.dart',
          '''
enum Color {
  blue,
  green,
  red,
}
''',
        );

        final EnumSorterResult result = await service.sortEnums(
          EnumSorterRequest(targetPath: file.path),
        );

        expect(result.enumsFound, equals(1));
        expect(result.enumsSorted, equals(0));
        expect(result.hasModifications, isFalse);
      });

      /// Verifies that dry-run mode does not write changes to disk.
      test('should not modify file in dry-run mode', () async {
        const String original = '''
enum Color {
  red,
  green,
  blue,
}
''';
        final File file = tempDirHelper.createFile(
          'dryrun.dart',
          original,
        );

        final EnumSorterResult result = await service.sortEnums(
          EnumSorterRequest(targetPath: file.path, dryRun: true),
        );

        expect(result.enumsSorted, equals(1));
        expect(result.dryRun, isTrue);
        expect(file.readAsStringSync(), equals(original));
      });
    });

    group('enhanced enums', () {
      /// Verifies sorting of enum values that have constructor arguments,
      /// preserving the arguments and the members section.
      test(
        'should sort values with constructor arguments',
        () async {
          final File file = tempDirHelper.createFile(
            'enhanced.dart',
            '''
enum Priority {
  medium(value: 2),
  high(value: 3),
  low(value: 1);

  final int value;
  const Priority({required this.value});
}
''',
          );

          final EnumSorterResult result = await service.sortEnums(
            EnumSorterRequest(targetPath: file.path),
          );

          expect(result.enumsSorted, equals(1));

          final String content = file.readAsStringSync();
          final int highIndex = content.indexOf('high(');
          final int lowIndex = content.indexOf('low(');
          final int mediumIndex = content.indexOf('medium(');

          expect(highIndex, lessThan(lowIndex));
          expect(lowIndex, lessThan(mediumIndex));

          // Members section must be preserved.
          expect(content, contains('final int value;'));
          expect(
            content,
            contains(
              'const Priority({required this.value});',
            ),
          );
        },
      );

      /// Verifies that static methods and other members after the semicolon
      /// are preserved exactly as they were.
      test('should preserve static methods in enum body', () async {
        final File file = tempDirHelper.createFile(
          'with_methods.dart',
          '''
enum Status {
  pending(code: 0),
  active(code: 1);

  final int code;
  const Status({required this.code});

  static Status fromCode(int code) {
    return Status.values.firstWhere((Status s) => s.code == code);
  }
}
''',
        );

        final EnumSorterResult result = await service.sortEnums(
          EnumSorterRequest(targetPath: file.path),
        );

        expect(result.success, isTrue);

        final String content = file.readAsStringSync();
        expect(content, contains('static Status fromCode'));
        expect(
          content,
          contains('return Status.values.firstWhere'),
        );
      });
    });

    group('documentation comments', () {
      /// Verifies that doc comments on enum values travel with their
      /// respective values during sorting.
      test(
        'should keep doc comments attached to their values',
        () async {
          final File file = tempDirHelper.createFile(
            'documented.dart',
            '''
enum Animal {
  /// A feline creature.
  cat,
  /// A canine creature.
  dog,
  /// A large mammal.
  bear,
}
''',
          );

          final EnumSorterResult result = await service.sortEnums(
            EnumSorterRequest(targetPath: file.path),
          );

          expect(result.enumsSorted, equals(1));

          final String content = file.readAsStringSync();

          // After sorting: bear, cat, dog.
          final int bearDoc = content.indexOf(
            '/// A large mammal.',
          );
          final int bearVal = content.indexOf('bear');
          final int catDoc = content.indexOf(
            '/// A feline creature.',
          );
          final int catVal = content.indexOf('cat');
          final int dogDoc = content.indexOf(
            '/// A canine creature.',
          );
          final int dogVal = content.indexOf('dog');

          // Each doc comment precedes its value.
          expect(bearDoc, lessThan(bearVal));
          expect(catDoc, lessThan(catVal));
          expect(dogDoc, lessThan(dogVal));

          // Values are in alphabetical order.
          expect(bearVal, lessThan(catVal));
          expect(catVal, lessThan(dogVal));
        },
      );
    });

    group('multiple enums', () {
      /// Verifies that all enums in a file are found and sorted
      /// independently.
      test('should sort all enums in a file', () async {
        final File file = tempDirHelper.createFile(
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

        final EnumSorterResult result = await service.sortEnums(
          EnumSorterRequest(targetPath: file.path),
        );

        expect(result.enumsFound, equals(2));
        expect(result.enumsSorted, equals(2));
      });
    });

    group('error handling', () {
      /// Verifies that a non-existent file throws [EnumSorterException] with
      /// the correct error type.
      test('should throw for non-existent file', () async {
        expect(
          () => service.sortEnums(
            const EnumSorterRequest(
              targetPath: 'nonexistent.dart',
            ),
          ),
          throwsA(
            isA<EnumSorterException>().having(
              (e) => e.type,
              'type',
              EnumSorterErrorType.targetNotFound,
            ),
          ),
        );
      });

      /// Verifies that a non-.dart file throws [EnumSorterException] with
      /// the correct error type.
      test('should throw for non-dart file', () async {
        final File file = tempDirHelper.createFile(
          'test.txt',
          'not dart',
        );

        expect(
          () => service.sortEnums(
            EnumSorterRequest(targetPath: file.path),
          ),
          throwsA(
            isA<EnumSorterException>().having(
              (e) => e.type,
              'type',
              EnumSorterErrorType.invalidFileType,
            ),
          ),
        );
      });

      /// Verifies that a .dart file with no enums throws
      /// [EnumSorterException] with the correct error type.
      test('should throw when no enums found', () async {
        final File file = tempDirHelper.createFile(
          'no_enum.dart',
          'class Foo {}\n',
        );

        expect(
          () => service.sortEnums(
            EnumSorterRequest(targetPath: file.path),
          ),
          throwsA(
            isA<EnumSorterException>().having(
              (e) => e.type,
              'type',
              EnumSorterErrorType.noEnumsFound,
            ),
          ),
        );
      });
    });
  });
}
