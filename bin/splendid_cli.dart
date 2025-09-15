import 'package:splendid_cli/splendid_command_runner.dart';

/// CLI entrypoint for the Splendid CLI.
///
/// Delegates argument parsing and execution to the [SplendidCommandRunner], which manages all available subcommands.
Future<void> main(List<String> arguments) async {
  // The [SplendidCommandRunner] will manage CLI commands.
  final SplendidCommandRunner runner = SplendidCommandRunner();
  await runner.run(arguments);
}
