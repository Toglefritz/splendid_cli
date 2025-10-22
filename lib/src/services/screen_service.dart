import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

import 'brick_loader.dart';

/// Service for managing Flutter screen generation operations.
///
/// This service encapsulates the core business logic for screen operations,
/// separating it from CLI-specific concerns like argument parsing and user
/// interaction. This design enables reuse across different interfaces
/// (CLI, MCP server, etc.).
class ScreenService {
  /// Creates a new instance of [ScreenService].
  ///
  /// This service is stateless and can be reused across multiple operations.
  /// All methods are safe to call concurrently from different isolates.
  const ScreenService();

  /// Adds a new screen to an existing Flutter project with MVC architecture.
  ///
  /// This method handles the complete screen generation workflow:
  /// 1. Validates the screen name and Flutter project
  /// 2. Checks for existing screen files and handles conflicts
  /// 3. Generates MVC files using Mason brick template
  /// 4. Returns result with success/failure information
  ///
  /// Parameters:
  /// * [request] - Configuration for the screen creation
  ///
  /// Returns:
  /// * [ScreenCreationResult] with success status and details
  ///
  /// Throws:
  /// * [ScreenServiceException] for various failure scenarios
  Future<ScreenCreationResult> createScreen(ScreenCreationRequest request) async {
    try {
      // Validate request
      _validateScreenRequest(request);

      // Check if we're in a Flutter project
      if (!_isFlutterProject(request.projectPath)) {
        throw const ScreenServiceException(
          'Not in a Flutter project directory.',
          ScreenServiceErrorType.notFlutterProject,
        );
      }

      // Determine screen path
      final String screenPath = path.join(
        request.projectPath,
        'lib',
        'screens',
        _toSnakeCase(request.screenName),
      );

      final Directory screenDirectory = Directory(screenPath);

      // Check if screen already exists and handle force flag
      if (screenDirectory.existsSync() && !request.force) {
        throw ScreenServiceException(
          'Screen ${request.screenName} already exists',
          ScreenServiceErrorType.screenExists,
        );
      }

      // Load and apply screen template
      final MasonGenerator generator = await _loadScreenBrick();
      final Map<String, dynamic> vars = {'name': request.screenName};

      await generator.generate(
        DirectoryGeneratorTarget(Directory(request.projectPath)),
        vars: vars,
        fileConflictResolution: request.force ? FileConflictResolution.overwrite : FileConflictResolution.skip,
      );

      // Generate list of created files
      final String snakeCaseName = _toSnakeCase(request.screenName);
      final List<String> createdFiles = [
        '$screenPath/${snakeCaseName}_route.dart',
        '$screenPath/${snakeCaseName}_controller.dart',
        '$screenPath/${snakeCaseName}_view.dart',
      ];

      return ScreenCreationResult.success(
        screenName: request.screenName,
        screenPath: screenPath,
        createdFiles: createdFiles,
      );
    } catch (e) {
      if (e is ScreenServiceException) {
        rethrow;
      }
      throw ScreenServiceException(
        'Failed to create screen: $e',
        ScreenServiceErrorType.unknown,
        cause: e,
      );
    }
  }

  /// Validates a screen creation request.
  void _validateScreenRequest(ScreenCreationRequest request) {
    if (!_isValidScreenName(request.screenName)) {
      throw ScreenServiceException(
        'Invalid screen name: ${request.screenName}. Must be a valid Dart identifier.',
        ScreenServiceErrorType.invalidScreenName,
      );
    }
  }

  /// Loads the Flutter screen Mason brick using the brick loader.
  ///
  /// This method uses the BrickLoader to find the brick locally (for development)
  /// or download it from GitHub (for global installations).
  Future<MasonGenerator> _loadScreenBrick() async {
    const BrickLoader brickLoader = BrickLoader();
    final String brickPath = await brickLoader.loadBrick('flutter_screen');

    final Brick brick = Brick.path(brickPath);
    return MasonGenerator.fromBrick(brick);
  }

  /// Validates that a screen name is a valid Dart identifier.
  bool _isValidScreenName(String name) {
    final RegExp validName = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

    const List<String> reservedWords = [
      'abstract',
      'as',
      'assert',
      'async',
      'await',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'default',
      'deferred',
      'do',
      'dynamic',
      'else',
      'enum',
      'export',
      'extends',
      'external',
      'factory',
      'false',
      'final',
      'finally',
      'for',
      'function',
      'get',
      'hide',
      'if',
      'implements',
      'import',
      'in',
      'interface',
      'is',
      'library',
      'mixin',
      'new',
      'null',
      'on',
      'operator',
      'part',
      'rethrow',
      'return',
      'set',
      'show',
      'static',
      'super',
      'switch',
      'sync',
      'this',
      'throw',
      'true',
      'try',
      'typedef',
      'var',
      'void',
      'while',
      'with',
      'yield',
    ];

    return validName.hasMatch(name) && !reservedWords.contains(name.toLowerCase());
  }

  /// Checks if a directory contains a Flutter project.
  bool _isFlutterProject(String projectPath) {
    final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final Directory libDirectory = Directory(path.join(projectPath, 'lib'));

    if (!pubspecFile.existsSync() || !libDirectory.existsSync()) {
      return false;
    }

    try {
      final String pubspecContent = pubspecFile.readAsStringSync();
      return pubspecContent.contains('flutter:') || pubspecContent.contains('flutter_test:');
    } catch (e) {
      return false;
    }
  }

  /// Converts a string to snake_case format.
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp('[A-Z]'), (Match match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp('^_'), '');
  }
}

/// Request configuration for screen creation.
class ScreenCreationRequest {
  /// Creates a screen creation request.
  const ScreenCreationRequest({
    required this.screenName,
    required this.projectPath,
    this.force = false,
  });

  /// Name of the screen to create.
  final String screenName;

  /// Path to the Flutter project.
  final String projectPath;

  /// Whether to overwrite existing screen files.
  final bool force;
}

/// Result of screen creation operation.
class ScreenCreationResult {
  /// Creates a screen creation result.
  const ScreenCreationResult({
    required this.success,
    required this.screenName,
    required this.screenPath,
    required this.createdFiles,
    this.error,
  });

  /// Creates a successful result.
  const ScreenCreationResult.success({
    required String screenName,
    required String screenPath,
    required List<String> createdFiles,
  }) : this(
         success: true,
         screenName: screenName,
         screenPath: screenPath,
         createdFiles: createdFiles,
       );

  /// Creates a failed result.
  const ScreenCreationResult.failure({
    required String screenName,
    required String error,
  }) : this(
         success: false,
         screenName: screenName,
         screenPath: '',
         createdFiles: const [],
         error: error,
       );

  /// Whether the operation was successful.
  final bool success;

  /// Name of the screen that was created.
  final String screenName;

  /// Path where the screen files were created.
  final String screenPath;

  /// List of files that were created.
  final List<String> createdFiles;

  /// Error message if operation failed.
  final String? error;
}

/// Exception thrown by screen service operations.
class ScreenServiceException implements Exception {
  /// Creates a screen service exception.
  const ScreenServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final ScreenServiceErrorType type;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'ScreenServiceException: $message';
}

/// Types of errors that can occur in screen service operations.
enum ScreenServiceErrorType {
  /// Invalid screen name provided.
  invalidScreenName,

  /// Directory is not a Flutter project.
  notFlutterProject,

  /// Screen already exists.
  screenExists,

  /// Unknown error occurred.
  unknown,
}
