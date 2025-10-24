import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import '../helpers/project_cleanup_helper.dart';

/// Basic integration tests for MCP server functionality.
///
/// These tests verify that the MCP server can start, respond to basic requests, and handle the core protocol flow
/// without requiring external dependencies.
// ignore_for_file: avoid_dynamic_calls, inference_failure_on_collection_literal
void main() {
  group('MCP Basic Integration', () {
    /// Set up automatic cleanup for test artifacts.
    ///
    /// This ensures that any test projects created at the root level during MCP server testing are automatically
    /// cleaned up.
    setUpAll(ProjectCleanupHelper.setupAutomaticCleanup);

    /// Clean up any test artifacts created during MCP testing.
    ///
    /// This removes any directories that may have been created at the project root level during MCP server command
    /// execution.
    tearDownAll(ProjectCleanupHelper.cleanupTestArtifacts);

    /// Tests that the server can initialize properly.
    test('should initialize successfully', () async {
      final Map<String, dynamic> response = await _sendMcpRequest({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      });

      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(1));
      expect(response['result'], isA<Map<String, dynamic>>());

      final result = response['result'] as Map<String, dynamic>;
      expect(result['protocolVersion'], equals('2024-11-05'));
      expect(result['serverInfo']['name'], equals('splendid-cli-mcp-server'));
    });

    /// Tests that the server can list tools.
    test('should list available tools', () async {
      final Map<String, dynamic> response = await _sendMcpRequest({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
        'params': {},
      });

      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(2));
      expect(response['result'], isA<Map<String, dynamic>>());

      final result = response['result'] as Map<String, dynamic>;
      final tools = result['tools'] as List<dynamic>;
      expect(tools, hasLength(4));

      final List<dynamic> toolNames = tools.map((dynamic tool) => tool['name']).toList();
      expect(toolNames, contains('create_flutter_project'));
      expect(toolNames, contains('add_flutter_screen'));
      expect(toolNames, contains('setup_flutter_project'));
      expect(toolNames, contains('generate_test_template'));
    });

    /// Tests that the server handles unknown tools gracefully.
    test('should handle unknown tool', () async {
      final Map<String, dynamic> response = await _sendMcpRequest({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {'name': 'unknown_tool', 'arguments': {}},
      });

      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(3));
      expect(response['result'], isA<Map<String, dynamic>>());

      final result = response['result'] as Map<String, dynamic>;
      expect(result['isError'], equals(true));
      expect(result['content'], isA<List<dynamic>>());
      expect(result['content'][0]['text'], contains('Unknown tool'));
    });
  });
}

/// Sends an MCP request to the server and returns the parsed response.
Future<Map<String, dynamic>> _sendMcpRequest(Map<String, dynamic> request) async {
  final Process process = await Process.start(
    'dart',
    ['run', 'bin/splendid_cli.dart', '--mcp-server'],
  );

  try {
    // Send the request
    process.stdin.writeln(jsonEncode(request));
    await process.stdin.close();

    // Wait for response with timeout
    final String response = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .firstWhere(
          (line) => line.trim().startsWith('{'),
          orElse: () => throw Exception('No JSON response received'),
        )
        .timeout(const Duration(seconds: 10));

    // Parse and return the response
    return jsonDecode(response) as Map<String, dynamic>;
  } finally {
    // Always clean up the process
    process.kill();
    await process.exitCode;
  }
}
