# Splendid CLI Examples

This directory contains examples demonstrating different ways to use and integrate with the Splendid CLI.

## GUI Dashboard

The `gui_dashboard/` directory contains a complete Flutter desktop application that provides a graphical interface for all Splendid CLI functionality.

### Features
- Visual project creation wizard
- Screen generation interface
- Test file generation tools
- Real-time command output
- File browser integration
- Cross-platform desktop support

### Usage
```bash
# Launch the GUI dashboard
splendid_cli gui

# Launch for specific project
splendid_cli gui --project-path /path/to/project
```

See [gui_dashboard/README.md](gui_dashboard/README.md) for detailed documentation.

## MCP Server Integration

The `mcp_test.dart` script demonstrates how to interact with the Splendid CLI's MCP (Model Context Protocol) server functionality.

### Features
- Server initialization and tool discovery
- Programmatic project creation
- Screen and test generation
- Integration with AI development tools

### Usage
```bash
# Run the MCP test script
dart run example/mcp_test.dart

# Start the MCP server
dart run bin/splendid_cli.dart --mcp-server
```

## Integration Examples

Both examples show different approaches to integrating with Splendid CLI:

1. **GUI Dashboard**: Human-friendly visual interface for interactive use
2. **MCP Server**: Machine-friendly API for programmatic integration with AI tools

These examples demonstrate the flexibility of the Splendid CLI architecture and provide starting points for building custom integrations.