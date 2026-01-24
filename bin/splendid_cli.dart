import 'dart:io';
import 'package:splendid_cli/splendid_cli.dart';

/// CLI entrypoint for the Splendid CLI.
///
/// Supports two modes of operation:
/// 1. CLI mode (default): Delegates argument parsing and execution to
/// [SplendidCommandRunner]
/// 2. MCP server mode: Starts an MCP server when --mcp-server flag is provided
///
/// MCP (Model Context Protocol) server mode allows AI systems to
/// programmatically use the CLI's functionality through a standardized
/// protocol.
Future<void> main(List<String> arguments) async {
  // Check if MCP server mode is requested
  if (arguments.contains('--mcp-server')) {
    // Start MCP server mode
    final SplendidMcpServer mcpServer = SplendidMcpServer();
    await mcpServer.start();

    return;
  }

  // Default CLI mode
  final SplendidCommandRunner runner = SplendidCommandRunner();
  final int code = await runner.run(arguments);
  exit(code);
}
