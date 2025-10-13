# MCP Server Usage Guide

## Overview

The Splendid CLI includes an MCP (Model Context Protocol) server that allows AI systems to programmatically use the CLI's functionality. This enables AI assistants to create Flutter projects, add screens, generate tests, and setup projects through a standardized protocol.

## Starting the MCP Server

To start the MCP server, use the `--mcp-server` flag:

```bash
dart run bin/splendid_cli.dart --mcp-server
```

The server will start and listen for JSON-RPC 2.0 requests over stdin/stdout.

## Available Tools

The MCP server exposes four main tools:

### 1. create_flutter_project

Creates a new Flutter project with MVC architecture.

**Parameters:**
- `name` (required): Project name (must be valid Dart package name)
- `outputDirectory` (optional): Custom output directory
- `platforms` (optional): Comma-separated platforms (default: all platforms)
- `force` (optional): Overwrite existing directories (default: false)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "create_flutter_project",
    "arguments": {
      "name": "my_awesome_app",
      "platforms": "android,ios,web",
      "force": true
    }
  }
}
```

### 2. add_flutter_screen

Adds a new screen with MVC architecture to an existing Flutter project.

**Parameters:**
- `name` (required): Screen name (must be valid Dart identifier)
- `projectPath` (optional): Path to Flutter project (default: current directory)
- `force` (optional): Overwrite existing screen files (default: false)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "add_flutter_screen",
    "arguments": {
      "name": "UserProfile",
      "projectPath": "./my_app",
      "force": false
    }
  }
}
```

### 3. setup_flutter_project

Sets up a Flutter project by running necessary commands.

**Parameters:**
- `projectPath` (optional): Path to Flutter project (default: current directory)
- `runApp` (optional): Whether to run the app after setup (default: false)
- `verbose` (optional): Enable verbose output (default: false)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "setup_flutter_project",
    "arguments": {
      "projectPath": "./my_app",
      "runApp": false,
      "verbose": true
    }
  }
}
```

### 4. generate_test_template

Generates test file templates for Dart classes and Flutter widgets.

**Parameters:**
- `targetFile` (required): Path to the Dart file to generate tests for
- `outputDirectory` (optional): Custom output directory for test file
- `testType` (optional): Type of test ("auto", "widget", "class") (default: "auto")
- `force` (optional): Overwrite existing test files (default: false)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "tools/call",
  "params": {
    "name": "generate_test_template",
    "arguments": {
      "targetFile": "lib/services/api_service.dart",
      "testType": "class",
      "force": true
    }
  }
}
```

## MCP Protocol Flow

### 1. Initialization

First, initialize the server:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {}
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {
        "listChanged": false
      }
    },
    "serverInfo": {
      "name": "splendid-cli-mcp-server",
      "version": "2.0.0",
      "description": "MCP server for Splendid CLI - Flutter project scaffolding with MVC architecture"
    }
  },
  "id": 1
}
```

### 2. List Available Tools

Get all available tools:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list",
  "params": {}
}
```

### 3. Execute Tools

Call any tool using the `tools/call` method with the tool name and arguments.

## Integration with AI Systems

### Claude Desktop

To use with Claude Desktop, add this to your MCP configuration:

```json
{
  "mcpServers": {
    "splendid-cli": {
      "command": "dart",
      "args": ["run", "/path/to/splendid_cli/bin/splendid_cli.dart", "--mcp-server"],
      "env": {}
    }
  }
}
```

### Other AI Systems

Any AI system that supports MCP can use this server by:

1. Starting the server process with `--mcp-server` flag
2. Communicating via stdin/stdout using JSON-RPC 2.0
3. Following the MCP protocol specification

## Error Handling

The server returns structured error responses:

```json
{
  "jsonrpc": "2.0",
  "result": {
    "isError": true,
    "content": [
      {
        "type": "text",
        "text": "Error message describing what went wrong"
      }
    ]
  },
  "id": 1
}
```

## Benefits for AI-Driven Development

With the MCP server, AI systems can:

1. **Automatically scaffold Flutter projects** based on natural language descriptions
2. **Generate consistent MVC architecture** following established patterns
3. **Add screens and features** to existing projects
4. **Set up development environments** with proper dependencies
5. **Generate comprehensive test templates** for better code quality

This enables powerful AI-driven Flutter development workflows while maintaining code quality and architectural consistency.