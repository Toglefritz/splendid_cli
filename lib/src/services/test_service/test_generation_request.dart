/// Test Generation Request Module
///
/// This module contains the request configuration class for test generation
/// operations within the test service. It defines the parameters and options
/// that control how test files are generated from Dart source files.
library;

import 'test_type.dart';

/// Request configuration for test generation.
///
/// This class encapsulates all the parameters needed to generate a test file
/// for a given Dart source file. It provides configuration options for output
/// location, test type selection, and file overwrite behavior.
///
/// The request supports automatic test type detection based on file content, or
/// explicit specification of the desired test type (widget vs class test).
///
/// Usage:
/// ```dart
/// final request = TestGenerationRequest(
/// targetFile: 'lib/widgets/my_widget.dart',
/// testType: TestType.widget,
/// force: true,
/// );
/// ```
class TestGenerationRequest {
  /// Creates a test generation request.
  ///
  /// Parameters:
  /// * [targetFile] - Path to the Dart file to generate tests for (required)
  /// * [outputDirectory] - Optional custom output directory for the test file
  /// * [testType] - Type of test to generate (defaults to auto-detection)
  /// * [force] - Whether to overwrite existing test files (defaults to false)
  const TestGenerationRequest({
    required this.targetFile,
    this.outputDirectory,
    this.testType = TestType.auto,
    this.force = false,
  });

  /// Path to the Dart file to generate tests for.
  ///
  /// This should be a valid path to an existing Dart file (.dart extension).
  /// The file content will be analyzed to determine the appropriate test type
  /// if [testType] is set to [TestType.auto].
  final String targetFile;

  /// Optional custom output directory for the test file.
  ///
  /// When specified, the generated test file will be placed in this directory
  /// with the naming pattern `{filename}_test.dart`. When null, the test file
  /// will be placed in the standard `test/` directory mirroring the source file
  /// structure.
  final String? outputDirectory;

  /// Type of test to generate.
  ///
  /// Determines which Mason brick template to use for test generation:
  /// * [TestType.auto] - Automatically detect based on file content
  /// * [TestType.widget] - Generate Flutter widget test template
  /// * [TestType.class_] - Generate Dart class test template
  final TestType testType;

  /// Whether to overwrite existing test files.
  ///
  /// When true, existing test files at the target location will be overwritten.
  /// When false, the operation will fail if a test file already exists at the
  /// target location.
  final bool force;
}
