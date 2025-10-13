import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'src/commands/create_command.dart';
import 'src/commands/screen_command.dart';
import 'src/commands/setup_command.dart';
import 'src/commands/test_command.dart';
import 'src/utils/custom_help.dart';

// Export MCP server components
export 'src/mcp/mcp_server.dart';
export 'src/mcp/mcp_tool_registry.dart';

// Export services for external use
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
    addCommand(CreateCommand());
    addCommand(ScreenCommand());
    addCommand(SetupCommand());
    addCommand(TestCommand());
  }

  /// Override to provide custom help output.
  @override
  void printUsage() {
    final Logger logger = Logger();
    CustomHelp.showGeneralHelp(logger, this);
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

      // Parse the raw [args] into a concrete Command instance + its options. `runCommand` executes the matched
      // subcommand and may return an integer exit code or `null` depending on the subcommand's contract.
      final Object? result = await runCommand(parse(args.toList()));

      // Normalize the result to a concrete exit code. If a subcommand does not provide an int exit code, treat it as
      // success (0) to keep behavior consistent across commands.
      return result is int ? result : 0;
    } on UsageException catch (e) {
      // The user invoked the CLI incorrectly (bad flags, missing args, etc.).  Emit the error message followed by
      // the generated usage/help text and return the standard EX_USAGE (64) code.
      logger
        ..err(e.message)
        ..info(e.usage);

      return 64; // EX_USAGE
    } catch (error, stackTrace) {
      // Any other unexpected exception. Show a concise error plus a verbose stack trace at the "detail" level to aid
      // debugging without overwhelming normal users.
      logger
        ..err('Unexpected error: $error')
        ..detail('$stackTrace');

      return 1; // Generic failure
    }
  }
}
