import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

/// Command-line interface for creating new Flutter applications with MVC architecture.
///
/// This command generates a complete Flutter project structure following Splendid's MVC coding standards. It uses
/// Mason bricks to ensure consistent project layout, proper separation of concerns, and adherence to established
/// patterns. The command first creates a Flutter project with specified platform support, then applies the MVC
/// template structure.
///
/// The generated applications include:
/// * Route classes for screen entry points (StatefulWidget)
/// * Controller classes for business logic and state management
/// * View classes for UI presentation (StatelessWidget)
/// * Proper directory structure organized by features
/// * Pre-configured analysis options and formatting rules
/// * Standard dependencies and development tools
/// * Platform support for all Flutter platforms by default
///
/// Usage Examples:
/// ```bash
/// # Create app with all platforms (default)
/// splendid_cli create awesome_app
///
/// # Create app with specific platforms
/// splendid_cli create mobile_app --platforms android,ios
///
/// # Create app in specific directory
/// splendid_cli create cool_app --output-directory ~/projects
///
/// # Force overwrite existing directory
/// splendid_cli create cool_app --force
/// ```
///
/// Exit Codes:
/// * `0` - Success: Application created successfully
/// * `1` - General error: Unexpected failure during generation
/// * `64` - Usage error: Invalid arguments or project name (EX_USAGE)
///
/// Performance: Typical generation time is 2-5 seconds depending on system I/O performance.
///
/// Thread Safety: This command is not thread-safe and should not be run concurrently for the same target directory.
class CreateCommand extends Command<int> {
  /// Creates a new instance of [CreateCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--output-directory` (-o): Custom target directory for project creation
  /// * `--force`: Overwrite existing directories without confirmation
  ///
  /// The argument parser is configured during construction to ensure all command-line options are properly defined
  /// and validated before execution.
  CreateCommand() {
    argParser
      ..addOption(
        'output-directory',
        abbr: 'o',
        help: 'The desired output directory when creating a new project.',
      )
      ..addOption(
        'platforms',
        help:
            'The platforms to enable for this project (comma-separated).\n'
            'Available: android,ios,web,windows,macos,linux\n'
            'Default: all platforms',
        defaultsTo: 'android,ios,web,windows,macos,linux',
      )
      ..addFlag(
        'force',
        help: 'Whether to force project generation.',
        negatable: false,
      );
  }

  /// Brief description of the command's purpose for help text.
  ///
  /// This description appears in the CLI help output when users run `splendid_cli help` or
  /// `splendid_cli create --help`.
  @override
  String get description => 'Create a new Flutter app with MVC architecture and platform support.';

  /// The command name used for CLI invocation.
  ///
  /// Users invoke this command by running `splendid_cli create <args>`.
  @override
  String get name => 'create';

  /// Usage pattern displayed in help text and error messages.
  ///
  /// Shows the expected command structure with required and optional arguments. The project name is required, while
  /// flags and options are optional.
  @override
  String get invocation => 'splendid_cli create <project_name> [arguments]';

  /// Executes the create command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete application generation workflow:
  /// 1. Validates command-line arguments and project name
  /// 2. Determines target directory and handles existing directory conflicts
  /// 3. Loads the appropriate Mason brick template
  /// 4. Generates the Flutter project with MVC structure
  /// 5. Provides user feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid project names
  /// * Directory conflicts (existing directories without --force)
  /// * File system permission errors
  /// * Mason brick loading failures
  /// * Template generation errors
  ///
  /// Returns:
  /// * `0` on successful project creation
  /// * `1` for unexpected errors during generation
  /// * `64` for usage errors (missing args, invalid names, etc.)
  ///
  /// Throws:
  /// * No exceptions are thrown; all errors are handled internally
  ///   and communicated through return codes and user messages
  @override
  Future<int> run() async {
    /// Logger instance for user-facing output and error reporting.
    ///
    /// Provides structured logging with different levels (info, success, warn, err) and consistent formatting across
    /// all CLI operations.
    final Logger logger = Logger();

    // Validate that a project name was provided as a positional argument
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Project name is required.')
        ..info(usage);

      return 64;
    }

    /// The project name provided by the user as the first positional argument.
    ///
    /// This name will be used for:
    /// * Directory name (unless custom output directory is specified)
    /// * Dart package name in pubspec.yaml
    /// * Template variable substitution in Mason brick
    final String projectName = argResults!.rest.first;

    /// Optional custom output directory specified via --output-directory flag.
    ///
    /// When provided, the project will be created in a subdirectory of this path. When null, the project is created in
    /// the current working directory.
    final String? outputDirectory = argResults!['output-directory'] as String?;

    /// Whether to force overwrite existing directories (--force flag).
    ///
    /// When true, existing directories will be overwritten without confirmation. When false, the command will fail if
    /// the target directory already exists.
    final bool force = argResults!['force'] as bool;

    /// Comma-separated list of platforms to enable for the Flutter project.
    ///
    /// Defaults to all available platforms (android,ios,web,windows,macos,linux) unless explicitly specified by the
    /// user via the --platforms flag.
    final String platforms = argResults!['platforms'] as String;

    // Validate project name
    if (!_isValidProjectName(projectName)) {
      logger
        ..err('Invalid project name: $projectName')
        ..info('Project name must be a valid Dart package name.');

      return 64;
    }

    /// Absolute path where the new Flutter project will be created.
    ///
    /// Constructed by combining the output directory (if specified) with the project name. If no output directory is
    /// provided, the project is created in the current directory.
    final String targetPath = outputDirectory != null ? path.join(outputDirectory, projectName) : projectName;

    /// Directory object representing the target location for project creation.
    ///
    /// Used for existence checks, creation, and as the target for Mason generation. The directory will be created
    /// recursively if it doesn't exist.
    final Directory targetDirectory = Directory(targetPath);

    // Check if directory exists and handle force flag
    if (targetDirectory.existsSync()) {
      if (!force) {
        logger
          ..err('Directory $targetPath already exists.')
          ..info('Use --force to overwrite existing directory.');
        return 1;
      }
      logger.warn('Overwriting existing directory: $targetPath');
    }

    try {
      // First create a Flutter project with specified platforms
      logger.info('Creating Flutter project with platform support...');
      await _createFlutterProject(projectName, targetPath, platforms, logger);

      // Remove default Flutter files that will be replaced by our MVC template
      logger.info('Preparing for MVC architecture template...');
      await _removeDefaultFlutterFiles(targetPath, logger);

      /// Mason generator instance loaded from the flutter_app brick template.
      ///
      /// The generator contains all template files and logic needed to create a complete Flutter application with MVC
      /// architecture.
      final MasonGenerator generator = await _loadBrick(logger);

      /// Template variables passed to the Mason brick during generation.
      ///
      /// Currently includes:
      /// * `name`: The project name for package naming and file generation
      ///
      /// Additional variables can be added here to customize the generated project based on user preferences or
      /// command-line options.
      final Map<String, dynamic> vars = {'name': projectName};

      logger.info('Applying MVC architecture template...');

      await generator.generate(
        DirectoryGeneratorTarget(Directory(targetPath)),
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      logger
        ..success('✓ Generated Flutter app: $projectName')
        ..info('')
        ..info('Next steps:')
        ..info('  cd $targetPath')
        ..info('  flutter pub get')
        ..info('  flutter run');

      return 0;
    } catch (error) {
      logger.err('Failed to create project: $error');

      return 1;
    }
  }

  /// Loads and initializes the Mason brick template for Flutter app generation.
  ///
  /// This method locates the `flutter_app` brick in the CLI package's brick directory and creates a Mason generator
  /// instance for project scaffolding.
  ///
  /// The brick path is resolved relative to the CLI executable location:
  /// `<cli_location>/../bricks/flutter_app/`
  ///
  /// Parameters:
  /// * [logger] - Logger instance for error reporting during brick loading
  ///
  /// Returns:
  /// * [MasonGenerator] configured with the flutter_app brick template
  ///
  /// Throws:
  /// * [FileSystemException] if the brick directory doesn't exist
  /// * [FormatException] if the brick.yaml file is malformed
  /// * [StateError] if the brick cannot be loaded or initialized
  ///
  /// Performance: Brick loading is typically fast (< 100ms) as it only reads metadata and doesn't process template
  /// files until generation.
  Future<MasonGenerator> _loadBrick(Logger logger) async {
    try {
      /// Absolute path to the flutter_app brick directory.
      ///
      /// Constructed by navigating from the CLI executable location to the bricks directory. This approach ensures the
      /// brick can be found regardless of where the CLI is installed or executed from.
      final String brickPath = path.join(
        path.dirname(Platform.script.path),
        '..',
        'bricks',
        'flutter_app',
      );

      /// Mason brick instance loaded from the file system.
      ///
      /// The brick contains metadata (brick.yaml) and template files (__brick__ directory) that define the structure
      /// and content of generated Flutter projects.
      final Brick brick = Brick.path(brickPath);

      return MasonGenerator.fromBrick(brick);
    } catch (error) {
      logger.err('Failed to load brick: $error');

      rethrow;
    }
  }

  /// Creates a new Flutter project with specified platform support using flutter create command.
  ///
  /// This method executes the `flutter create` command with appropriate platform flags to generate a base Flutter
  /// project structure. The generated project includes platform-specific code and configurations for the requested
  /// platforms.
  ///
  /// The method handles platform validation and constructs the appropriate command-line arguments for the Flutter CLI.
  /// Invalid platforms are filtered out to prevent command failures.
  ///
  /// Parameters:
  /// * [projectName] - Name of the Flutter project to create
  /// * [targetPath] - Directory path where the project should be created
  /// * [platforms] - Comma-separated list of platforms to enable
  /// * [logger] - Logger instance for progress reporting and error handling
  ///
  /// Supported platforms:
  /// * `android` - Android mobile platform
  /// * `ios` - iOS mobile platform
  /// * `web` - Web platform (Progressive Web App)
  /// * `windows` - Windows desktop platform
  /// * `macos` - macOS desktop platform
  /// * `linux` - Linux desktop platform
  ///
  /// Throws:
  /// * [ProcessException] if the flutter command fails or is not found
  /// * [FileSystemException] if the target directory cannot be accessed
  ///
  /// Performance: Command execution time varies by platform count (2-10 seconds typical)
  Future<void> _createFlutterProject(
    String projectName,
    String targetPath,
    String platforms,
    Logger logger,
  ) async {
    /// List of valid Flutter platforms that can be enabled during project creation.
    ///
    /// These correspond to the platforms supported by the Flutter SDK and must match the exact names expected by the
    /// `flutter create --platforms` flag.
    const List<String> validPlatforms = [
      'android',
      'ios',
      'web',
      'windows',
      'macos',
      'linux',
    ];

    /// Parsed and validated list of platforms to enable for the project.
    ///
    /// Invalid platform names are filtered out to prevent flutter create command failures. The list is constructed by
    /// splitting the comma-separated input and validating each platform name.
    final List<String> enabledPlatforms = platforms
        .split(',')
        .map((String platform) => platform.trim().toLowerCase())
        .where((String platform) => validPlatforms.contains(platform))
        .toList();

    if (enabledPlatforms.isEmpty) {
      throw ArgumentError('No valid platforms specified. Valid platforms: ${validPlatforms.join(', ')}');
    }

    /// Command-line arguments for the flutter create command.
    ///
    /// Includes the project name, platforms flag, and target directory. The platforms are joined with commas as
    /// expected by the Flutter CLI.
    final List<String> createArgs = [
      'create',
      '--platforms=${enabledPlatforms.join(',')}',
      projectName,
    ];

    logger.info('Enabled platforms: ${enabledPlatforms.join(', ')}');

    /// Process result from executing the flutter create command.
    ///
    /// Contains exit code, stdout, and stderr from the command execution. Used to determine success/failure and
    /// provide detailed error information if the command fails.
    final ProcessResult result = await Process.run(
      'flutter',
      createArgs,
      workingDirectory: path.dirname(targetPath),
    );

    if (result.exitCode != 0) {
      throw ProcessException(
        'flutter',
        createArgs,
        'Flutter create failed with exit code ${result.exitCode}\n'
            'stdout: ${result.stdout}\n'
            'stderr: ${result.stderr}',
      );
    }
  }

  /// Removes default Flutter files that will be replaced by the MVC template.
  ///
  /// This method deletes the standard Flutter project files that conflict with our MVC architecture template,
  /// ensuring that Mason can properly apply the custom template without file conflicts.
  ///
  /// Files removed:
  /// * `lib/main.dart` - Replaced with MVC-structured main.dart
  /// * `test/widget_test.dart` - Replaced with MVC-appropriate tests
  /// * Any other conflicting files that would prevent proper template application
  ///
  /// The method preserves platform-specific files and configuration that was created by `flutter create`,
  /// only removing files that will be replaced by the Mason brick template.
  ///
  /// Parameters:
  /// * [targetPath] - Path to the Flutter project directory
  /// * [logger] - Logger instance for progress reporting
  ///
  /// Throws:
  /// * [FileSystemException] if files cannot be deleted due to permissions
  ///
  /// Performance: Fast operation (< 100ms) as it only deletes a few small files
  Future<void> _removeDefaultFlutterFiles(String targetPath, Logger logger) async {
    /// List of default Flutter files that conflict with our MVC template.
    ///
    /// These files are created by `flutter create` but need to be replaced with our custom MVC structure.
    /// The paths are relative to the project root directory.
    final List<String> filesToRemove = [
      'lib/main.dart',
      'test/widget_test.dart',
    ];

    for (final String filePath in filesToRemove) {
      final File file = File(path.join(targetPath, filePath));
      if (file.existsSync()) {
        try {
          await file.delete();
          logger.detail('Removed default file: $filePath');
        } catch (error) {
          logger.warn('Could not remove $filePath: $error');
          // Continue with other files even if one fails
        }
      }
    }
  }

  /// Validates that the project name conforms to Dart package naming conventions.
  ///
  /// Dart package names must follow specific rules to ensure compatibility with the Dart ecosystem and pub.dev
  /// publishing requirements:
  ///
  /// Valid name requirements:
  /// * Must start with a lowercase letter (a-z)
  /// * Can contain lowercase letters, numbers, and underscores
  /// * Cannot start with an underscore (reserved for private packages)
  /// * Cannot contain uppercase letters, hyphens, or special characters
  /// * Should be descriptive and unique within the pub.dev namespace
  ///
  /// Examples of valid names: `my_app`, `flutter_demo`, `awesome_project`
  /// Examples of invalid names: `MyApp`, `flutter-demo`, `_private`, `123app`
  ///
  /// Parameters:
  /// * [name] - The project name to validate
  ///
  /// Returns:
  /// * `true` if the name is valid for use as a Dart package name
  /// * `false` if the name violates Dart naming conventions
  ///
  /// Performance: O(1) - Uses compiled regex for efficient validation
  bool _isValidProjectName(String name) {
    /// Regular expression pattern for valid Dart package names.
    ///
    /// Pattern breakdown:
    /// * `^[a-z]` - Must start with lowercase letter
    /// * `[a-z0-9_]*` - Followed by any number of lowercase letters, digits, or underscores
    /// * `$` - Must match the entire string (no additional characters)
    final RegExp validName = RegExp(r'^[a-z][a-z0-9_]*$');

    return validName.hasMatch(name) && !name.startsWith('_');
  }
}
