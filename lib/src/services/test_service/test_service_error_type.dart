/// Test Service Error Type Enumeration Module
///
/// This module defines the specific types of errors that can occur during
/// test service operations. It provides enumeration values for different
/// error scenarios to enable structured error handling and appropriate
/// user feedback.
library;

/// Types of errors that can occur in test service operations.
///
/// This enumeration categorizes the different failure modes that can
/// occur during test file generation. Each error type represents a
/// specific scenario that requires different handling strategies and
/// user feedback approaches.
///
/// The error types are designed to be comprehensive enough to cover
/// all expected failure scenarios while remaining specific enough to
/// enable targeted error handling and recovery logic.
///
/// Usage:
/// ```dart
/// try {
///   await testService.generateTest(request);
/// } on TestServiceException catch (e) {
///   switch (e.type) {
///     case TestServiceErrorType.targetFileNotFound:
///       // Handle missing file scenario
///       showError('The specified file could not be found');
///       break;
///     case TestServiceErrorType.testFileExists:
///       // Handle existing test file scenario
///       askUserToOverwrite();
///       break;
///     // ... handle other error types
///   }
/// }
/// ```
enum TestServiceErrorType {
  /// Target file was not found.
  ///
  /// This error occurs when the specified target file does not exist
  /// at the given path. This is typically a user input error where
  /// an incorrect file path was provided.
  ///
  /// Recovery strategies:
  /// * Verify the file path is correct
  /// * Check if the file was moved or deleted
  /// * Provide file browser for correct path selection
  targetFileNotFound,

  /// Target file is not a valid Dart file.
  ///
  /// This error occurs when the target file exists but does not have
  /// a .dart extension or is not a valid Dart source file. The test
  /// service only supports generating tests for Dart files.
  ///
  /// Recovery strategies:
  /// * Verify the file has a .dart extension
  /// * Check if the file contains valid Dart code
  /// * Select a different target file
  invalidTargetFile,

  /// Test file already exists.
  ///
  /// This error occurs when a test file already exists at the target
  /// output location and the force flag is not set. This prevents
  /// accidental overwriting of existing test files.
  ///
  /// Recovery strategies:
  /// * Set the force flag to overwrite the existing file
  /// * Choose a different output location
  /// * Manually merge the existing and new test content
  testFileExists,

  /// Unknown error occurred.
  ///
  /// This error type is used for unexpected failures that don't fit
  /// into the other specific categories. It typically indicates an
  /// internal error or unexpected system condition.
  ///
  /// Recovery strategies:
  /// * Check system resources and permissions
  /// * Retry the operation
  /// * Report the issue for investigation
  /// * Check logs for additional error details
  unknown,
}
