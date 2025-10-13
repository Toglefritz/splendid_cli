import 'integration/mcp_basic_test.dart' as integration_tests;
import 'src/mcp/mcp_server_test.dart' as server_tests;
import 'src/mcp/mcp_tool_registry_test.dart' as tool_registry_tests;

/// Comprehensive test suite for MCP (Model Context Protocol) functionality.
///
/// This file serves as a test runner for all MCP-related tests, providing
/// a single entry point to validate the complete MCP server implementation.
///
/// Test Coverage:
/// * Unit tests for MCP tool registry
/// * Unit tests for MCP server protocol handling
/// * Integration tests for complete MCP workflow
/// * Error handling and edge cases
/// * JSON-RPC communication validation
///
/// Run with: dart test test/mcp_test_suite.dart

void main() {
  // Run all MCP test suites
  tool_registry_tests.main();
  server_tests.main();
  integration_tests.main();
}
