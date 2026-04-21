/// A comprehensive CLI tool for scaffolding and managing Flutter applications.
///
/// Splendid CLI provides a complete toolkit for Flutter development with
/// built-in MVC architecture patterns, code generation, and project management
/// capabilities. It includes MCP (Model Context Protocol) server functionality
/// for integration with AI development tools.
///
/// Key Features:
/// * Project scaffolding with MVC architecture
/// * Screen generation with route/controller/view pattern
/// * Test file generation for widgets and classes
/// * Code formatting and documentation tools
/// * MCP server for AI tool integration
///
/// Usage:
/// ```bash
/// splendid_cli create my_app
/// splendid_cli screen LoginScreen
/// splendid_cli test lib/models/user.dart
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'src/commands/cache_command.dart';
import 'src/commands/create_command.dart';
import 'src/commands/deep_clean_command.dart';
import 'src/commands/format_all_command.dart';
import 'src/commands/format_comments_command.dart';
import 'src/commands/format_dartdoc_command.dart';
import 'src/commands/gui_command.dart';
import 'src/commands/screen_command.dart';
import 'src/commands/setup_command.dart';
import 'src/commands/sort_enum_command.dart';
import 'src/commands/sort_l10n_command.dart';
import 'src/commands/test_command.dart';
import 'src/utils/custom_help.dart';

// Export MCP server components
export 'src/mcp/mcp_server.dart';
export 'src/mcp/mcp_tool_registry.dart';
// Export services for external use
export 'src/services/comment_formatter_service.dart';
export 'src/services/dartdoc_formatter_service.dart';
export 'src/services/enum_sorter_service.dart';
export 'src/services/l10n_sorter_service.dart';
export 'src/services/project_service.dart';
export 'src/services/screen_service.dart';
export 'src/services/test_service.dart';

/// Top-level command runner for the Splendid CLI.
///
/// This class registers subcommands and handles top-level errors.
class SplendidCommandRunner extends CommandRunner<int> {
  /// Creates an instance of [SplendidCommandRunner].
  SplendidCommandRunner()
    : super(
        'splendid_cli',
        'Scaffold and manage Flutter apps using MVC standards.',
      ) {
    // Add global version option
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current version.',
    );

    addCommand(CacheCommand());
    addCommand(CreateCommand());
    addCommand(DeepCleanCommand());
    addCommand(FormatAllCommand());
    addCommand(FormatDartdocCommand());
    addCommand(FormatCommentsCommand());
    addCommand(GuiCommand());
    addCommand(ScreenCommand());
    addCommand(SetupCommand());
    addCommand(SortEnumCommand());
    addCommand(SortL10nCommand());
    addCommand(TestCommand());
  }

  /// Override to provide custom help output.
  @override
  void printUsage() {
    final Logger logger = Logger();
    CustomHelp.showGeneralHelp(logger, this);
  }

  /// Reads the version from pubspec.yaml file.
  ///
  /// This method locates the pubspec.yaml file and extracts the version field
  /// to ensure the CLI always reports the correct version.
  ///
  /// Returns the version string from pubspec.yaml, or 'unknown' if the version
  /// cannot be determined due to file access issues or parsing errors.
  String _getVersionFromPubspec() {
    try {
      // Get the directory where the current script is located
      final String scriptPath = Platform.script.toFilePath();
      final String packageRoot = path.dirname(path.dirname(scriptPath));
      final String pubspecPath = path.join(packageRoot, 'pubspec.yaml');

      // Try to read the pubspec.yaml file
      final File pubspecFile = File(pubspecPath);
      if (!pubspecFile.existsSync()) {
        // If pubspec.yaml is not found in the expected location, try looking in
        // the current working directory
        final String currentDirPubspec = path.join(Directory.current.path, 'pubspec.yaml');
        final File currentPubspecFile = File(currentDirPubspec);
        if (currentPubspecFile.existsSync()) {
          final String content = currentPubspecFile.readAsStringSync();
          final YamlMap yaml = loadYaml(content) as YamlMap;
          return yaml['version']?.toString() ?? 'unknown';
        }

        return 'unknown';
      }

      final String content = pubspecFile.readAsStringSync();
      final YamlMap yaml = loadYaml(content) as YamlMap;

      return yaml['version']?.toString() ?? 'unknown';
    } catch (e) {
      // If any error occurs during file reading or parsing, return 'unknown'
      return 'unknown';
    }
  }

  /// Parses and executes the provided [args] using the registered subcommands.
  ///
  /// Returns a POSIX-style exit code:
  /// - `0`  on success,
  /// - `64` when the command usage is invalid (e.g., missing or bad arguments),
  /// - `1`  for any unexpected error.
  @override
  Future<int> run(Iterable<String> args) async {
    // Logger used for all user-facing output from the command runner.
    final Logger logger = Logger();

    try {
      // Parse arguments to check for global flags
      final ArgResults topLevelResults = parse(args.toList());

      // Handle version flag
      if (topLevelResults['version'] as bool) {
        final String version = _getVersionFromPubspec();
        logger.info('splendid_cli version $version');

        return 0;
      }

      // Check for custom help command pattern: help <command>
      if (args.isNotEmpty && args.first == 'help') {
        final List<String> argsList = args.toList();
        if (argsList.length > 1) {
          final String commandName = argsList[1];
          final bool success = CustomHelp.showCommandHelp(commandName, logger, this);
          return success ? 0 : 64;
        } else {
          // Just "help" with no command - show general help
          CustomHelp.showGeneralHelp(logger, this);

          return 0;
        }
      }

      // Execute the matched subcommand and may return an integer exit code or
      // `null` depending on the subcommand's contract.
      final Object? result = await runCommand(topLevelResults);

      // Normalize the result to a concrete exit code. If a subcommand does not
      // provide an int exit code, treat it as success (0) to keep behavior
      // consistent across commands.
      return result is int ? result : 0;
    } on UsageException catch (e) {
      // The user invoked the CLI incorrectly (bad flags, missing args, etc.).
      // Emit the error message followed by the generated usage/help text and
      // return the standard EX_USAGE (64) code.
      logger
        ..err(e.message)
        ..info(e.usage);

      return 64; // EX_USAGE
    } catch (error, stackTrace) {
      // Any other unexpected exception. Show a concise error plus a verbose
      // stack trace at the "detail" level to aid debugging without overwhelming
      // normal users.
      logger
        ..err('Unexpected error: $error')
        ..detail('$stackTrace');

      return 1; // Generic failure
    }
  }
}
