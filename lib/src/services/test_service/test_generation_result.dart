/// Test Generation Result Module
///
/// This module contains the result class for test generation operations within
/// the test service. It encapsulates the outcome of test file generation,
/// including success/failure status and relevant metadata.
library;

import 'test_type.dart';

/// Result of test generation operation.
///
/// This class represents the outcome of a test file generation request,
/// providing information about success or failure, file paths, and test type
/// information. It includes factory constructors for common result patterns to
/// simplify result creation.
///
/// The result contains all necessary information for the caller to understand
/// what happened during the test generation process and take appropriate action
/// based on the outcome.
///
/// Usage:
/// ```dart
/// // Success case
/// final result = TestGenerationResult.success(
/// targetFile: 'lib/widgets/my_widget.dart',
/// outputPath: 'test/widgets/my_widget_test.dart',
/// testType: TestType.widget,
/// );
///
/// // Failure case
/// final result = TestGenerationResult.failure(
/// targetFile: 'lib/widgets/my_widget.dart',
/// error: 'Target file not found',
/// );
/// ```
class TestGenerationResult {
  /// Creates a test generation result.
  ///
  /// Parameters:
  /// * [success] - Whether the operation was successful
  /// * [targetFile] - Path to the target file that was processed
  /// * [outputPath] - Path where the test file was created (empty on failure)
  /// * [testType] - Type of test that was generated
  /// * [error] - Error message if operation failed (null on success)
  const TestGenerationResult({
    required this.success,
    required this.targetFile,
    required this.outputPath,
    required this.testType,
    this.error,
  });

  /// Creates a successful result.
  ///
  /// This factory constructor creates a result indicating successful test
  /// generation with all the relevant metadata about the generated test file.
  ///
  /// Parameters:
  /// * [targetFile] - Path to the source file that was processed
  /// * [outputPath] - Path where the test file was successfully created
  /// * [testType] - Type of test that was generated
  const TestGenerationResult.success({
    required String targetFile,
    required String outputPath,
    required TestType testType,
  }) : this(
         success: true,
         targetFile: targetFile,
         outputPath: outputPath,
         testType: testType,
       );

  /// Creates a failed result.
  ///
  /// This factory constructor creates a result indicating failed test
  /// generation with an error message describing what went wrong.
  ///
  /// Parameters:
  /// * [targetFile] - Path to the source file that was being processed
  /// * [error] - Human-readable error message describing the failure
  const TestGenerationResult.failure({
    required String targetFile,
    required String error,
  }) : this(
         success: false,
         targetFile: targetFile,
         outputPath: '',
         testType: TestType.auto,
         error: error,
       );

  /// Whether the operation was successful.
  ///
  /// True indicates that the test file was successfully generated at the
  /// specified output path. False indicates that the operation failed and the
  /// [error] field contains details about the failure.
  final bool success;

  /// Path to the target file that was tested.
  ///
  /// This is the original source file path that was provided in the test
  /// generation request. It's included in both success and failure results for
  /// reference and logging purposes.
  final String targetFile;

  /// Path where the test file was created.
  ///
  /// On successful operations, this contains the full path to the generated
  /// test file. On failed operations, this will be an empty string.
  final String outputPath;

  /// Type of test that was generated.
  ///
  /// Indicates which test template was used for generation:
  /// * [TestType.widget] - Flutter widget test template was used
  /// * [TestType.class_] - Dart class test template was used
  /// * [TestType.auto] - Used in failure cases where type wasn't determined
  final TestType testType;

  /// Error message if operation failed.
  ///
  /// Contains a human-readable description of what went wrong during test
  /// generation. This field is null for successful operations and contains a
  /// descriptive error message for failed operations.
  final String? error;
}
