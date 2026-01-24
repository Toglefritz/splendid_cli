import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../services/cli_service.dart';
import 'dashboard_route.dart';
import 'dashboard_view.dart';

/// Controller for the main dashboard screen.
///
/// This controller manages the state and business logic for the dashboard,
/// including project management, CLI command execution, and user interactions.
/// It provides a bridge between the UI and the underlying CLI functionality.
///
/// Key responsibilities:
/// * Managing current project path and Flutter project detection
/// * Executing CLI commands and handling their output
/// * Managing loading states and error handling
/// * Coordinating between different dashboard features
/// * Handling file system operations and project navigation
class DashboardController extends State<DashboardRoute> {
  /// Service for executing CLI commands.
  final CliService _cliService = const CliService();

  /// The currently selected project directory path.
  ///
  /// This path is used as the working directory for CLI operations and
  /// determines which project is being managed in the dashboard.
  String? _currentProjectPath;

  /// Whether the current directory contains a Flutter project.
  ///
  /// Determined by checking for the presence of pubspec.yaml with Flutter
  /// dependencies. Used to enable/disable Flutter-specific features.
  bool _isFlutterProject = false;

  /// Whether a CLI operation is currently in progress.
  ///
  /// Used to show loading indicators and prevent concurrent operations that
  /// could interfere with each other.
  bool _isLoading = false;

  /// Current error message from the most recent failed operation.
  ///
  /// Null when no error is present. Displayed to users for troubleshooting and
  /// automatically cleared when successful operations complete.
  String? _errorMessage;

  /// Output from the most recent CLI command execution.
  ///
  /// Contains both stdout and stderr from CLI operations, formatted for display
  /// in the dashboard's output panel.
  String _commandOutput = '';

  /// Whether the output panel is currently visible.
  ///
  /// Controls the visibility of the expandable output panel that shows CLI
  /// command results and error messages.
  bool _showOutput = false;

  /// Getter for the current project path.
  String? get currentProjectPath => _currentProjectPath;

  /// Getter for Flutter project detection status.
  bool get isFlutterProject => _isFlutterProject;

  /// Getter for loading state.
  bool get isLoading => _isLoading;

  /// Getter for current error message.
  String? get errorMessage => _errorMessage;

  /// Getter for command output.
  String get commandOutput => _commandOutput;

  /// Getter for output panel visibility.
  bool get showOutput => _showOutput;

  @override
  void initState() {
    super.initState();
    _initializeProjectPath();
  }

  /// Initializes the project path from environment or current directory.
  ///
  /// Checks for a PROJECT_PATH environment variable (set by the CLI when
  /// launching the GUI) and falls back to the current working directory. Also
  /// performs initial Flutter project detection.
  void _initializeProjectPath() {
    final String? envProjectPath = Platform.environment['PROJECT_PATH'];
    final String initialPath = envProjectPath ?? Directory.current.path;

    _setProjectPath(initialPath);
  }

  /// Sets the current project path and updates Flutter project detection.
  ///
  /// This method updates the project path, checks if it contains a Flutter
  /// project, and triggers a UI rebuild to reflect the changes.
  ///
  /// Parameters:
  /// * [projectPath] - The new project directory path to set
  void _setProjectPath(String projectPath) {
    setState(() {
      _currentProjectPath = projectPath;
      _isFlutterProject = _checkIsFlutterProject(projectPath);
      _clearError();
    });
  }

  /// Checks if a directory contains a Flutter project.
  ///
  /// Determines Flutter project status by looking for pubspec.yaml with Flutter
  /// SDK dependency. This is used to enable Flutter-specific features in the
  /// dashboard.
  ///
  /// Parameters:
  /// * [projectPath] - The directory path to check
  ///
  /// Returns:
  /// * `true` if the directory contains a Flutter project
  /// * `false` if it's not a Flutter project or path is invalid
  bool _checkIsFlutterProject(String projectPath) {
    try {
      final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) return false;

      final String content = pubspecFile.readAsStringSync();
      return content.contains('flutter:') || content.contains('sdk: flutter');
    } catch (error) {
      return false;
    }
  }

  /// Opens a directory picker dialog for selecting a project folder.
  ///
  /// Allows users to browse and select a different project directory to work
  /// with in the dashboard. Updates the current project path if a valid
  /// directory is selected.
  ///
  /// On macOS, this method handles security-scoped access to ensure the app
  /// maintains write permissions to the selected directory for file operations
  /// like creating screens and generating tests.
  Future<void> selectProjectFolder() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Folder',
        initialDirectory: _currentProjectPath,
      );

      if (selectedDirectory != null) {
        // On macOS, we need to verify we have write access to the selected
        // directory
        if (Platform.isMacOS) {
          final bool hasWriteAccess = await _verifyWriteAccess(selectedDirectory);
          if (!hasWriteAccess) {
            _setError(
              'No write permission to selected folder. Please ensure the folder is writable or try selecting a different location.',
            );
            return;
          }
        }

        _setProjectPath(selectedDirectory);
      }
    } catch (error) {
      _setError('Failed to select project folder: $error');
    }
  }

  /// Creates a new Flutter project with the specified parameters.
  ///
  /// Executes the CLI create command with user-provided project name, output
  /// directory, and platform selections. Shows progress feedback and handles
  /// success/error states appropriately.
  ///
  /// Parameters:
  /// * [projectName] - Name for the new Flutter project
  /// * [outputDirectory] - Directory where the project should be created (empty uses current project directory)
  /// * [platforms] - Comma-separated list of target platforms
  /// * [force] - Whether to overwrite existing directories
  Future<void> createProject({
    required String projectName,
    required String outputDirectory,
    required String platforms,
    required bool force,
  }) async {
    await _executeCommand(
      'Creating Flutter project...',
      () => _cliService.createProject(
        projectName: projectName,
        outputDirectory: outputDirectory,
        platforms: platforms,
        force: force,
        workingDirectory: outputDirectory.isEmpty ? _currentProjectPath : null,
      ),
    );
  }

  /// Adds a new screen to the current Flutter project.
  ///
  /// Executes the CLI screen command to generate MVC architecture files for a
  /// new screen. Requires a valid Flutter project to be selected and write
  /// permissions to the project directory.
  ///
  /// Parameters:
  /// * [screenName] - Name for the new screen
  /// * [force] - Whether to overwrite existing screen files
  Future<void> addScreen({
    required String screenName,
    required bool force,
  }) async {
    if (_currentProjectPath == null) {
      _setError('No project selected. Please select a project folder first.');
      return;
    }

    // Verify write access before attempting to create files
    if (Platform.isMacOS) {
      final bool hasWriteAccess = await _verifyWriteAccess(_currentProjectPath!);
      if (!hasWriteAccess) {
        _setError(
          'No write permission to project folder. Please select the project folder again to grant access.',
        );
        return;
      }
    }

    await _executeCommand(
      'Adding screen to project...',
      () => _cliService.addScreen(
        screenName: screenName,
        projectPath: _currentProjectPath!,
        force: force,
      ),
    );
  }

  /// Generates a test file for the specified Dart file.
  ///
  /// Executes the CLI test generation command to create appropriate test
  /// templates for widgets or classes. Handles both automatic type detection
  /// and explicit type specification.
  ///
  /// Parameters:
  /// * [targetFile] - Path to the Dart file to generate tests for
  /// * [testType] - Type of test to generate ('auto', 'widget', 'class')
  /// * [force] - Whether to overwrite existing test files
  Future<void> generateTest({
    required String targetFile,
    required String testType,
    required bool force,
  }) async {
    if (_currentProjectPath == null) {
      _setError('No project selected. Please select a project folder first.');
      return;
    }

    await _executeCommand(
      'Generating test file...',
      () => _cliService.generateTest(
        targetFile: targetFile,
        projectPath: _currentProjectPath!,
        testType: testType,
        force: force,
      ),
    );
  }

  /// Runs Flutter setup commands for the current project.
  ///
  /// Executes the CLI setup command which typically includes pub get, code
  /// generation, and other project initialization tasks.
  Future<void> setupProject() async {
    if (_currentProjectPath == null) {
      _setError('No project selected. Please select a project folder first.');
      return;
    }

    await _executeCommand(
      'Setting up project...',
      () => _cliService.setupProject(projectPath: _currentProjectPath!),
    );
  }

  /// Formats Dartdoc comments in the current project.
  ///
  /// Executes the CLI format-dartdoc command to reformat and rewrap Dartdoc
  /// comments to the specified line length across all Dart files in the
  /// project.
  Future<void> formatProject() async {
    if (_currentProjectPath == null) {
      _setError('No project selected. Please select a project folder first.');
      return;
    }

    await _executeCommand(
      'Formatting Dartdoc comments...',
      () => _cliService.formatProject(projectPath: _currentProjectPath!),
    );
  }

  /// Toggles the visibility of the command output panel.
  ///
  /// Shows or hides the expandable panel that displays CLI command output and
  /// error messages for user review and debugging.
  void toggleOutputPanel() {
    setState(() {
      _showOutput = !_showOutput;
    });
  }

  /// Clears the current error message and updates the UI.
  ///
  /// Removes any displayed error message and triggers a rebuild to hide error
  /// indicators in the interface.
  void clearError() {
    setState(_clearError);
  }

  /// Internal method to clear error state without triggering rebuild.
  void _clearError() {
    _errorMessage = null;
  }

  /// Verifies that the app has write access to the specified directory.
  ///
  /// This method attempts to create a temporary file in the directory to test
  /// write permissions. This is particularly important on macOS where sandboxed
  /// apps need explicit permission to write to user-selected directories.
  ///
  /// Parameters:
  /// * [directoryPath] - The directory path to test for write access
  ///
  /// Returns:
  /// * `true` if the app can write to the directory
  /// * `false` if write access is denied or the directory doesn't exist
  Future<bool> _verifyWriteAccess(String directoryPath) async {
    try {
      final Directory directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        return false;
      }

      // Try to create a temporary file to test write permissions
      final String tempFileName = '.splendid_write_test_${DateTime.now().millisecondsSinceEpoch}';
      final File tempFile = File(path.join(directoryPath, tempFileName));

      await tempFile.writeAsString('test');
      await tempFile.delete();

      return true;
    } catch (error) {
      return false;
    }
  }

  /// Sets an error message and updates the UI.
  ///
  /// Displays the provided error message to the user and triggers a rebuild to
  /// show error indicators in the interface.
  ///
  /// Parameters:
  /// * [message] - The error message to display
  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  /// Executes a CLI command with loading state management.
  ///
  /// This method provides a consistent pattern for executing CLI operations
  /// with proper loading indicators, error handling, and output capture. It
  /// manages the loading state and updates the UI appropriately.
  ///
  /// Parameters:
  /// * [loadingMessage] - Message to display while command is executing
  /// * [command] - Function that returns the CLI command execution future
  Future<void> _executeCommand(
    String loadingMessage,
    Future<CliResult> Function() command,
  ) async {
    setState(() {
      _isLoading = true;
      _clearError();
      _commandOutput = loadingMessage;
      _showOutput = true;
    });

    try {
      final CliResult result = await command();

      setState(() {
        _isLoading = false;
        _commandOutput = result.output;

        if (!result.success) {
          _errorMessage = result.error ?? 'Command failed';
        }
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to execute command: $error';
        _commandOutput = 'Error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => DashboardView(this);
}
