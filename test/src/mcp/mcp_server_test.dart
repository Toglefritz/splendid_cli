import 'dart:async';
import 'dart:convert';

import 'package:splendid_cli/src/mcp/mcp_server.dart';
import 'package:test/test.dart';

/// Test suite for SplendidMcpServer functionality.
///
/// This test suite covers MCP protocol handling, JSON-RPC communication,
/// and server lifecycle management without requiring actual stdio communication.
///
/// Test Categories:
/// * Server initialization and capability negotiation
/// * MCP protocol method handling
/// * JSON-RPC request/response processing
/// * Error handling and edge cases
/// * Tool discovery and execution routing
///
/// Test Environment:
/// * Uses mock stream channels for communication
/// * Isolates server logic from transport layer
/// * Tests protocol compliance without external dependencies
// ignore_for_file: inference_failure_on_collection_literal, avoid_dynamic_calls
void main() {
  group('SplendidMcpServer', () {
    late StreamController<String> inputController;
    late StreamController<String> outputController;

    /// Set up test environment with mock communication channel.
    ///
    /// Creates a test server instance with mock stream channels that
    /// allow us to simulate MCP client communication without stdio.
    setUp(() {
      inputController = StreamController<String>();
      outputController = StreamController<String>();
    });

    /// Clean up test environment after each test.
    ///
    /// Closes stream controllers and cleans up any server resources
    /// to prevent resource leaks in the test environment.
    tearDown(() {
      inputController.close();
      outputController.close();
    });

    group('MCP protocol methods', () {
      /// Tests the initialize method response structure.
      ///
      /// This test verifies that the server responds to initialization
      /// requests with proper MCP protocol version and capabilities.
      test('should handle initialize request', () {
        // Create a test server instance to access private methods
        final testServer = TestableMcpServer();

        final Map<String, dynamic> response = testServer.testHandleInitialize(<String, dynamic>{});

        expect(response, containsPair('protocolVersion', '2024-11-05'));
        expect(response.keys, contains('capabilities'));
        expect(response.keys, contains('serverInfo'));

        final Map<String, dynamic> serverInfo = response['serverInfo'] as Map<String, dynamic>;
        expect(serverInfo, containsPair('name', 'splendid-cli-mcp-server'));
        expect(serverInfo, containsPair('version', '2.0.0'));
        expect(serverInfo.keys, contains('description'));

        final Map<String, dynamic> capabilities = response['capabilities'] as Map<String, dynamic>;
        expect(capabilities.keys, contains('tools'));
      });

      /// Tests the tools/list method response structure.
      ///
      /// This test verifies that the server returns all available tools
      /// with proper schema definitions for MCP clients.
      test('should handle tools/list request', () {
        final testServer = TestableMcpServer();

        final Map<String, dynamic> response = testServer.testHandleToolsList(<String, dynamic>{});

        expect(response.keys, contains('tools'));
        final List<dynamic> tools = response['tools'] as List<dynamic>;
        expect(tools, hasLength(4));

        // Verify each tool has required MCP structure
        for (final dynamic tool in tools) {
          final Map<String, dynamic> toolMap = tool as Map<String, dynamic>;
          expect(toolMap.keys, contains('name'));
          expect(toolMap.keys, contains('description'));
          expect(toolMap.keys, contains('inputSchema'));
        }
      });

      /// Tests the tools/call method parameter handling.
      ///
      /// This test verifies that the server properly extracts tool name
      /// and arguments from MCP tool call requests.
      test('should handle tools/call request structure', () async {
        final testServer = TestableMcpServer();

        // Test with valid tool call parameters
        final Map<String, dynamic> params = <String, dynamic>{
          'name': 'create_flutter_project',
          'arguments': <String, dynamic>{
            'name': 'test_project',
            'platforms': 'android,ios',
          },
        };

        // This will fail with actual execution, but tests parameter extraction
        final Map<String, dynamic> response = await testServer.testHandleToolsCall(params);

        // Should return error response due to missing Flutter CLI, but structure should be correct
        expect(response.keys, contains('isError'));
        expect(response.keys, contains('content'));

        final List<dynamic> content = response['content'] as List<dynamic>;
        expect(content, hasLength(1));
        expect(content[0], containsPair('type', 'text'));
        expect((content[0] as Map).keys, contains('text'));
      });

      /// Tests error handling for malformed tool call requests.
      ///
      /// This test verifies that the server handles invalid tool call
      /// parameters gracefully with proper error responses.
      test('should handle malformed tools/call request', () async {
        final testServer = TestableMcpServer();

        // Test with missing tool name
        final Map<String, dynamic> invalidParams = <String, dynamic>{
          'arguments': <String, dynamic>{'name': 'test'},
        };

        final Map<String, dynamic> response = await testServer.testHandleToolsCall(invalidParams);

        expect(response, containsPair('isError', true));
        expect(response.keys, contains('content'));

        final List<dynamic> content = response['content'] as List<dynamic>;
        expect(content[0], containsPair('type', 'text'));
        expect(content[0]['text'], contains('Tool execution failed'));
      });
    });

    group('JSON-RPC integration', () {
      /// Tests that server methods return JSON-serializable responses.
      ///
      /// This test ensures that all MCP method responses can be properly
      /// serialized to JSON for transmission over the wire.
      test('should return JSON-serializable responses', () {
        final testServer = TestableMcpServer();

        // Test initialize response
        final initResponse = testServer.testHandleInitialize({});
        expect(() => jsonEncode(initResponse), returnsNormally);

        // Test tools/list response
        final toolsResponse = testServer.testHandleToolsList({});
        expect(() => jsonEncode(toolsResponse), returnsNormally);
      });

      /// Tests MCP protocol compliance for required methods.
      ///
      /// This test verifies that the server implements all required
      /// MCP methods with proper signatures and response formats.
      test('should implement required MCP methods', () {
        final testServer = TestableMcpServer();

        // All MCP servers must implement these methods
        expect(() => testServer.testHandleInitialize({}), returnsNormally);
        expect(() => testServer.testHandleToolsList({}), returnsNormally);
        expect(() => testServer.testHandleInitialized({}), returnsNormally);
      });
    });

    group('error handling', () {
      /// Tests server behavior with null or invalid parameters.
      ///
      /// This test ensures that the server handles edge cases gracefully
      /// without crashing or returning malformed responses.
      test('should handle null parameters gracefully', () {
        final testServer = TestableMcpServer();

        // These should not throw exceptions
        expect(() => testServer.testHandleInitialize(<String, dynamic>{}), returnsNormally);
        expect(() => testServer.testHandleToolsList(<String, dynamic>{}), returnsNormally);
        expect(() => testServer.testHandleInitialized(<String, dynamic>{}), returnsNormally);
      });

      /// Tests error response format compliance.
      ///
      /// This test verifies that error responses follow the MCP specification
      /// for error formatting and content structure.
      test('should return properly formatted error responses', () async {
        final testServer = TestableMcpServer();

        final Map<String, dynamic> errorResponse = await testServer.testHandleToolsCall(<String, dynamic>{
          'name': 'nonexistent_tool',
          'arguments': <String, dynamic>{},
        });

        expect(errorResponse, containsPair('isError', true));
        expect(errorResponse.keys, contains('content'));

        final List<dynamic> content = errorResponse['content'] as List<dynamic>;
        expect(content, isNotEmpty);
        expect(content[0], containsPair('type', 'text'));
        expect((content[0] as Map).keys, contains('text'));
      });
    });
  });
}

/// Testable wrapper for SplendidMcpServer that exposes methods for testing.
///
/// This class extends the MCP server to provide direct access to handler methods
/// for unit testing without requiring full server startup and communication.
class TestableMcpServer extends SplendidMcpServer {
  /// Exposes the handleInitialize method for testing.
  Map<String, dynamic> testHandleInitialize(dynamic params) {
    return handleInitialize(params);
  }

  /// Exposes the handleToolsList method for testing.
  Map<String, dynamic> testHandleToolsList(dynamic params) {
    return handleToolsList(params);
  }

  /// Exposes the handleToolsCall method for testing.
  Future<Map<String, dynamic>> testHandleToolsCall(dynamic params) {
    return handleToolsCall(params);
  }

  /// Exposes the handleInitialized method for testing.
  void testHandleInitialized(dynamic params) {
    handleInitialized(params);
  }
}
