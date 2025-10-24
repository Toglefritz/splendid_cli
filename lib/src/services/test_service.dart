import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Service for managing test file generation operations.
///
/// This service encapsulates the core business logic for test generation, separating it from CLI-specific concerns like
/// argument parsing and user interaction. This design enables reuse across different interfaces (CLI, MCP server,
/// etc.).
class TestService {
  /// Creates a new instance of [TestService].
  ///
  /// This service is stateless and can be reused across multiple operations. All methods are safe to call concurrently
  /// from different isolates.
  const TestService();

  /// Generates a test file template for the specified Dart file.
  ///
  /// This method handles the complete test generation workflow:
  /// 1. Validates the target file exists and is a Dart file
  /// 2. Determines the appropriate test type (widget or class)
  /// 3. Generates test template using Mason brick
  /// 4. Returns result with success/failure information
  ///
  /// Parameters:
  /// * [request] - Configuration for the test generation
  ///
  /// Returns:
  /// * [TestGenerationResult] with success status and details
  ///
  /// Throws:
  /// * [TestServiceException] for various failure scenarios
  Future<TestGenerationResult> generateTest(TestGenerationRequest request) async {
    try {
      // Validate request
      _validateTestRequest(request);

      // Determine test type if not explicitly specified
      final TestType testType = request.testType == TestType.auto
          ? await _detectTestType(request.targetFile)
          : request.testType;

      // Determine output path
      final String outputPath = _determineOutputPath(request.targetFile, request.outputDirectory);

      // Check if test file already exists and handle force flag
      final File outputFile = File(outputPath);
      if (outputFile.existsSync() && !request.force) {
        throw TestServiceException(
          'Test file already exists: $outputPath',
          TestServiceErrorType.testFileExists,
        );
      }

      // Load appropriate brick based on test type
      final MasonGenerator generator = await _loadTestBrick(testType);

      // Prepare template variables
      final Map<String, dynamic> vars = _prepareTemplateVariables(
        request.targetFile,
        testType,
      );

      // Generate test file
      await generator.generate(
        DirectoryGeneratorTarget(Directory(path.dirname(outputPath))),
        vars: vars,
        fileConflictResolution: request.force ? FileConflictResolution.overwrite : FileConflictResolution.skip,
      );

      return TestGenerationResult.success(
        targetFile: request.targetFile,
        outputPath: outputPath,
        testType: testType,
      );
    } catch (e) {
      if (e is TestServiceException) {
        rethrow;
      }
      throw TestServiceException(
        'Failed to generate test: $e',
        TestServiceErrorType.unknown,
        cause: e,
      );
    }
  }

  /// Validates a test generation request.
  void _validateTestRequest(TestGenerationRequest request) {
    final File targetFile = File(request.targetFile);

    if (!targetFile.existsSync()) {
      throw TestServiceException(
        'Target file does not exist: ${request.targetFile}',
        TestServiceErrorType.targetFileNotFound,
      );
    }

    if (!request.targetFile.endsWith('.dart')) {
      throw TestServiceException(
        'Target file must be a Dart file (.dart extension): ${request.targetFile}',
        TestServiceErrorType.invalidTargetFile,
      );
    }
  }

  /// Detects the appropriate test type based on file content.
  Future<TestType> _detectTestType(String targetFile) async {
    try {
      final String content = await File(targetFile).readAsString();

      // Check for Flutter widget indicators
      if (content.contains('import \'package:flutter/') ||
          content.contains('extends StatelessWidget') ||
          content.contains('extends StatefulWidget') ||
          content.contains('Widget build(')) {
        return TestType.widget;
      }

      return TestType.class_;
    } catch (e) {
      // Default to class test if we can't read the file
      return TestType.class_;
    }
  }

  /// Determines the output path for the generated test file.
  String _determineOutputPath(String targetFile, String? customOutputDirectory) {
    if (customOutputDirectory != null) {
      final String fileName = path.basenameWithoutExtension(targetFile);
      return path.join(customOutputDirectory, '${fileName}_test.dart');
    }

    // Mirror the source file structure in test/
    String relativePath = targetFile;

    // Remove lib/ prefix if present
    if (relativePath.startsWith('lib/')) {
      relativePath = relativePath.substring(4);
    }

    // Add test/ prefix and _test suffix
    final String fileName = path.basenameWithoutExtension(relativePath);
    final String directory = path.dirname(relativePath);

    return path.join('test', directory, '${fileName}_test.dart');
  }

  /// Prepares template variables for Mason brick generation.
  Map<String, dynamic> _prepareTemplateVariables(String targetFile, TestType testType) {
    final String fileName = path.basenameWithoutExtension(targetFile);
    final String className = _toPascalCase(fileName);

    return {
      'fileName': fileName,
      'className': className,
      'targetFile': targetFile,
      'isWidget': testType == TestType.widget,
    };
  }

  /// Loads the appropriate Mason brick for the test type.
  Future<MasonGenerator> _loadTestBrick(TestType testType) async {
    final String brickName = testType == TestType.widget ? 'flutter_widget_test' : 'dart_class_test';

    final String brickPath = path.join(
      path.dirname(Platform.script.path),
      '..',
      'bricks',
      brickName,
    );

    final Brick brick = Brick.path(brickPath);
    return MasonGenerator.fromBrick(brick);
  }

  /// Converts a string to PascalCase format.
  String _toPascalCase(String input) {
    return input.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join();
  }
}

/// Request configuration for test generation.
class TestGenerationRequest {
  /// Creates a test generation request.
  const TestGenerationRequest({
    required this.targetFile,
    this.outputDirectory,
    this.testType = TestType.auto,
    this.force = false,
  });

  /// Path to the Dart file to generate tests for.
  final String targetFile;

  /// Optional custom output directory for the test file.
  final String? outputDirectory;

  /// Type of test to generate.
  final TestType testType;

  /// Whether to overwrite existing test files.
  final bool force;
}

/// Result of test generation operation.
class TestGenerationResult {
  /// Creates a test generation result.
  const TestGenerationResult({
    required this.success,
    required this.targetFile,
    required this.outputPath,
    required this.testType,
    this.error,
  });

  /// Creates a successful result.
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
  final bool success;

  /// Path to the target file that was tested.
  final String targetFile;

  /// Path where the test file was created.
  final String outputPath;

  /// Type of test that was generated.
  final TestType testType;

  /// Error message if operation failed.
  final String? error;
}

/// Types of tests that can be generated.
enum TestType {
  /// Automatically detect based on file content.
  auto,

  /// Generate Flutter widget test.
  widget,

  /// Generate Dart class test.
  class_,
}

/// Exception thrown by test service operations.
class TestServiceException implements Exception {
  /// Creates a test service exception.
  const TestServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final TestServiceErrorType type;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'TestServiceException: $message';
}

/// Types of errors that can occur in test service operations.
enum TestServiceErrorType {
  /// Target file was not found.
  targetFileNotFound,

  /// Target file is not a valid Dart file.
  invalidTargetFile,

  /// Test file already exists.
  testFileExists,

  /// Unknown error occurred.
  unknown,
}
