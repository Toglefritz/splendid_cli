import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

import '../services/screen_service.dart';

/// Command-line interface for adding new screens to existing Flutter applications.
///
/// This command generates a new screen following Splendid's MVC architecture patterns. It uses Mason bricks to ensure
/// consistent screen structure with proper separation of concerns between route, controller, and view components. The
/// generated screen includes a simple icon selection game as placeholder content.
///
/// The generated screen includes:
/// * Route class for screen entry point (StatefulWidget)
/// * Controller class for business logic and state management
/// * View class for UI presentation (StatelessWidget)
/// * Icon selection game with randomized layout and target selection
/// * Proper MVC separation following established patterns
///
/// Usage Examples:
/// ```bash
/// # Add a new screen to current Flutter project
/// splendid_cli screen game
///
/// # Add screen with specific name
/// splendid_cli screen user_profile
///
/// # Force overwrite existing screen files
/// splendid_cli screen settings --force
/// ```
///
/// Exit Codes:
/// * `0` - Success: Screen created successfully
/// * `1` - General error: Unexpected failure during generation
/// * `64` - Usage error: Invalid arguments or not in Flutter project (EX_USAGE)
///
/// Performance: Typical generation time is under 1 second for screen creation.
///
/// Thread Safety: This command is not thread-safe and should not be run concurrently for the same screen name.
class ScreenCommand extends Command<int> {
  /// Service for handling screen operations.
  static const ScreenService _screenService = ScreenService();

  /// Creates a new instance of [ScreenCommand] with configured argument parser.
  ///
  /// Initializes the command with support for:
  /// * `--force`: Overwrite existing screen files without confirmation
  ///
  /// The argument parser is configured during construction to ensure all command-line options are properly defined and
  /// validated before execution.
  ScreenCommand() {
    argParser.addFlag(
      'force',
      help: 'Whether to force screen generation, overwriting existing files.',
      negatable: false,
    );
  }

  /// Brief description of the command's purpose for help text.
  ///
  /// This description appears in the CLI help output when users run `splendid_cli help` or `splendid_cli screen
  /// --help`.
  @override
  String get description => 'Add a new screen with MVC architecture to an existing Flutter app.';

  /// The command name used for CLI invocation.
  ///
  /// Users invoke this command by running `splendid_cli screen <args>`.
  @override
  String get name => 'screen';

  /// Usage pattern displayed in help text and error messages.
  ///
  /// Shows the expected command structure with required and optional arguments. The screen name is required, while
  /// flags are optional.
  @override
  String get invocation => 'splendid_cli screen <screen_name> [arguments]';

  /// Executes the screen command with parsed command-line arguments.
  ///
  /// This method orchestrates the complete screen generation workflow:
  /// 1. Validates command-line arguments and screen name
  /// 2. Verifies that the current directory is a Flutter project
  /// 3. Checks for existing screen files and handles conflicts
  /// 4. Loads the appropriate Mason brick template
  /// 5. Generates the screen files with MVC structure
  /// 6. Provides user feedback and next steps
  ///
  /// The method handles various error conditions gracefully:
  /// * Missing or invalid screen names
  /// * Not being run in a Flutter project directory
  /// * File conflicts (existing screens without --force)
  /// * File system permission errors
  /// * Mason brick loading failures
  /// * Template generation errors
  ///
  /// Returns:
  /// * `0` on successful screen creation
  /// * `1` for unexpected errors during generation
  /// * `64` for usage errors (missing args, invalid names, not in Flutter project)
  ///
  /// Throws:
  /// * No exceptions are thrown; all errors are handled internally
  /// and communicated through return codes and user messages
  @override
  Future<int> run() async {
    /// Logger instance for user-facing output and error reporting.
    final Logger logger = Logger();

    // Validate that a screen name was provided as a positional argument
    if (argResults!.rest.isEmpty) {
      logger
        ..err('Screen name is required.')
        ..info(usage);

      return 64;
    }

    /// The screen name provided by the user as the first positional argument.
    final String screenName = argResults!.rest.first;

    /// Whether to force overwrite existing screen files (--force flag).
    final bool force = argResults!['force'] as bool;

    // Create request object
    final ScreenCreationRequest request = ScreenCreationRequest(
      screenName: screenName,
      projectPath: Directory.current.path,
      force: force,
    );

    try {
      // Check if screen exists and show warning if force is used
      final String screenPath = path.join(Directory.current.path, 'lib', 'screens', _toSnakeCase(screenName));
      final Directory screenDirectory = Directory(screenPath);

      if (screenDirectory.existsSync() && force) {
        logger.warn('Overwriting existing screen: $screenName');
      }

      logger.info('Generating screen: $screenName');

      // Use service to create screen
      final ScreenCreationResult result = await _screenService.createScreen(request);

      if (result.success) {
        logger
          ..success('✓ Generated screen: ${result.screenName}')
          ..info('')
          ..info('Screen files created:');

        for (final String file in result.createdFiles) {
          logger.info('  $file');
        }

        logger
          ..info('')
          ..info('Next steps:')
          ..info('  1. Add navigation to the new screen in your app')
          ..info('  2. Customize the screen content as needed')
          ..info('  3. Update any routing configuration');

        return 0;
      } else {
        logger.err('Failed to create screen: ${result.error}');
        return 1;
      }
    } on ScreenServiceException catch (e) {
      switch (e.type) {
        case ScreenServiceErrorType.invalidScreenName:
          logger
            ..err(e.message)
            ..info('Screen name must be a valid Dart identifier (letters, numbers, underscores).');
          return 64;
        case ScreenServiceErrorType.notFlutterProject:
          logger
            ..err(e.message)
            ..info('Run this command from the root of a Flutter project.');
          return 64;
        case ScreenServiceErrorType.screenExists:
          logger
            ..err(e.message)
            ..info('Use --force to overwrite existing screen files.');
          return 1;
        // A default case is useful to guard against any unforeseen errors.
        // ignore: no_default_cases
        default:
          logger.err('Failed to create screen: ${e.message}');
          return 1;
      }
    } catch (error) {
      logger.err('Failed to create screen: $error');
      return 1;
    }
  }

  /// Converts a string to snake_case format.
  ///
  /// Transforms the input string to follow snake_case naming conventions used for file names and some variable names in
  /// Dart projects.
  ///
  /// Conversion rules:
  /// * Converts uppercase letters to lowercase
  /// * Inserts underscores before uppercase letters (except at the start)
  /// * Preserves existing underscores
  /// * Handles consecutive uppercase letters appropriately
  ///
  /// Examples:
  /// * `UserProfile` → `user_profile`
  /// * `gameBoard` → `game_board`
  /// * `HTTPClient` → `http_client`
  /// * `already_snake_case` → `already_snake_case`
  ///
  /// Parameters:
  /// * [input] - The string to convert to snake_case
  ///
  /// Returns:
  /// * String in snake_case format
  ///
  /// Performance: O(n) where n is the length of the input string
  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp('[A-Z]'), (Match match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp('^_'), '');
  }
}
