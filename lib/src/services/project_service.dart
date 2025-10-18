import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Service for managing Flutter project creation and setup operations.
///
/// This service encapsulates the core business logic for project operations,
/// separating it from CLI-specific concerns like argument parsing and user
/// interaction. This design enables reuse across different interfaces
/// (CLI, MCP server, etc.).
class ProjectService {
  /// Creates a new instance of [ProjectService].
  ///
  /// This service is stateless and can be reused across multiple operations.
  /// All methods are safe to call concurrently from different isolates.
  const ProjectService();

  /// Creates a new Flutter project with MVC architecture.
  ///
  /// This method handles the complete project creation workflow:
  /// 1. Creates base Flutter project with specified platforms
  /// 2. Removes default Flutter files that conflict with MVC template
  /// 3. Applies MVC architecture template using Mason brick
  /// 4. Returns result with success/failure information
  ///
  /// Parameters:
  /// * [request] - Configuration for the project creation
  ///
  /// Returns:
  /// * [ProjectCreationResult] with success status and details
  ///
  /// Throws:
  /// * [ProjectServiceException] for various failure scenarios
  Future<ProjectCreationResult> createProject(ProjectCreationRequest request) async {
    try {
      // Validate request
      _validateProjectRequest(request);

      // Determine target path
      final String targetPath = request.outputDirectory != null
          ? path.join(request.outputDirectory!, request.projectName)
          : request.projectName;

      final Directory targetDirectory = Directory(targetPath);

      // Check if directory exists and handle force flag
      if (targetDirectory.existsSync() && !request.force) {
        throw const ProjectServiceException(
          'Directory already exists. Use force flag to overwrite.',
          ProjectServiceErrorType.directoryExists,
        );
      }

      // Create Flutter project with specified platforms
      await _createFlutterProject(
        request.projectName,
        targetPath,
        request.platforms,
      );

      // Remove default Flutter files that will be replaced
      await _removeDefaultFlutterFiles(targetPath);

      // Load and apply MVC template
      final MasonGenerator generator = await _loadFlutterAppBrick();
      final Map<String, dynamic> vars = {'name': request.projectName};

      await generator.generate(
        DirectoryGeneratorTarget(Directory(targetPath)),
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      return ProjectCreationResult.success(
        projectName: request.projectName,
        targetPath: targetPath,
        platforms: request.platforms,
      );
    } catch (e) {
      if (e is ProjectServiceException) {
        rethrow;
      }
      throw ProjectServiceException(
        'Failed to create project: $e',
        ProjectServiceErrorType.unknown,
        cause: e,
      );
    }
  }

  /// Sets up a Flutter project by running necessary post-creation commands.
  ///
  /// This method handles the setup workflow:
  /// 1. Validates that the target is a Flutter project
  /// 2. Runs flutter pub get to install dependencies
  /// 3. Runs flutter gen-l10n to generate localization files
  /// 4. Optionally runs the application
  ///
  /// Parameters:
  /// * [request] - Configuration for the project setup
  ///
  /// Returns:
  /// * [ProjectSetupResult] with success status and details
  Future<ProjectSetupResult> setupProject(ProjectSetupRequest request) async {
    try {
      // Validate that target is a Flutter project
      if (!_isFlutterProject(request.projectPath)) {
        throw ProjectServiceException(
          'Directory ${request.projectPath} is not a Flutter project',
          ProjectServiceErrorType.notFlutterProject,
        );
      }

      final List<String> executedCommands = [];

      // Run flutter pub get
      await _runFlutterCommand(
        ['pub', 'get'],
        workingDirectory: request.projectPath,
        verbose: request.verbose,
      );
      executedCommands.add('flutter pub get');

      // Run flutter gen-l10n
      await _runFlutterCommand(
        ['gen-l10n'],
        workingDirectory: request.projectPath,
        verbose: request.verbose,
      );
      executedCommands.add('flutter gen-l10n');

      // Optionally run the application
      if (request.runApp) {
        await _runFlutterCommand(
          ['run'],
          workingDirectory: request.projectPath,
          verbose: request.verbose,
        );
        executedCommands.add('flutter run');
      }

      return ProjectSetupResult.success(
        projectPath: request.projectPath,
        executedCommands: executedCommands,
      );
    } catch (e) {
      if (e is ProjectServiceException) {
        rethrow;
      }
      throw ProjectServiceException(
        'Failed to setup project: $e',
        ProjectServiceErrorType.unknown,
        cause: e,
      );
    }
  }

  /// Validates a project creation request.
  void _validateProjectRequest(ProjectCreationRequest request) {
    if (!_isValidProjectName(request.projectName)) {
      throw ProjectServiceException(
        'Invalid project name: ${request.projectName}. Must be a valid Dart package name.',
        ProjectServiceErrorType.invalidProjectName,
      );
    }

    // Validate platforms
    const List<String> validPlatforms = ['android', 'ios', 'web', 'windows', 'macos', 'linux'];

    final List<String> requestedPlatforms = request.platforms.split(',').map((p) => p.trim().toLowerCase()).toList();

    final List<String> invalidPlatforms = requestedPlatforms.where((p) => !validPlatforms.contains(p)).toList();

    if (invalidPlatforms.isNotEmpty) {
      throw ProjectServiceException(
        'Invalid platforms: ${invalidPlatforms.join(', ')}. Valid platforms: ${validPlatforms.join(', ')}',
        ProjectServiceErrorType.invalidPlatforms,
      );
    }
  }

  /// Creates a Flutter project using the Flutter CLI.
  Future<void> _createFlutterProject(
    String projectName,
    String targetPath,
    String platforms,
  ) async {
    const List<String> validPlatforms = ['android', 'ios', 'web', 'windows', 'macos', 'linux'];

    final List<String> enabledPlatforms = platforms
        .split(',')
        .map((platform) => platform.trim().toLowerCase())
        .where((platform) => validPlatforms.contains(platform))
        .toList();

    if (enabledPlatforms.isEmpty) {
      throw const ProjectServiceException(
        'No valid platforms specified',
        ProjectServiceErrorType.invalidPlatforms,
      );
    }

    final List<String> createArgs = [
      'create',
      '--platforms=${enabledPlatforms.join(',')}',
      projectName,
    ];

    final ProcessResult result = await Process.run(
      'flutter',
      createArgs,
      workingDirectory: path.dirname(targetPath),
    );

    if (result.exitCode != 0) {
      throw ProjectServiceException(
        'Flutter create failed: ${result.stderr}',
        ProjectServiceErrorType.flutterCommandFailed,
      );
    }
  }

  /// Removes default Flutter files that conflict with MVC template.
  Future<void> _removeDefaultFlutterFiles(String targetPath) async {
    final List<String> filesToRemove = [
      'lib/main.dart',
      'test/widget_test.dart',
    ];

    for (final String filePath in filesToRemove) {
      final File file = File(path.join(targetPath, filePath));
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (e) {
          // Continue with other files even if one fails
        }
      }
    }
  }

  /// Loads the Flutter app Mason brick.
  Future<MasonGenerator> _loadFlutterAppBrick() async {
    final String brickPath = path.join(
      path.dirname(Platform.script.path),
      '..',
      'bricks',
      'flutter_app',
    );

    final Brick brick = Brick.path(brickPath);
    return MasonGenerator.fromBrick(brick);
  }

  /// Runs a Flutter command with the specified arguments.
  Future<void> _runFlutterCommand(
    List<String> args, {
    required String workingDirectory,
    bool verbose = false,
  }) async {
    final ProcessResult result = await Process.run(
      'flutter',
      args,
      workingDirectory: workingDirectory,
    );

    if (result.exitCode != 0) {
      throw ProjectServiceException(
        'Flutter command failed: flutter ${args.join(' ')}\n${result.stderr}',
        ProjectServiceErrorType.flutterCommandFailed,
      );
    }
  }

  /// Validates that a project name follows Dart package naming conventions.
  bool _isValidProjectName(String name) {
    final RegExp validName = RegExp(r'^[a-z][a-z0-9_]*$');
    return validName.hasMatch(name) && !name.startsWith('_');
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
}

/// Request configuration for project creation.
class ProjectCreationRequest {
  /// Creates a project creation request.
  const ProjectCreationRequest({
    required this.projectName,
    this.outputDirectory,
    this.platforms = 'android,ios,web,windows,macos,linux',
    this.force = false,
  });

  /// Name of the project to create.
  final String projectName;

  /// Optional custom output directory.
  final String? outputDirectory;

  /// Comma-separated list of platforms to enable.
  final String platforms;

  /// Whether to overwrite existing directories.
  final bool force;
}

/// Request configuration for project setup.
class ProjectSetupRequest {
  /// Creates a project setup request.
  const ProjectSetupRequest({
    required this.projectPath,
    this.runApp = true,
    this.verbose = false,
  });

  /// Path to the Flutter project to setup.
  final String projectPath;

  /// Whether to run the app after setup.
  final bool runApp;

  /// Whether to enable verbose output.
  final bool verbose;
}

/// Result of project creation operation.
class ProjectCreationResult {
  /// Creates a project creation result.
  const ProjectCreationResult({
    required this.success,
    required this.projectName,
    required this.targetPath,
    required this.platforms,
    this.error,
  });

  /// Creates a successful result.
  const ProjectCreationResult.success({
    required String projectName,
    required String targetPath,
    required String platforms,
  }) : this(
         success: true,
         projectName: projectName,
         targetPath: targetPath,
         platforms: platforms,
       );

  /// Creates a failed result.
  const ProjectCreationResult.failure({
    required String projectName,
    required String targetPath,
    required String platforms,
    required String error,
  }) : this(
         success: false,
         projectName: projectName,
         targetPath: targetPath,
         platforms: platforms,
         error: error,
       );

  /// Whether the operation was successful.
  final bool success;

  /// Name of the project.
  final String projectName;

  /// Path where the project was created.
  final String targetPath;

  /// Platforms that were enabled.
  final String platforms;

  /// Error message if operation failed.
  final String? error;
}

/// Result of project setup operation.
class ProjectSetupResult {
  /// Creates a project setup result.
  const ProjectSetupResult({
    required this.success,
    required this.projectPath,
    required this.executedCommands,
    this.error,
  });

  /// Creates a successful result.
  const ProjectSetupResult.success({
    required String projectPath,
    required List<String> executedCommands,
  }) : this(
         success: true,
         projectPath: projectPath,
         executedCommands: executedCommands,
       );

  /// Creates a failed result.
  const ProjectSetupResult.failure({
    required String projectPath,
    required String error,
  }) : this(
         success: false,
         projectPath: projectPath,
         executedCommands: const [],
         error: error,
       );

  /// Whether the operation was successful.
  final bool success;

  /// Path to the project that was setup.
  final String projectPath;

  /// List of commands that were executed.
  final List<String> executedCommands;

  /// Error message if operation failed.
  final String? error;
}

/// Exception thrown by project service operations.
class ProjectServiceException implements Exception {
  /// Creates a project service exception.
  const ProjectServiceException(
    this.message,
    this.type, {
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// Type of error that occurred.
  final ProjectServiceErrorType type;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'ProjectServiceException: $message';
}

/// Types of errors that can occur in project service operations.
enum ProjectServiceErrorType {
  /// Invalid project name provided.
  invalidProjectName,

  /// Invalid platforms specified.
  invalidPlatforms,

  /// Target directory already exists.
  directoryExists,

  /// Directory is not a Flutter project.
  notFlutterProject,

  /// Flutter command execution failed.
  flutterCommandFailed,

  /// Unknown error occurred.
  unknown,
}
