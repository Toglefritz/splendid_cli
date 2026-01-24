import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

import 'brick_loader.dart';
import 'project_service/device_selection_info.dart';
import 'project_service/flutter_device.dart';
import 'project_service/project_creation_request.dart';
import 'project_service/project_creation_result.dart';
import 'project_service/project_service_error_type.dart';
import 'project_service/project_service_exception.dart';
import 'project_service/project_setup_request.dart';
import 'project_service/project_setup_result.dart';

/// Service for managing Flutter project creation and setup operations.
///
/// This service encapsulates the core business logic for project operations,
/// separating it from CLI-specific concerns like argument parsing and user
/// interaction. This design enables reuse across different interfaces (CLI, MCP
/// server, etc.).
class ProjectService {
  /// Brick loader for handling template loading and caching.
  final BrickLoader _brickLoader;

  /// Creates a new instance of [ProjectService].
  ///
  /// This service is stateless and can be reused across multiple operations.
  /// All methods are safe to call concurrently from different isolates.
  const ProjectService({BrickLoader? brickLoader}) : _brickLoader = brickLoader ?? const BrickLoader();

  /// Creates a new instance with default dependencies.
  const ProjectService.defaultInstance() : _brickLoader = const BrickLoader();

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
        request.organization,
      );

      // Remove default Flutter files that will be replaced
      await _removeDefaultFlutterFiles(targetPath);

      // Load and apply MVC template using BrickLoader
      final String brickPath = await _brickLoader.loadBrick('flutter_app');
      final Brick brick = Brick.path(brickPath);
      final MasonGenerator generator = await MasonGenerator.fromBrick(brick);
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
    } on BrickLoadException catch (e) {
      throw ProjectServiceException(
        'Failed to load project template: ${e.message}',
        ProjectServiceErrorType.templateLoadFailed,
        cause: e,
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
      DeviceSelectionInfo? deviceInfo;
      if (request.runApp) {
        deviceInfo = await _runFlutterCommand(
          ['run'],
          workingDirectory: request.projectPath,
          verbose: request.verbose,
          deviceId: request.deviceId,
        );
        executedCommands.add('flutter run');
      }

      return ProjectSetupResult.success(
        projectPath: request.projectPath,
        executedCommands: executedCommands,
        selectedDevice: deviceInfo?.selectedDevice,
        availableDevices: deviceInfo?.availableDevices,
        deviceSelectionReason: deviceInfo?.selectionReason,
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

    // Validate organization format
    if (!_isValidOrganization(request.organization)) {
      throw ProjectServiceException(
        'Invalid organization: ${request.organization}. Must be in reverse domain name notation (e.g., com.example).',
        ProjectServiceErrorType.invalidOrganization,
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
    String organization,
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
      '--org=$organization',
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

  /// Runs a Flutter command with the specified arguments.
  ///
  /// Returns device selection information if this was a flutter run command
  /// with device selection.
  Future<DeviceSelectionInfo?> _runFlutterCommand(
    List<String> args, {
    required String workingDirectory,
    bool verbose = false,
    String? deviceId,
  }) async {
    // Special handling for 'flutter run' command to handle multiple devices
    if (args.isNotEmpty && args.first == 'run') {
      return _runFlutterRunCommand(
        args,
        workingDirectory: workingDirectory,
        verbose: verbose,
        deviceId: deviceId,
      );
    }

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

    return null; // No device selection info for non-run commands
  }

  /// Runs the Flutter run command with intelligent device selection.
  ///
  /// This method handles the case where multiple devices are available by:
  /// 1. Using the specified device ID if provided
  /// 2. Otherwise, checking available devices and selecting the best one
  /// 3. Running flutter run with the selected device
  ///
  /// Device selection priority (when no device specified):
  /// 1. Desktop devices (Windows, macOS, Linux)
  /// 2. Web browsers (Chrome)
  /// 3. Mobile devices (Android, iOS)
  /// 4. Other devices
  ///
  /// Returns device selection information for user feedback.
  Future<DeviceSelectionInfo?> _runFlutterRunCommand(
    List<String> args, {
    required String workingDirectory,
    bool verbose = false,
    String? deviceId,
  }) async {
    try {
      // Get list of available devices first
      final List<FlutterDevice> devices = await _getAvailableDevices(workingDirectory);

      if (devices.isEmpty) {
        throw const ProjectServiceException(
          'No devices available. Please connect a device or start an emulator.',
          ProjectServiceErrorType.flutterCommandFailed,
        );
      }

      List<String> runArgs = [...args];
      FlutterDevice selectedDevice;
      String selectionReason;

      // Determine device selection logic
      if (deviceId != null) {
        // Device ID was specified, validate it exists
        final FlutterDevice? specifiedDevice = devices.where((d) => d.id == deviceId).firstOrNull;

        if (specifiedDevice == null) {
          throw ProjectServiceException(
            'Specified device "$deviceId" not found. Available devices: ${devices.map((d) => d.id).join(', ')}',
            ProjectServiceErrorType.flutterCommandFailed,
          );
        }

        selectedDevice = specifiedDevice;
        selectionReason = 'User specified';
        runArgs = [...args, '-d', deviceId];
      } else if (devices.length == 1) {
        // Only one device available
        selectedDevice = devices.first;
        selectionReason = 'Only device available';
        // Don't add -d flag for single device
      } else {
        // Multiple devices available - select the best one
        selectedDevice = _selectBestDevice(devices);
        selectionReason = _getSelectionReason(selectedDevice, devices);
        runArgs = [...args, '-d', selectedDevice.id];
      }

      final ProcessResult result = await Process.run(
        'flutter',
        runArgs,
        workingDirectory: workingDirectory,
      );

      if (result.exitCode != 0) {
        throw ProjectServiceException(
          'Flutter run failed on device ${selectedDevice.name}: ${result.stderr}',
          ProjectServiceErrorType.flutterCommandFailed,
        );
      }

      // Return device selection information
      return DeviceSelectionInfo(
        selectedDevice: selectedDevice,
        availableDevices: devices,
        selectionReason: selectionReason,
      );
    } catch (e) {
      if (e is ProjectServiceException) {
        rethrow;
      }
      throw ProjectServiceException(
        'Failed to run Flutter app: $e',
        ProjectServiceErrorType.flutterCommandFailed,
        cause: e,
      );
    }
  }

  /// Determines which device would be selected for flutter run without actually
  /// running.
  ///
  /// This method performs device detection and selection logic to provide user
  /// feedback before actually executing the flutter run command.
  Future<DeviceSelectionInfo> getDeviceSelection(
    String workingDirectory, {
    String? deviceId,
  }) async {
    // Get list of available devices
    final List<FlutterDevice> devices = await _getAvailableDevices(workingDirectory);

    if (devices.isEmpty) {
      throw const ProjectServiceException(
        'No devices available. Please connect a device or start an emulator.',
        ProjectServiceErrorType.flutterCommandFailed,
      );
    }

    FlutterDevice selectedDevice;
    String selectionReason;

    // Determine device selection logic (same as in _runFlutterRunCommand)
    if (deviceId != null) {
      // Device ID was specified, validate it exists
      final FlutterDevice? specifiedDevice = devices.where((d) => d.id == deviceId).firstOrNull;

      if (specifiedDevice == null) {
        throw ProjectServiceException(
          'Specified device "$deviceId" not found. Available devices: ${devices.map((d) => d.id).join(', ')}',
          ProjectServiceErrorType.flutterCommandFailed,
        );
      }

      selectedDevice = specifiedDevice;
      selectionReason = 'User specified';
    } else if (devices.length == 1) {
      // Only one device available
      selectedDevice = devices.first;
      selectionReason = 'Only device available';
    } else {
      // Multiple devices available - select the best one
      selectedDevice = _selectBestDevice(devices);
      selectionReason = _getSelectionReason(selectedDevice, devices);
    }

    return DeviceSelectionInfo(
      selectedDevice: selectedDevice,
      availableDevices: devices,
      selectionReason: selectionReason,
    );
  }

  /// Gets the list of available Flutter devices.
  Future<List<FlutterDevice>> _getAvailableDevices(String workingDirectory) async {
    final ProcessResult result = await Process.run(
      'flutter',
      ['devices', '--machine'],
      workingDirectory: workingDirectory,
    );

    if (result.exitCode != 0) {
      throw ProjectServiceException(
        'Failed to get device list: ${result.stderr}',
        ProjectServiceErrorType.flutterCommandFailed,
      );
    }

    try {
      final String output = result.stdout as String;
      final List<dynamic> deviceList = jsonDecode(output) as List<dynamic>;

      return deviceList.map((dynamic device) => FlutterDevice.fromJson(device as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ProjectServiceException(
        'Failed to parse device list: $e',
        ProjectServiceErrorType.flutterCommandFailed,
        cause: e,
      );
    }
  }

  /// Selects the best device from available devices based on priority.
  ///
  /// Priority order:
  /// 1. Desktop devices (better for development)
  /// 2. Web browsers (universal compatibility)
  /// 3. Mobile devices (Android/iOS)
  /// 4. Other devices
  FlutterDevice _selectBestDevice(List<FlutterDevice> devices) {
    // Priority 1: Desktop devices
    final FlutterDevice? desktopDevice = devices.where(_isDesktopDevice).firstOrNull;
    if (desktopDevice != null) return desktopDevice;

    // Priority 2: Web browsers
    final FlutterDevice? webDevice = devices.where(_isWebDevice).firstOrNull;
    if (webDevice != null) return webDevice;

    // Priority 3: Mobile devices
    final FlutterDevice? mobileDevice = devices.where(_isMobileDevice).firstOrNull;
    if (mobileDevice != null) return mobileDevice;

    // Fallback: Return first available device
    return devices.first;
  }

  /// Checks if a device is a desktop device. Checks if a device is a desktop
  /// device.
  bool _isDesktopDevice(FlutterDevice device) => device.isDesktop;

  /// Checks if a device is a web device.
  bool _isWebDevice(FlutterDevice device) => device.isWeb;

  /// Checks if a device is a mobile device.
  bool _isMobileDevice(FlutterDevice device) => device.isMobile;

  /// Gets a human-readable explanation for why a device was selected.
  String _getSelectionReason(FlutterDevice selectedDevice, List<FlutterDevice> availableDevices) {
    if (selectedDevice.isDesktop) {
      return 'Automatically selected (desktop preferred for development)';
    } else if (selectedDevice.isWeb) {
      final bool hasDesktop = availableDevices.any((d) => d.isDesktop);
      if (hasDesktop) {
        return 'Automatically selected (web device)';
      } else {
        return 'Automatically selected (web preferred over mobile)';
      }
    } else if (selectedDevice.isMobile) {
      return 'Automatically selected (mobile device)';
    } else {
      return 'Automatically selected';
    }
  }

  /// Validates that a project name follows Dart package naming conventions.
  bool _isValidProjectName(String name) {
    final RegExp validName = RegExp(r'^[a-z][a-z0-9_]*$');
    return validName.hasMatch(name) && !name.startsWith('_');
  }

  /// Validates that an organization follows reverse domain name notation.
  ///
  /// Valid organization formats:
  /// * com.example
  /// * org.mycompany
  /// * io.github.username
  /// * net.domain.subdomain
  ///
  /// The organization must:
  /// * Contain at least one dot
  /// * Have segments separated by dots
  /// * Each segment must start with a letter
  /// * Each segment can contain letters, numbers, and hyphens
  /// * Each segment must end with a letter or number
  bool _isValidOrganization(String organization) {
    if (organization.isEmpty || !organization.contains('.')) {
      return false;
    }

    final List<String> segments = organization.split('.');

    // Must have at least 2 segments (e.g., com.example)
    if (segments.length < 2) {
      return false;
    }

    // Validate each segment
    for (final String segment in segments) {
      if (segment.isEmpty) {
        return false;
      }

      // Each segment must match domain name rules:
      // - Start with lowercase letter
      // - Contain only lowercase letters, numbers, and hyphens
      // - End with lowercase letter or number
      // - Single letter segments are allowed
      final RegExp validSegment = RegExp(r'^[a-z]([a-z0-9-]*[a-z0-9])?$');
      if (!validSegment.hasMatch(segment)) {
        return false;
      }
    }

    return true;
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
