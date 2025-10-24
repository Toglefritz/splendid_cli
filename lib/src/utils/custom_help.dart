import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Utility class for generating custom help output.
///
/// This class provides enhanced help formatting with colorized output, ASCII art branding, and comprehensive command
/// information that improves upon the default args package help system.
// ignore_for_file: cascade_invocations
class CustomHelp {
  /// Creates a new custom help utility.
  const CustomHelp();

  /// Displays general CLI help with branding and overview.
  ///
  /// This method shows the main help screen with:
  /// * CLI description and purpose
  /// * List of available commands with descriptions
  /// * Usage examples and tips
  /// * Additional resources and links
  ///
  /// Parameters:
  /// * [logger] - Logger instance for formatted output
  /// * [runner] - Command runner instance for accessing commands
  static void showGeneralHelp(Logger logger, CommandRunner<int> runner) {
    // Main description
    logger.info('${lightCyan.wrap('Splendid CLI')} - Scaffold and manage Flutter apps using MVC standards');
    logger.info('');
    logger.info('A powerful command-line tool for creating Flutter applications that follow');
    logger.info('best practices including MVC architecture, strong typing, localization,');
    logger.info('comprehensive testing, and consistent code organization.');
    logger.info('');

    // Usage section
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli <command> [arguments]');
    logger.info('');

    // Available commands section
    logger.info('${yellow.wrap('AVAILABLE COMMANDS:')}');
    logger.info('');

    final List<CommandInfo> commands = [
      const CommandInfo(
        name: 'create',
        description: 'Create a new Flutter app with MVC architecture',
        example: 'splendid_cli create my_awesome_app',
      ),
      const CommandInfo(
        name: 'screen',
        description: 'Add a new screen with MVC architecture to existing Flutter app',
        example: 'splendid_cli screen game',
      ),
      const CommandInfo(
        name: 'setup',
        description: 'Setup a Flutter project (pub get, gen-l10n, run)',
        example: 'splendid_cli setup --project my_app',
      ),
      const CommandInfo(
        name: 'generate-test',
        aliases: ['gen-test'],
        description: 'Generate test file templates for Dart classes and widgets',
        example: 'splendid_cli gen-test lib/services/api_service.dart',
      ),
      const CommandInfo(
        name: 'gui',
        aliases: ['dashboard'],
        description: 'Launch GUI dashboard for visual project management',
        example: 'splendid_cli gui --project-path ~/my_project',
      ),
      const CommandInfo(
        name: 'format-dartdoc',
        aliases: ['fmt-doc', 'format-docs'],
        description: 'Reformat and rewrap Dartdoc comments to specified line length',
        example: 'splendid_cli format-dartdoc . --line-length 120',
      ),
      const CommandInfo(
        name: 'cache',
        description: 'Manage the local brick cache (list, info, clear)',
        example: 'splendid_cli cache list',
      ),
      const CommandInfo(
        name: 'help',
        description: 'Show help information for commands',
        example: 'splendid_cli help create',
      ),
    ];

    for (final CommandInfo cmd in commands) {
      final String nameWithAliases = cmd.aliases.isNotEmpty ? '${cmd.name} (${cmd.aliases.join(', ')})' : cmd.name;

      logger.info('  ${green.wrap(nameWithAliases.padRight(20))} ${cmd.description}');
      logger.info('    ${darkGray.wrap('Example: ${cmd.example}')}');
      logger.info('');
    }

    // Quick start section
    logger.info('${yellow.wrap('QUICK START:')}');
    logger.info('  1. ${cyan.wrap('splendid_cli create my_app')}        # Create new Flutter project');
    logger.info('  2. ${cyan.wrap('splendid_cli setup --project my_app')} # Setup dependencies and run');
    logger.info('  3. ${cyan.wrap('splendid_cli gen-test lib/main.dart')} # Generate test templates');
    logger.info('');

    // Global options
    logger.info('${yellow.wrap('GLOBAL OPTIONS:')}');
    logger.info('  ${green.wrap('-h, --help')}    Show help information');
    logger.info('  ${green.wrap('--version')}     Show version information');
    logger.info('');

    // Additional help
    logger.info('${yellow.wrap('GET MORE HELP:')}');
    logger.info('  ${cyan.wrap('splendid_cli help <command>')}  Show detailed help for a specific command');
    logger.info('  ${cyan.wrap('splendid_cli <command> --help')} Show help for a command (alternative)');
    logger.info('');

    // Footer with tips
    logger.info(
      '${darkGray.wrap('💡 Tip: Use')} ${cyan.wrap('--force')} ${darkGray.wrap('to overwrite existing files when needed')}',
    );
    logger.info('${darkGray.wrap('📚 Documentation: https://github.com/your-org/splendid_cli')}');
    logger.info('');
  }

  /// Displays help for a specific command.
  ///
  /// This method shows detailed help for the requested command including:
  /// * Command description and purpose
  /// * Usage patterns and syntax
  /// * Available options and flags
  /// * Detailed examples with explanations
  /// * Related commands and workflows
  ///
  /// Parameters:
  /// * [commandName] - Name of the command to show help for
  /// * [logger] - Logger instance for formatted output
  /// * [runner] - Command runner instance for accessing commands
  ///
  /// Returns:
  /// * `true` if command help was shown successfully
  /// * `false` if the command name is invalid
  static bool showCommandHelp(String commandName, Logger logger, CommandRunner<int> runner) {
    final Command<int>? command = runner.commands[commandName];

    if (command == null) {
      logger.err('Unknown command: $commandName');
      logger.info('');
      logger.info('Available commands: ${runner.commands.keys.join(', ')}');
      logger.info('Use ${cyan.wrap('splendid_cli --help')} to see all available commands.');
      return false;
    }

    logger.info('');
    logger.info('${lightCyan.wrap('Splendid CLI')} - ${command.description}');
    logger.info('');

    // Show detailed help based on command type
    switch (commandName) {
      case 'create':
        _showCreateCommandHelp(logger);
      case 'screen':
        _showScreenCommandHelp(logger);
      case 'setup':
        _showSetupCommandHelp(logger);
      case 'generate-test':
      case 'gen-test':
        _showGenerateTestCommandHelp(logger);
      case 'format-dartdoc':
      case 'fmt-doc':
      case 'format-docs':
        _showFormatDartdocCommandHelp(logger);
      case 'gui':
      case 'dashboard':
        _showGuiCommandHelp(logger);
      case 'help':
        _showHelpCommandHelp(logger);
      default:
        // Fallback to standard help
        logger.info('${yellow.wrap('USAGE:')}');
        logger.info('  ${command.invocation}');
        logger.info('');
        logger.info('${yellow.wrap('DESCRIPTION:')}');
        logger.info('  ${command.description}');
        logger.info('');
    }

    return true;
  }

  /// Shows detailed help for the create command.
  static void _showCreateCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli create <project_name> [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Creates a new Flutter project with MVC architecture, strong typing,');
    logger.info('  localization setup, and other best practices. The generated project');
    logger.info('  includes proper directory structure, analysis options, and dependencies.');
    logger.info('');

    logger.info('${yellow.wrap('ARGUMENTS:')}');
    logger.info('  ${green.wrap('project_name')}    Name of the Flutter project to create');
    logger.info('                   Must follow Dart package naming conventions');
    logger.info('                   (lowercase, underscores, no hyphens)');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('-o, --output-directory')}  Custom directory for project creation');
    logger.info('  ${green.wrap('--platforms')}             Platforms to enable (comma-separated)');
    logger.info('                              Default: android,ios,web,windows,macos,linux');
    logger.info('  ${green.wrap('--force')}                 Overwrite existing directories');
    logger.info('  ${green.wrap('-h, --help')}              Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli create my_awesome_app')}');
    logger.info('    Create a new Flutter project with all platforms');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli create mobile_app --platforms android,ios')}');
    logger.info('    Create a mobile-only project');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli create my_app --output-directory ~/projects --force')}');
    logger.info('    Create project in custom directory, overwriting if exists');
    logger.info('');

    logger.info('${yellow.wrap('WHAT GETS CREATED:')}');
    logger.info('  • MVC architecture with routes, controllers, and views');
    logger.info('  • Localization setup with app_en.arb');
    logger.info('  • Theme configuration with consistent styling');
    logger.info('  • Analysis options with very_good_analysis');
    logger.info('  • Proper directory structure and organization');
    logger.info('  • Platform-specific configurations');
    logger.info('');

    logger.info('${yellow.wrap('NEXT STEPS:')}');
    logger.info('  After creating your project, run:');
    logger.info('  ${cyan.wrap('splendid_cli setup --project <project_name>')}');
    logger.info('');
  }

  /// Shows detailed help for the screen command.
  static void _showScreenCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli screen <screen_name> [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Adds a new screen to an existing Flutter project following MVC');
    logger.info('  architecture patterns. Creates route, controller, and view files');
    logger.info('  with proper separation of concerns and placeholder content.');
    logger.info('');

    logger.info('${yellow.wrap('ARGUMENTS:')}');
    logger.info('  ${green.wrap('screen_name')}      Name of the screen to create');
    logger.info('                     Must be a valid Dart identifier');
    logger.info('                     (letters, numbers, underscores)');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('--force')}           Overwrite existing screen files');
    logger.info('  ${green.wrap('-h, --help')}        Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli screen game')}');
    logger.info('    Create a new game screen with MVC structure');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli screen UserProfile')}');
    logger.info('    Create user profile screen (converts to user_profile files)');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli screen settings --force')}');
    logger.info('    Create settings screen, overwriting if exists');
    logger.info('');

    logger.info('${yellow.wrap('WHAT GETS CREATED:')}');
    logger.info('  • ${cyan.wrap('lib/screens/<screen_name>/<screen_name>_route.dart')}');
    logger.info('    StatefulWidget entry point for the screen');
    logger.info('  • ${cyan.wrap('lib/screens/<screen_name>/<screen_name>_controller.dart')}');
    logger.info('    State management and business logic');
    logger.info('  • ${cyan.wrap('lib/screens/<screen_name>/<screen_name>_view.dart')}');
    logger.info('    UI presentation layer (StatelessWidget)');
    logger.info('');

    logger.info('${yellow.wrap('PLACEHOLDER CONTENT:')}');
    logger.info('  The generated screen includes a simple icon selection game with:');
    logger.info('  • Three Material icons (rocket, chef hat, art palette)');
    logger.info('  • Random arrangement and target selection');
    logger.info('  • User interaction handling in the controller');
    logger.info('  • Clean separation between business logic and UI');
    logger.info('');

    logger.info('${yellow.wrap('REQUIREMENTS:')}');
    logger.info('  • Must be run from the root of a Flutter project');
    logger.info('  • Project must have lib/ directory and pubspec.yaml');
    logger.info('  • Screen name must be a valid Dart identifier');
    logger.info('');

    logger.info('${yellow.wrap('NEXT STEPS:')}');
    logger.info('  After creating your screen:');
    logger.info('  1. Add navigation to the new screen in your app');
    logger.info('  2. Customize the screen content as needed');
    logger.info('  3. Update any routing configuration');
    logger.info('');
  }

  /// Shows detailed help for the setup command.
  static void _showSetupCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli setup [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Sets up a Flutter project by running the necessary post-creation');
    logger.info('  commands including dependency installation, localization generation,');
    logger.info('  and optionally launching the application.');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('-p, --project')}     Flutter project directory to setup');
    logger.info('                      Default: current directory');
    logger.info('  ${green.wrap('--[no-]run')}        Run the app after setup (default: true)');
    logger.info('  ${green.wrap('-v, --verbose')}     Enable verbose output from Flutter commands');
    logger.info('  ${green.wrap('-h, --help')}        Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('SETUP STEPS PERFORMED:')}');
    logger.info('  1. ${cyan.wrap('flutter pub get')}     Install dependencies');
    logger.info('  2. ${cyan.wrap('flutter gen-l10n')}    Generate localization files');
    logger.info('  3. ${cyan.wrap('flutter run')}         Launch the application (optional)');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli setup')}');
    logger.info('    Setup current directory as Flutter project');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli setup --project my_app --no-run')}');
    logger.info('    Setup specific project without running it');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli setup --verbose')}');
    logger.info('    Setup with detailed output from Flutter commands');
    logger.info('');
  }

  /// Shows detailed help for the generate-test command.
  static void _showGenerateTestCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli generate-test <dart_file> [options]');
    logger.info('  splendid_cli gen-test <dart_file> [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Generates comprehensive test file templates for Dart classes and');
    logger.info('  Flutter widgets. Automatically detects the file type and creates');
    logger.info('  appropriate test structure with documentation, setup/teardown,');
    logger.info('  and example test cases following best practices.');
    logger.info('');

    logger.info('${yellow.wrap('ARGUMENTS:')}');
    logger.info('  ${green.wrap('dart_file')}        Path to the Dart file to generate tests for');
    logger.info('                   Must be a .dart file that exists');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('-o, --output')}      Custom output directory for test file');
    logger.info('                     Default: mirrors source structure in test/');
    logger.info('  ${green.wrap('-t, --type')}        Test type: auto, widget, class (default: auto)');
    logger.info('                     auto: Automatically detect based on file content');
    logger.info('                     widget: Generate Flutter widget test');
    logger.info('                     class: Generate Dart class test');
    logger.info('  ${green.wrap('--force')}           Overwrite existing test files');
    logger.info('  ${green.wrap('-h, --help')}        Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli gen-test lib/services/api_service.dart')}');
    logger.info('    Auto-detect and generate appropriate test template');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli gen-test lib/widgets/my_widget.dart --type=widget')}');
    logger.info('    Explicitly generate a Flutter widget test');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli gen-test lib/models/user.dart --output=test/unit')}');
    logger.info('    Generate test in custom output directory');
    logger.info('');

    logger.info('${yellow.wrap('GENERATED TEST FEATURES:')}');
    logger.info('  • Comprehensive documentation with test categories');
    logger.info('  • Proper setup and teardown methods');
    logger.info('  • Organized test groups (initialization, core, edge cases, errors)');
    logger.info('  • Example test cases with detailed comments');
    logger.info('  • Flutter-specific patterns for widget tests');
    logger.info('  • Mock dependency placeholders');
    logger.info('');

    logger.info('${yellow.wrap('FILE TYPE DETECTION:')}');
    logger.info('  Widget tests: Files with Flutter imports and widget classes');
    logger.info('  Class tests:  Regular Dart classes without Flutter dependencies');
    logger.info('');
  }

  /// Shows detailed help for the format-dartdoc command.
  static void _showFormatDartdocCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli format-dartdoc <target> [options]');
    logger.info('  splendid_cli fmt-doc <target> [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Reformats and rewraps Dartdoc comments to a specified line length.');
    logger.info('  Particularly useful for migrating from 80-character to 120-character');
    logger.info('  line limits or standardizing comment formatting across team projects.');
    logger.info('  Intelligently preserves code blocks, lists, and special formatting.');
    logger.info('');

    logger.info('${yellow.wrap('ARGUMENTS:')}');
    logger.info('  ${green.wrap('target')}           Path to Dart file or directory to process');
    logger.info('                   For directories: processes all .dart files recursively');
    logger.info('                   Skips build/ and .dart_tool/ directories automatically');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('-l, --line-length')} Maximum line length for wrapped text (default: 120)');
    logger.info('                      Valid range: 40-200 characters');
    logger.info('  ${green.wrap('--dry-run')}         Preview changes without modifying files');
    logger.info('  ${green.wrap('-v, --verbose')}     Show detailed progress and file lists');
    logger.info('  ${green.wrap('-h, --help')}        Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli format-dartdoc .')}');
    logger.info('    Format all Dartdoc comments in current directory to 120 characters');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli format-dartdoc lib/services/api_service.dart --line-length 80')}');
    logger.info('    Format specific file with 80-character line limit');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli format-dartdoc lib/ --dry-run --verbose')}');
    logger.info('    Preview changes with detailed output, no modifications');
    logger.info('');

    logger.info('${yellow.wrap('FORMATTING BEHAVIOR:')}');
    logger.info('  • Wraps /// and /** */ style Dartdoc comments');
    logger.info('  • Preserves code blocks (```dart ... ```)');
    logger.info('  • Maintains list formatting and indentation');
    logger.info('  • Respects word boundaries for clean wrapping');
    logger.info('  • Leaves regular comments (//) unchanged');
    logger.info('  • Skips generated files and build directories');
    logger.info('');

    logger.info('${yellow.wrap('WHAT GETS PRESERVED:')}');
    logger.info('  • Code examples within ```dart blocks');
    logger.info('  • Markdown headers (# ## ###)');
    logger.info('  • List items (* - + numbered)');
    logger.info('  • Documentation tags (@param, @returns, etc.)');
    logger.info('  • Original indentation levels');
    logger.info('');

    logger.info('${yellow.wrap('NEXT STEPS:')}');
    logger.info('  After formatting:');
    logger.info('  1. Review changes in your version control system');
    logger.info('  2. Run tests to ensure no functionality was affected');
    logger.info('  3. Consider running ${cyan.wrap('dart format')} for code formatting');
    logger.info('');
  }

  /// Shows detailed help for the GUI command.
  static void _showGuiCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli gui [options]');
    logger.info('  splendid_cli dashboard [options]');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Launches a Flutter desktop application that provides a graphical');
    logger.info('  interface for all Splendid CLI functionality. The GUI offers');
    logger.info('  point-and-click access to project creation, screen generation,');
    logger.info('  test file creation, and other CLI tools with real-time feedback.');
    logger.info('');

    logger.info('${yellow.wrap('OPTIONS:')}');
    logger.info('  ${green.wrap('-p, --project-path')}  Initial project directory to open in GUI');
    logger.info('                        Default: current directory');
    logger.info('  ${green.wrap('--debug')}             Launch GUI in debug mode with additional logging');
    logger.info('  ${green.wrap('-h, --help')}          Show this help message');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli gui')}');
    logger.info('    Launch GUI dashboard for current directory');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli gui --project-path ~/my_flutter_app')}');
    logger.info('    Launch GUI with specific project directory');
    logger.info('');
    logger.info('  ${cyan.wrap('splendid_cli dashboard --debug')}');
    logger.info('    Launch GUI in debug mode with verbose logging');
    logger.info('');

    logger.info('${yellow.wrap('GUI FEATURES:')}');
    logger.info('  • Visual project creation wizard with platform selection');
    logger.info('  • Screen generation interface with MVC architecture preview');
    logger.info('  • Test file generation with file browser integration');
    logger.info('  • Real-time command output with copy-to-clipboard');
    logger.info('  • Project detection and Flutter status indicators');
    logger.info('  • Cross-platform desktop support (Windows, macOS, Linux)');
    logger.info('');

    logger.info('${yellow.wrap('REQUIREMENTS:')}');
    logger.info('  • Flutter SDK installed and available in PATH');
    logger.info('  • Desktop platform support enabled for Flutter');
    logger.info('  • Sufficient system resources for Flutter desktop app');
    logger.info('');

    logger.info('${yellow.wrap('PLATFORM SUPPORT:')}');
    logger.info('  • Windows: Native Windows desktop application');
    logger.info('  • macOS: Native macOS desktop application');
    logger.info('  • Linux: Native Linux desktop application');
    logger.info('');

    logger.info('${yellow.wrap('NEXT STEPS:')}');
    logger.info('  After launching the GUI:');
    logger.info('  1. Select or create a Flutter project directory');
    logger.info('  2. Use the visual interface to manage your project');
    logger.info('  3. View real-time output in the expandable output panel');
    logger.info('');
  }

  /// Shows detailed help for the help command itself.
  static void _showHelpCommandHelp(Logger logger) {
    logger.info('${yellow.wrap('USAGE:')}');
    logger.info('  splendid_cli help [command]');
    logger.info('  splendid_cli --help');
    logger.info('');

    logger.info('${yellow.wrap('DESCRIPTION:')}');
    logger.info('  Shows help information for the CLI or specific commands.');
    logger.info('  Provides detailed usage instructions, examples, and options.');
    logger.info('');

    logger.info('${yellow.wrap('EXAMPLES:')}');
    logger.info('  ${cyan.wrap('splendid_cli --help')}         Show general CLI help');
    logger.info('  ${cyan.wrap('splendid_cli help create')}    Show help for create command');
    logger.info('  ${cyan.wrap('splendid_cli help gen-test')}  Show help for generate-test command');
    logger.info('');
  }
}

/// Information about a CLI command for help display.
///
/// This class contains metadata about commands that is used to generate consistent and informative help output.
class CommandInfo {
  /// Creates command information for help display.
  const CommandInfo({
    required this.name,
    required this.description,
    required this.example,
    this.aliases = const [],
  });

  /// The primary name of the command.
  final String name;

  /// Brief description of what the command does.
  final String description;

  /// Example usage of the command.
  final String example;

  /// Alternative names (aliases) for the command.
  final List<String> aliases;
}
