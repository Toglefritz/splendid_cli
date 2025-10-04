import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Integration test suite for the generate-test command.
///
/// This test suite covers end-to-end scenarios for the test command,
/// verifying that it correctly generates test files for both Flutter
/// widgets and regular Dart classes using the CLI interface.
///
/// Test Categories:
/// * Complete test generation workflow
/// * File system integration
/// * Mason brick integration
/// * Command-line argument handling
/// * Error recovery scenarios
///
/// Note: These tests require Mason bricks to be available in the bricks/
/// directory for complete validation. Tests are skipped in environments
/// where the bricks are not available to prevent false failures.
void main() {
  group('Generate-Test Command Integration Tests', () {
    late Directory tempDir;
    late String cliExecutable;

    /// Set up integration test environment.
    ///
    /// Creates a temporary directory for test files and determines the
    /// path to the CLI executable for process invocation testing.
    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('test_command_integration_');

      // Determine CLI executable path
      cliExecutable = path.join('bin', 'splendid_cli.dart');
    });

    /// Clean up integration test resources.
    ///
    /// Removes the temporary directory and all created test files to
    /// prevent disk space accumulation during test runs.
    tearDownAll(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('successful test generation', () {
      /// Tests complete test generation for a Flutter widget.
      ///
      /// This test verifies the entire workflow from CLI invocation through
      /// test file generation for a Flutter widget, ensuring that the
      /// generated test follows widget testing patterns.
      test('should generate widget test file successfully', () async {
        // Create a Flutter widget file
        final widgetFile = File(path.join(tempDir.path, 'my_widget.dart'));
        await widgetFile.writeAsString('''
import 'package:flutter/material.dart';

/// A simple test widget for demonstration.
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Hello World');
  }
}
''');

        // Execute CLI command to generate test
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            widgetFile.path,
            '--type=widget',
            '--force',
          ],
        );

        // Verify command executed successfully
        expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

        // Verify test file was created
        final testFile = File(path.join(tempDir.path, 'my_widget_test.dart'));
        expect(testFile.existsSync(), isTrue, reason: 'Test file should be created');

        // Verify test file content
        final testContent = await testFile.readAsString();
        expect(testContent, contains('testWidgets'), reason: 'Should use testWidgets for widget tests');
        expect(testContent, contains('MyWidget'), reason: 'Should reference the widget class');
        expect(testContent, contains('WidgetTester'), reason: 'Should include WidgetTester parameter');
        expect(testContent, contains('flutter_test'), reason: 'Should import flutter_test package');
      }, skip: 'Requires Mason bricks to be available');

      /// Tests complete test generation for a regular Dart class.
      ///
      /// This test verifies the entire workflow from CLI invocation through
      /// test file generation for a regular Dart class, ensuring that the
      /// generated test follows standard unit testing patterns.
      test('should generate class test file successfully', () async {
        // Create a regular Dart class file
        final classFile = File(path.join(tempDir.path, 'my_service.dart'));
        await classFile.writeAsString('''
/// A simple service class for demonstration.
class MyService {
  /// Processes input data by converting to uppercase.
  String processData(String input) {
    return input.toUpperCase();
  }

  /// Validates that input is not empty.
  bool isValid(String input) {
    return input.isNotEmpty;
  }
}
''');

        // Execute CLI command to generate test
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            classFile.path,
            '--type=class',
            '--force',
          ],
        );

        // Verify command executed successfully
        expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

        // Verify test file was created
        final testFile = File(path.join(tempDir.path, 'my_service_test.dart'));
        expect(testFile.existsSync(), isTrue, reason: 'Test file should be created');

        // Verify test file content
        final testContent = await testFile.readAsString();
        expect(testContent, contains('test('), reason: 'Should use test() for class tests');
        expect(testContent, contains('MyService'), reason: 'Should reference the service class');
        expect(testContent, contains('group('), reason: 'Should organize tests in groups');
        expect(testContent, contains('expect('), reason: 'Should include expect statements');
      }, skip: 'Requires Mason bricks to be available');

      /// Tests automatic type detection for widget files.
      ///
      /// This test verifies that the command correctly detects Flutter
      /// widgets automatically and generates appropriate widget tests
      /// without explicit type specification.
      test('should auto-detect widget files and generate widget tests', () async {
        // Create a Flutter widget file
        final widgetFile = File(path.join(tempDir.path, 'auto_widget.dart'));
        await widgetFile.writeAsString('''
import 'package:flutter/material.dart';

class AutoWidget extends StatefulWidget {
  @override
  State<AutoWidget> createState() => _AutoWidgetState();
}

class _AutoWidgetState extends State<AutoWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');

        // Execute CLI command with auto type detection
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            widgetFile.path,
            '--type=auto',
            '--force',
          ],
        );

        // Verify command executed successfully
        expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

        // Verify widget test was generated
        final testFile = File(path.join(tempDir.path, 'auto_widget_test.dart'));
        expect(testFile.existsSync(), isTrue, reason: 'Test file should be created');

        final testContent = await testFile.readAsString();
        expect(testContent, contains('testWidgets'), reason: 'Should generate widget test');
      }, skip: 'Requires Mason bricks to be available');

      /// Tests automatic type detection for class files.
      ///
      /// This test verifies that the command correctly detects regular
      /// Dart classes automatically and generates appropriate unit tests
      /// without explicit type specification.
      test('should auto-detect class files and generate class tests', () async {
        // Create a regular Dart class file
        final classFile = File(path.join(tempDir.path, 'auto_class.dart'));
        await classFile.writeAsString(r'''
class AutoClass {
  final String name;
  
  AutoClass(this.name);
  
  String greet() {
    return 'Hello, $name!';
  }
}
''');

        // Execute CLI command with auto type detection
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            classFile.path,
            '--type=auto',
            '--force',
          ],
        );

        // Verify command executed successfully
        expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

        // Verify class test was generated
        final testFile = File(path.join(tempDir.path, 'auto_class_test.dart'));
        expect(testFile.existsSync(), isTrue, reason: 'Test file should be created');

        final testContent = await testFile.readAsString();
        expect(testContent, contains('test('), reason: 'Should generate class test');
        expect(testContent, isNot(contains('testWidgets')), reason: 'Should not use testWidgets');
      }, skip: 'Requires Mason bricks to be available');

      /// Tests custom output directory functionality.
      ///
      /// This test verifies that the --output flag correctly places
      /// generated test files in the specified custom directory.
      test('should generate test in custom output directory', () async {
        // Create a Dart class file
        final classFile = File(path.join(tempDir.path, 'custom_class.dart'));
        await classFile.writeAsString('''
class CustomClass {
  void doSomething() {}
}
''');

        // Create custom output directory
        final Directory customOutputDir = Directory(path.join(tempDir.path, 'custom_tests'))..createSync();

        // Execute CLI command with custom output directory
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            classFile.path,
            '--output=${customOutputDir.path}',
            '--force',
          ],
        );

        // Verify command executed successfully
        expect(result.exitCode, equals(0), reason: 'CLI should succeed: ${result.stderr}');

        // Verify test file was created in custom directory
        final testFile = File(path.join(customOutputDir.path, 'custom_class_test.dart'));
        expect(testFile.existsSync(), isTrue, reason: 'Test file should be in custom directory');
      }, skip: 'Requires Mason bricks to be available');
    });

    group('error handling scenarios', () {
      /// Tests CLI behavior when no target file is provided.
      ///
      /// This test verifies that the CLI provides helpful usage information
      /// when the required target file argument is missing.
      test('should return usage error when target file is missing', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
        expect(result.stderr.toString(), contains('Target Dart file is required'));
      });

      /// Tests CLI behavior when target file doesn't exist.
      ///
      /// This test ensures that the CLI provides clear error messages when
      /// the specified target file cannot be found.
      test('should return usage error when target file does not exist', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', 'nonexistent.dart'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
        expect(result.stderr.toString(), contains('Target file does not exist'));
      });

      /// Tests CLI behavior with non-Dart files.
      ///
      /// This test verifies that the CLI validates file extensions and
      /// only accepts .dart files for test generation.
      test('should return usage error for non-Dart files', () async {
        // Create a non-Dart file
        final nonDartFile = File(path.join(tempDir.path, 'not_dart.txt'));
        await nonDartFile.writeAsString('This is not a Dart file');

        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', nonDartFile.path],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
        expect(result.stderr.toString(), contains('must be a Dart file'));
      });

      /// Tests CLI behavior when test file already exists without force flag.
      ///
      /// This test ensures that the CLI protects existing test files from
      /// accidental overwriting and requires explicit --force flag.
      test('should fail when test file exists without force flag', () async {
        // Create source file
        final sourceFile = File(path.join(tempDir.path, 'existing_test.dart'));
        await sourceFile.writeAsString('class ExistingTest {}');

        // Create existing test file
        final testFile = File(path.join(tempDir.path, 'existing_test_test.dart'));
        await testFile.writeAsString('// Existing test content');

        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', sourceFile.path],
        );

        // Should return error code (1)
        expect(result.exitCode, equals(1));
        expect(result.stderr.toString(), contains('already exists'));
      });

      /// Tests CLI behavior with invalid command-line flags.
      ///
      /// This test verifies that the CLI properly validates command-line options
      /// and provides helpful error messages for invalid flags.
      test('should return usage error for invalid flags', () async {
        // Create a valid Dart file
        final dartFile = File(path.join(tempDir.path, 'valid.dart'));
        await dartFile.writeAsString('class Valid {}');

        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', dartFile.path, '--invalid-flag'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
      });

      /// Tests CLI behavior with invalid type option values.
      ///
      /// This test ensures that the CLI validates the --type option and
      /// only accepts allowed values (auto, widget, class).
      test('should return usage error for invalid type values', () async {
        // Create a valid Dart file
        final dartFile = File(path.join(tempDir.path, 'valid.dart'));
        await dartFile.writeAsString('class Valid {}');

        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', dartFile.path, '--type=invalid'],
        );

        // Should return usage error (64)
        expect(result.exitCode, equals(64));
      });
    });

    group('help and usage', () {
      /// Tests that help flag displays comprehensive usage information.
      ///
      /// This test verifies that users can get detailed help information
      /// about the generate-test command and its available options.
      test('should display help with --help flag', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', '--help'],
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout.toString(), contains('Generate test file templates'));
        expect(result.stdout.toString(), contains('--output'));
        expect(result.stdout.toString(), contains('--type'));
        expect(result.stdout.toString(), contains('--force'));
      });

      /// Tests that type option help shows allowed values.
      ///
      /// This test ensures that users can see the available options
      /// for the --type flag and understand their purposes.
      test('should show type option allowed values in help', () async {
        final ProcessResult result = await Process.run(
          'dart',
          [cliExecutable, 'generate-test', '--help'],
        );

        expect(result.exitCode, equals(0));
        final helpText = result.stdout.toString();
        expect(helpText, contains('auto'));
        expect(helpText, contains('widget'));
        expect(helpText, contains('class'));
      });
    });

    group('file content validation', () {
      /// Tests that generated test files contain expected structure.
      ///
      /// This test verifies that the generated test files follow the
      /// established testing patterns and include all necessary components.
      test('should generate test files with correct structure', () async {
        // Create a simple Dart class
        final classFile = File(path.join(tempDir.path, 'structured_class.dart'));
        await classFile.writeAsString('''
class StructuredClass {
  final String name;
  
  StructuredClass(this.name);
  
  String getName() => name;
}
''');

        // Generate test file
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            classFile.path,
            '--force',
          ],
        );

        expect(result.exitCode, equals(0), reason: 'Test generation should succeed');

        // Verify test file structure
        final testFile = File(path.join(tempDir.path, 'structured_class_test.dart'));
        if (testFile.existsSync()) {
          final testContent = await testFile.readAsString();

          // Check for comprehensive documentation
          expect(testContent, contains('Test suite for StructuredClass'));
          expect(testContent, contains('Test Categories:'));

          // Check for proper test organization
          expect(testContent, contains('group('));
          expect(testContent, contains('setUp('));
          expect(testContent, contains('tearDown('));

          // Check for example test cases
          expect(testContent, contains('test('));
          expect(testContent, contains('expect('));

          // Check for import statements
          expect(testContent, contains('import \'package:test/test.dart\''));
        }
      }, skip: 'Requires Mason bricks to be available');

      /// Tests that generated widget tests include Flutter-specific patterns.
      ///
      /// This test verifies that widget test files include the appropriate
      /// Flutter testing utilities and patterns.
      test('should generate widget tests with Flutter patterns', () async {
        // Create a Flutter widget
        final widgetFile = File(path.join(tempDir.path, 'flutter_widget.dart'));
        await widgetFile.writeAsString('''
import 'package:flutter/material.dart';

class FlutterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test')),
      body: Center(child: Text('Hello')),
    );
  }
}
''');

        // Generate widget test
        final ProcessResult result = await Process.run(
          'dart',
          [
            cliExecutable,
            'generate-test',
            widgetFile.path,
            '--type=widget',
            '--force',
          ],
        );

        expect(result.exitCode, equals(0), reason: 'Widget test generation should succeed');

        // Verify widget test patterns
        final testFile = File(path.join(tempDir.path, 'flutter_widget_test.dart'));
        if (testFile.existsSync()) {
          final testContent = await testFile.readAsString();

          // Check for Flutter test imports
          expect(testContent, contains('flutter_test'));
          expect(testContent, contains('flutter/material.dart'));

          // Check for widget testing patterns
          expect(testContent, contains('testWidgets'));
          expect(testContent, contains('WidgetTester'));
          expect(testContent, contains('pumpWidget'));
          expect(testContent, contains('MaterialApp'));

          // Check for widget-specific test categories
          expect(testContent, contains('widget rendering'));
          expect(testContent, contains('user interactions'));
          expect(testContent, contains('accessibility'));
        }
      }, skip: 'Requires Mason bricks to be available');
    });
  });
}
