import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../services/project_service.dart';
import '../services/screen_service.dart';
import '../services/test_service.dart';
import 'mcp_tool_registry.dart';

/// MCP (Model Context Protocol) server for Splendid CLI.
///
/// This server exposes the CLI's functionality as MCP tools that can be used
/// by AI systems. It implements the MCP specification over stdio transport,
/// allowing AI models to programmatically create Flutter projects, add screens,
/// generate tests, and setup projects.
///
/// The server follows the MCP protocol specification:
/// 1. Initialization handshake with capability negotiation
/// 2. Tool discovery via tools/list
/// 3. Tool execution via tools/call
/// 4. Proper error handling and response formatting
///
/// Usage:
/// ```dart
/// final SplendidMcpServer server = SplendidMcpServer();
/// await server.start();
/// ```
///
/// The server runs indefinitely, processing MCP requests until terminated.
class SplendidMcpServer {
  /// Service for project creation and setup operations.
  static const ProjectService _projectService = ProjectService();

  /// Service for screen generation operations.
  static const ScreenService _screenService = ScreenService();

  /// Service for test generation operations.
  static const TestService _testService = TestService();

  /// Registry of available MCP tools.
  late final McpToolRegistry _toolRegistry;

  /// JSON-RPC server instance for handling MCP communication.
  late final Server _rpcServer;

  /// Creates a new MCP server instance.
  ///
  /// Initializes the tool registry with available services and prepares
  /// the JSON-RPC server for communication.
  SplendidMcpServer() {
    _toolRegistry = McpToolRegistry(
      projectService: _projectService,
      screenService: _screenService,
      testService: _testService,
    );
  }

  /// Starts the MCP server and begins listening for requests.
  ///
  /// This method:
  /// 1. Sets up stdio transport for communication
  /// 2. Registers MCP protocol methods
  /// 3. Starts the JSON-RPC server
  /// 4. Runs indefinitely until terminated
  ///
  /// The server communicates over stdin/stdout using JSON-RPC 2.0,
  /// which is the standard transport for MCP servers.
  ///
  /// Throws:
  /// * [StateError] if the server is already running
  /// * [IOException] if stdio communication fails
  Future<void> start() async {
    try {
      // Create stdio transport channel
      final StreamChannel<String> channel = _createStdioChannel();

      // Create JSON-RPC server
      _rpcServer = Server(channel);

      // Register MCP protocol methods
      _registerMcpMethods();

      // Start listening for requests
      await _rpcServer.listen();
    } catch (error) {
      stderr.writeln('MCP Server failed to start: $error');
      exit(1);
    }
  }

  /// Creates a stdio-based stream channel for MCP communication.
  ///
  /// This channel allows the MCP server to communicate with AI clients
  /// through standard input/output streams. The AI client typically
  /// spawns this process and communicates via pipes.
  ///
  /// Returns:
  /// * `StreamChannel<String>` configured for stdio communication
  StreamChannel<String> _createStdioChannel() {
    // Transform byte streams to string streams
    final Stream<String> inputStream = stdin.transform(utf8.decoder).transform(const LineSplitter());

    // Create a simple string sink that writes to stdout
    final StreamController<String> outputController = StreamController<String>();
    outputController.stream.listen((String line) {
      stdout.writeln(line);
    });

    return StreamChannel(inputStream, outputController.sink);
  }

  /// Registers MCP protocol methods with the JSON-RPC server.
  ///
  /// This method sets up handlers for the core MCP methods:
  /// * `initialize` - Server initialization and capability negotiation
  /// * `tools/list` - Returns available tools
  /// * `tools/call` - Executes a specific tool
  ///
  /// Each method follows the MCP specification for request/response format.
  void _registerMcpMethods() {
    // Initialize method - required by MCP spec
    _rpcServer
      ..registerMethod('initialize', handleInitialize)
      // Tools methods - core MCP functionality
      ..registerMethod('tools/list', handleToolsList)
      ..registerMethod('tools/call', handleToolsCall)
      // Notifications (optional)
      ..registerMethod('initialized', handleInitialized);
  }

  /// Handles the MCP initialize request.
  ///
  /// This is the first method called by MCP clients to establish
  /// communication and negotiate capabilities. The server responds
  /// with its capabilities and protocol version.
  ///
  /// Parameters:
  /// * [params] - Initialization parameters from the client
  ///
  /// Returns:
  /// * Map containing server capabilities and information
  @visibleForTesting
  Map<String, dynamic> handleInitialize(Object? params) {
    return <String, dynamic>{
      'protocolVersion': '2024-11-05',
      'capabilities': <String, dynamic>{
        'tools': <String, dynamic>{
          'listChanged': false, // Our tools don't change dynamically
        },
      },
      'serverInfo': <String, dynamic>{
        'name': 'splendid-cli-mcp-server',
        'version': '2.0.0',
        'description': 'MCP server for Splendid CLI - Flutter project scaffolding with MVC architecture',
      },
    };
  }

  /// Handles the initialized notification.
  ///
  /// This notification is sent by the client after successful initialization.
  /// We don't need to do anything special here, but it's part of the MCP spec.
  ///
  /// Parameters:
  /// * [params] - Notification parameters (usually empty)
  @visibleForTesting
  void handleInitialized(Object? params) {
    // Initialization complete - server is ready
    stderr.writeln('MCP Server initialized and ready');
  }

  /// Handles the tools/list request.
  ///
  /// Returns a list of all available tools that AI clients can use.
  /// Each tool includes its name, description, and input schema for
  /// parameter validation.
  ///
  /// Parameters:
  /// * [params] - Request parameters (usually empty for tools/list)
  ///
  /// Returns:
  /// * Map containing the list of available tools
  @visibleForTesting
  Map<String, dynamic> handleToolsList(Object? params) {
    return <String, dynamic>{
      'tools': _toolRegistry.getAllTools(),
    };
  }

  /// Handles the tools/call request.
  ///
  /// Executes a specific tool with the provided arguments and returns
  /// the result. This is where the actual CLI functionality is invoked.
  ///
  /// Parameters:
  /// * [params] - Tool execution parameters including name and arguments
  ///
  /// Returns:
  /// * `Future<Map<String, dynamic>>` containing the tool execution result
  @visibleForTesting
  Future<Map<String, dynamic>> handleToolsCall(Object? params) async {
    try {
      // Extract parameters safely - json_rpc_2 passes Parameters object or Map
      String toolName;
      Map<String, dynamic> arguments;

      if (params == null) {
        throw ArgumentError('Missing required parameters for tool call');
      }

      // Handle both Parameters object and direct Map cases
      Map<String, dynamic> paramsMap;
      if (params is Map<String, dynamic>) {
        paramsMap = params;
      } else {
        // Try to access as Parameters object with indexer
        try {
          final Object? nameParam = (params as dynamic)['name'];
          final Object? argsParam = (params as dynamic)['arguments'];

          paramsMap = <String, dynamic>{
            'name': nameParam,
            'arguments': argsParam,
          };
        } catch (e) {
          throw ArgumentError('Invalid parameter format: expected Map or Parameters object');
        }
      }

      // Extract tool name
      final Object? nameValue = paramsMap['name'];
      if (nameValue == null) {
        throw ArgumentError('Missing required parameter: name');
      }

      // Handle Parameters object value extraction
      if (nameValue is String) {
        toolName = nameValue;
      } else {
        // Try to extract value from Parameters object
        try {
          final String? extractedName = (nameValue as dynamic).value as String?;
          if (extractedName == null) {
            throw ArgumentError('Tool name cannot be null');
          }
          toolName = extractedName;
        } catch (e) {
          throw ArgumentError('Invalid tool name format: expected String');
        }
      }

      // Extract arguments
      final Object? argsValue = paramsMap['arguments'];
      if (argsValue == null) {
        arguments = <String, dynamic>{};
      } else if (argsValue is Map<String, dynamic>) {
        arguments = argsValue;
      } else {
        // Try to extract value from Parameters object
        try {
          final Map<String, dynamic>? extractedArgs = (argsValue as dynamic).value as Map<String, dynamic>?;
          arguments = extractedArgs ?? <String, dynamic>{};
        } catch (e) {
          throw ArgumentError('Invalid arguments format: expected Map<String, dynamic>');
        }
      }

      // Execute the tool through the registry
      final Map<String, dynamic> result = await _toolRegistry.executeTool(toolName, arguments);

      return result;
    } catch (error) {
      // Return MCP-formatted error response
      return <String, dynamic>{
        'isError': true,
        'content': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'text',
            'text': 'Tool execution failed: $error',
          },
        ],
      };
    }
  }
}
