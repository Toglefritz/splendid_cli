import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// Command-line interface for performing deep cleaning of Flutter projects.
///
/// This command provides a comprehensive cleaning workflow that goes beyond the standard `flutter clean`
/// by also refreshing dependencies and regenerating localization files. It's particularly useful when
/// dealing with build issues, dependency conflicts, or after major Flutter SDK updates.
///
/// The deep clean process executes the following commands in sequence:
/// 1. `flutter clean` - Removes build artifacts and cached files
/// 2. `flutter pub get` - Refreshes all project dependencies
/// 3. `flutter gen-l10n` - Regenerates localization files
///
/// This comprehensive approach resolves most common Flutter development issues including:
/// * Stale build artifacts causing compilation errors
/// * Dependency version conflicts or corruption
/// * Outdated localization files after string changes
/// * General build system inconsistencies
///
/// Key Features:
/// * Automatic Flutter project detection and validation
/// * Sequential execution with proper error handling
/// * Detailed progress reporting for each step
/// * Comprehensive error messages with troubleshooting guidance
/// * Support for both current directory and specified project paths
///
/// Usage Examples:
/// ```bash
/// # Deep clean current directory (if it's a Flutter project)
/// splendid_cli deep_clean
///
/// # Deep clean a specific Flutter project
/// splendid_cli deep_clean /path/to/flutter/project
///
/// # Using the short alias
/// splendid_cli dc
/// ```
///
/// Exit Codes:
/// * `0` - Success: All cleaning steps completed successfully
/// * `1` - General error: Flutter command execution failed
/// * `64` - Usage error: Invalid arguments or not a Flutter project (EX_USAGE)
///
/// Performance: Execution time varies based on project size and network speed for dependency downloads.
/// Typical completion time is 30-60 seconds for most projects.
///
/// Prerequisites: Requires Flutter SDK to be installed and available in PATH. The target directory
/// must contain a valid Flutter project with pubspec.yaml file.
class DeepCleanCommand extends Command<int> {
  /// Creates a new instance of [DeepCleanCommand] with configured argument parser.
  ///
  /// The command accepts an optional positional argument for the project path.
  /// If no path is provided, the current working directory is used.
  DeepCleanCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show detailed output from Flutter commands.',
      negatable: false,
    );
  }

  /// Brief description of the command's purpose for help text.
  @override
  String get description => 'Perform deep cleaning: flutter clean, pub get, and gen-l10n.';

  /// The command name used for CLI invocation.
  @override
  String get name => 'deep_clean';

  /// Alternative shorter names for the command.
  @override
  List<String> get aliases => ['dc'];

  /// Usage pattern displayed in help text and error messages.
  @override
  String get invocation => 'splendid_cli deep_clean [project_path]';

  /// Executes the deep clean command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete deep cleaning workflow:
  /// 1. Validates that the target directory contains a Flutter project
  /// 2. Executes flutter clean to remove build artifacts
  /// 3. Executes flutter pub get to refresh dependencies
  /// 4. Executes flutter gen-l10n to regenerate localization files
  /// 5. Provides comprehensive progress reporting and error handling
  ///
  /// The method handles various error conditions gracefully:
  /// * Invalid or missing Flutter projects
  /// * Flutter SDK not available in PATH
  /// * Network connectivity issues during pub get
  /// * Missing localization configuration for gen-l10n
  /// * File system permission errors
  ///
  /// Progress Reporting:
  /// * Clear indication of current step being executed
  /// * Success confirmation for each completed step
  /// * Detailed error messages with troubleshooting guidance
  /// * Final summary of all completed operations
  ///
  /// Returns:
  /// * `0` on successful completion of all cleaning steps
  /// * `1` for Flutter command execution failures
  /// * `64` for usage errors (invalid project, missing Flutter SDK, etc.)
  @override
  Future<int> run() async {
    final Logger logger = Logger();

    /// The target project path to clean.
    ///
    /// Defaults to current working directory if no path is provided as argument.
    /// Must point to a valid Flutter project directory containing pubspec.yaml.
    final String projectPath = argResults!.rest.isNotEmpty ? argResults!.rest.first : Directory.current.path;

    /// Whether to show verbose output from Flutter commands.
    ///
    /// When enabled, displays detailed output from each Flutter command execution
    /// for debugging and troubleshooting purposes.
    final bool verbose = argResults!['verbose'] as bool;

    try {
      // Validate that target is a Flutter project
      if (!_isFlutterProject(projectPath)) {
        logger
          ..err('Directory "$projectPath" is not a Flutter project.')
          ..info('')
          ..info('A Flutter project must contain:')
          ..info('  • pubspec.yaml file')
          ..info('  • lib/ directory')
          ..info('  • Flutter dependencies in pubspec.yaml')
          ..info('')
          ..info('Usage: $invocation');
        return 64;
      }

      // Display operation summary
      logger
        ..info('🧹 Starting deep clean for Flutter project...')
        ..info('Project: $projectPath')
        ..info('');

      /// List of commands that will be executed during the deep clean process.
      ///
      /// Each command is executed sequentially, and the process stops if any command fails.
      final List<_CleanStep> cleanSteps = [
        const _CleanStep(
          name: 'Flutter Clean',
          description: 'Removing build artifacts and cached files',
          command: ['clean'],
          icon: '🗑️',
        ),
        const _CleanStep(
          name: 'Pub Get',
          description: 'Refreshing project dependencies',
          command: ['pub', 'get'],
          icon: '📦',
        ),
        const _CleanStep(
          name: 'Generate Localizations',
          description: 'Regenerating localization files',
          command: ['gen-l10n'],
          icon: '🌐',
        ),
      ];

      /// List of successfully completed steps for final reporting.
      final List<String> completedSteps = [];

      // Execute each cleaning step
      for (final _CleanStep step in cleanSteps) {
        final Progress progress = logger.progress('${step.icon} ${step.description}...');

        try {
          await _runFlutterCommand(
            step.command,
            workingDirectory: projectPath,
            verbose: verbose,
          );

          progress.complete('${step.icon} ${step.name} completed');
          completedSteps.add(step.name);
        } catch (e) {
          progress.fail('${step.icon} ${step.name} failed');

          // Provide specific error guidance based on the failed step
          _handleStepError(logger, step, e);
          return 1;
        }
      }

      // Display success summary
      logger
        ..info('')
        ..success('✅ Deep clean completed successfully!')
        ..info('')
        ..info('Completed operations:');

      for (final String step in completedSteps) {
        logger.info('  ✓ $step');
      }

      logger
        ..info('')
        ..info('Your Flutter project has been thoroughly cleaned and refreshed.')
        ..info('You can now run your app or continue development.');

      return 0;
    } catch (error) {
      logger.err('Unexpected error during deep clean: $error');
      return 1;
    }
  }

  /// Checks if a directory contains a valid Flutter project.
  ///
  /// A valid Flutter project must have:
  /// * A pubspec.yaml file in the root directory
  /// * A lib/ directory for Dart source code
  /// * Flutter dependencies declared in pubspec.yaml
  ///
  /// Parameters:
  /// * [projectPath] - Path to the directory to validate
  ///
  /// Returns:
  /// * `true` if the directory contains a valid Flutter project
  /// * `false` if any required components are missing
  bool _isFlutterProject(String projectPath) {
    final File pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final Directory libDirectory = Directory(path.join(projectPath, 'lib'));

    // Check for required files and directories
    if (!pubspecFile.existsSync() || !libDirectory.existsSync()) {
      return false;
    }

    try {
      // Verify that pubspec.yaml contains Flutter dependencies
      final String pubspecContent = pubspecFile.readAsStringSync();
      return pubspecContent.contains('flutter:') || pubspecContent.contains('flutter_test:');
    } catch (e) {
      // If we can't read the pubspec.yaml file, assume it's not a valid project
      return false;
    }
  }

  /// Executes a Flutter command with proper error handling and output management.
  ///
  /// This method runs Flutter commands in the specified working directory and handles
  /// both successful execution and error conditions appropriately.
  ///
  /// Parameters:
  /// * [args] - List of arguments to pass to the flutter command
  /// * [workingDirectory] - Directory where the command should be executed
  /// * [verbose] - Whether to display detailed command output
  ///
  /// Throws:
  /// * [Exception] if the Flutter command fails or Flutter SDK is not available
  Future<void> _runFlutterCommand(
    List<String> args, {
    required String workingDirectory,
    bool verbose = false,
  }) async {
    try {
      final ProcessResult result = await Process.run(
        'flutter',
        args,
        workingDirectory: workingDirectory,
      );

      if (result.exitCode != 0) {
        final String errorOutput = result.stderr.toString().trim();
        final String standardOutput = result.stdout.toString().trim();

        String errorMessage = 'Flutter command failed: flutter ${args.join(' ')}';
        if (errorOutput.isNotEmpty) {
          errorMessage += '\nError: $errorOutput';
        }
        if (standardOutput.isNotEmpty && verbose) {
          errorMessage += '\nOutput: $standardOutput';
        }

        throw Exception(errorMessage);
      }

      // Display command output in verbose mode
      if (verbose) {
        final String output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          print(output);
        }
      }
    } on ProcessException catch (e) {
      throw Exception(
        'Failed to execute Flutter command. Please ensure Flutter SDK is installed and available in PATH.\n'
        'Error: ${e.message}',
      );
    }
  }

  /// Provides specific error handling and guidance based on the failed cleaning step.
  ///
  /// This method analyzes which step failed and provides targeted troubleshooting
  /// advice to help users resolve common issues.
  ///
  /// Parameters:
  /// * [logger] - Logger instance for displaying error messages
  /// * [step] - The cleaning step that failed
  /// * [error] - The error that occurred during step execution
  void _handleStepError(Logger logger, _CleanStep step, Object error) {
    logger
      ..info('')
      ..err('${step.name} failed: $error')
      ..info('');

    // Provide step-specific troubleshooting guidance
    switch (step.name) {
      case 'Flutter Clean':
        logger
          ..info('Troubleshooting Flutter Clean failure:')
          ..info('  • Ensure no Flutter processes are running')
          ..info('  • Check file permissions in the project directory')
          ..info('  • Try closing your IDE and running the command again')
          ..info('  • Verify Flutter SDK is properly installed');

      case 'Pub Get':
        logger
          ..info('Troubleshooting Pub Get failure:')
          ..info('  • Check your internet connection')
          ..info('  • Verify pubspec.yaml syntax is correct')
          ..info('  • Try running "flutter pub cache repair"')
          ..info('  • Check if any dependencies have version conflicts')
          ..info('  • Ensure you have access to all package repositories');

      case 'Generate Localizations':
        logger
          ..info('Troubleshooting Localization Generation failure:')
          ..info('  • Verify l10n configuration in pubspec.yaml')
          ..info('  • Check that .arb files exist in the specified directory')
          ..info('  • Ensure .arb files have valid JSON syntax')
          ..info('  • Verify flutter_localizations dependency is included')
          ..info('  • Check that generate: true is set in pubspec.yaml');

      default:
        logger
          ..info('General troubleshooting:')
          ..info('  • Ensure Flutter SDK is up to date')
          ..info('  • Try running "flutter doctor" to check your setup')
          ..info('  • Check project permissions and file access')
          ..info('  • Restart your terminal and try again');
    }

    logger.info('');
  }
}

/// Represents a single step in the deep cleaning process.
///
/// Each step encapsulates the information needed to execute and report on
/// a specific Flutter command during the deep clean workflow.
class _CleanStep {
  /// Human-readable name of the cleaning step.
  final String name;

  /// Detailed description of what this step accomplishes.
  final String description;

  /// Flutter command arguments to execute for this step.
  final List<String> command;

  /// Emoji icon used for visual identification in progress reporting.
  final String icon;

  /// Creates a new cleaning step with the specified configuration.
  ///
  /// Parameters:
  /// * [name] - Display name for the step
  /// * [description] - What the step does
  /// * [command] - Flutter command arguments
  /// * [icon] - Emoji for visual representation
  const _CleanStep({
    required this.name,
    required this.description,
    required this.command,
    required this.icon,
  });
}
