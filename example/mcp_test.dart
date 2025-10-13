#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Example script demonstrating how to interact with the Splendid CLI MCP server.
///
/// This script shows how AI systems can programmatically use the CLI's functionality
/// through the MCP (Model Context Protocol) interface.
///
/// Run with: dart run examples/mcp_test.dart
// ignore_for_file: avoid_print, avoid_dynamic_calls
Future<void> main() async {
  print('🚀 Testing Splendid CLI MCP Server\n');

  // Test 1: Initialize the server
  print('1. Testing server initialization...');
  final Map<String, dynamic> initResponse = await sendMcpRequest(<String, dynamic>{
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'initialize',
    'params': <String, dynamic>{},
  });

  final dynamic initResult = initResponse['result'];
  if (initResult != null) {
    print('✅ Server initialized successfully');
    print('   Protocol version: ${initResult['protocolVersion']}');
    print('   Server: ${initResult['serverInfo']['name']}');
  } else {
    print('❌ Server initialization failed');
    return;
  }

  // Test 2: List available tools
  print('\n2. Testing tools/list...');
  final Map<String, dynamic> toolsResponse = await sendMcpRequest(<String, dynamic>{
    'jsonrpc': '2.0',
    'id': 2,
    'method': 'tools/list',
    'params': <String, dynamic>{},
  });

  final dynamic toolsResult = toolsResponse['result'];
  if (toolsResult != null) {
    final List<dynamic> tools = toolsResult['tools'] as List<dynamic>;
    print('✅ Found ${tools.length} available tools:');
    for (final dynamic tool in tools) {
      print('   • ${tool['name']}: ${tool['description']}');
    }
  } else {
    print('❌ Failed to list tools');
    return;
  }

  // Test 3: Try to create a project (this will fail without Flutter CLI, but shows the interface)
  print('\n3. Testing create_flutter_project tool...');
  final Map<String, dynamic> createResponse = await sendMcpRequest(<String, dynamic>{
    'jsonrpc': '2.0',
    'id': 3,
    'method': 'tools/call',
    'params': <String, dynamic>{
      'name': 'create_flutter_project',
      'arguments': <String, dynamic>{'name': 'test_mcp_project', 'platforms': 'android,ios', 'force': true},
    },
  });

  final dynamic createResult = createResponse['result'];
  if (createResult != null) {
    if (createResult['isError'] == true) {
      print('⚠️  Tool execution failed (expected without Flutter CLI):');
      print('   ${createResult['content'][0]['text']}');
    } else {
      print('✅ Project creation succeeded:');
      print('   ${createResult['content'][0]['text']}');
    }
  } else {
    print('❌ Tool call failed');
  }

  print('\n🎉 MCP Server test completed!');
  print('\nTo use this MCP server with AI systems:');
  print('1. Start the server: dart run bin/splendid_cli.dart --mcp-server');
  print('2. Configure your AI client to use this server');
  print('3. The AI can now create Flutter projects, add screens, and more!');
}

/// Sends an MCP request to the server and returns the response.
Future<Map<String, dynamic>> sendMcpRequest(Map<String, dynamic> request) async {
  // Start the MCP server process
  final process = await Process.start(
    'dart',
    ['run', 'bin/splendid_cli.dart', '--mcp-server'],
    workingDirectory: Directory.current.parent.path,
  );

  // Send the request
  process.stdin.writeln(jsonEncode(request));
  await process.stdin.close();

  // Read the response
  final responseLines = await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).toList();

  // Kill the process
  process.kill();

  // Parse the JSON response (skip any stderr output)
  for (final line in responseLines) {
    if (line.trim().startsWith('{')) {
      try {
        return jsonDecode(line) as Map<String, dynamic>;
      } catch (e) {
        // Continue to next line if JSON parsing fails
      }
    }
  }

  throw Exception('No valid JSON response received');
}
