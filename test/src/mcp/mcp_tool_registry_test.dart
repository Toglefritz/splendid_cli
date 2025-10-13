import 'package:splendid_cli/src/mcp/mcp_tool_registry.dart';
import 'package:splendid_cli/src/services/project_service.dart';
import 'package:splendid_cli/src/services/screen_service.dart';
import 'package:splendid_cli/src/services/test_service.dart';
import 'package:test/test.dart';

/// Test suite for McpToolRegistry functionality.
///
/// This test suite covers tool registration, schema validation, and tool execution
/// routing without requiring external dependencies like Flutter CLI or file system
/// operations.
///
/// Test Categories:
/// * Tool registration and discovery
/// * Schema validation and structure
/// * Tool execution routing
/// * Error handling for invalid tools
/// * Parameter validation and conversion
// ignore_for_file: document_ignores
void main() {
  group('McpToolRegistry', () {
    late McpToolRegistry toolRegistry;
    late ProjectService projectService;
    late ScreenService screenService;
    late TestService testService;

    /// Set up test dependencies and registry instance.
    ///
    /// Creates fresh service instances for each test to ensure isolation.
    /// Services are real instances but will be tested with mock data.
    setUp(() {
      projectService = ProjectService();
      screenService = ScreenService();
      testService = TestService();

      toolRegistry = McpToolRegistry(
        projectService: projectService,
        screenService: screenService,
        testService: testService,
      );
    });

    group('tool registration', () {
      /// Verifies that all expected tools are registered and discoverable.
      ///
      /// This test ensures that the tool registry exposes all CLI functionality
      /// as MCP tools with proper naming and structure.
      test('should register all expected tools', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();

        expect(tools, hasLength(4));

        final List<String> toolNames = tools.map((tool) => tool['name'] as String).toList();
        expect(
          toolNames,
          containsAll([
            'create_flutter_project',
            'add_flutter_screen',
            'setup_flutter_project',
            'generate_test_template',
          ]),
        );
      });

      /// Verifies that each tool has the required MCP tool structure.
      ///
      /// This test ensures that all tools conform to the MCP specification
      /// with proper name, description, and input schema.
      test('should have valid tool structure', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();

        for (final Map<String, dynamic> tool in tools) {
          // Each tool must have required fields
          expect(tool, containsPair('name', isA<String>()));
          expect(tool, containsPair('description', isA<String>()));
          expect(tool, containsPair('inputSchema', isA<Map<String, dynamic>>()));

          // Input schema must be valid JSON Schema
          final Map<String, dynamic> schema = tool['inputSchema'] as Map<String, dynamic>;
          expect(schema, containsPair('type', 'object'));
          expect(schema, containsPair('properties', isA<Map<String, dynamic>>()));
          expect(schema, containsPair('required', isA<List<dynamic>>()));
        }
      });
    });

    group('create_flutter_project tool', () {
      /// Verifies the create_flutter_project tool schema and structure.
      ///
      /// This test ensures that the project creation tool has the correct
      /// parameters, validation rules, and default values.
      test('should have correct schema', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();
        final Map<String, dynamic> createTool = tools.firstWhere(
          (tool) => tool['name'] == 'create_flutter_project',
        );

        expect(createTool['description'], contains('MVC architecture'));

        final Map<String, dynamic> schema = createTool['inputSchema'] as Map<String, dynamic>;
        final Map<String, dynamic> properties = schema['properties'] as Map<String, dynamic>;

        // Required name parameter
        expect(properties.keys, contains('name'));
        expect(properties['name'], containsPair('type', 'string'));
        expect((properties['name'] as Map).keys, contains('pattern')); // Dart package name validation

        // Optional parameters with defaults
        expect(properties.keys, contains('platforms'));
        expect(properties['platforms'], containsPair('default', 'android,ios,web,windows,macos,linux'));

        expect(properties.keys, contains('force'));
        expect(properties['force'], containsPair('default', false));

        // Required fields
        final List<String> required = (schema['required'] as List<dynamic>).cast<String>();
        expect(required, contains('name'));
      });

      /// Tests tool execution routing for project creation.
      ///
      /// This test verifies that the tool registry correctly routes
      /// create_flutter_project calls to the project service and returns
      /// proper MCP error responses when the service fails.
      test('should route to project service', () async {
        final Map<String, dynamic> result = await toolRegistry.executeTool('create_flutter_project', {
          'name': 'test_project',
        });

        // Get the content of the result.
        final List<Map<String, dynamic>> content = result['content'] as List<Map<String, dynamic>>;

        // Should return MCP error response format
        expect(result, containsPair('isError', true));
        expect(result.keys, contains('content'));
        expect(content, isA<List<Map<String, dynamic>>>());
        expect(content[0], containsPair('type', 'text'));
        expect(content[0]['text'], contains('Project creation failed'));
      });
    });

    group('add_flutter_screen tool', () {
      /// Verifies the add_flutter_screen tool schema and structure.
      ///
      /// This test ensures that the screen creation tool has the correct
      /// parameters for screen name, project path, and force flag.
      test('should have correct schema', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();
        final Map<String, dynamic> screenTool = tools.firstWhere(
          (tool) => tool['name'] == 'add_flutter_screen',
        );

        expect(screenTool['description'], contains('MVC architecture'));

        final Map<String, dynamic> schema = screenTool['inputSchema'] as Map<String, dynamic>;
        final Map<String, dynamic> properties = schema['properties'] as Map<String, dynamic>;

        // Required name parameter
        expect(properties.keys, contains('name'));
        expect(properties['name'], containsPair('type', 'string'));
        expect((properties['name'] as Map).keys, contains('pattern')); // Dart identifier validation

        // Optional parameters with defaults
        expect(properties.keys, contains('projectPath'));
        expect(properties['projectPath'], containsPair('default', '.'));

        expect(properties.keys, contains('force'));
        expect(properties['force'], containsPair('default', false));

        // Required fields
        final List<String> required = (schema['required'] as List<dynamic>).cast<String>();
        expect(required, contains('name'));
      });
    });

    group('setup_flutter_project tool', () {
      /// Verifies the setup_flutter_project tool schema and structure.
      ///
      /// This test ensures that the project setup tool has the correct
      /// parameters for project path, run app flag, and verbose flag.
      test('should have correct schema', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();
        final Map<String, dynamic> setupTool = tools.firstWhere(
          (tool) => tool['name'] == 'setup_flutter_project',
        );

        expect(setupTool['description'], contains('pub get'));

        final Map<String, dynamic> schema = setupTool['inputSchema'] as Map<String, dynamic>;
        final Map<String, dynamic> properties = schema['properties'] as Map<String, dynamic>;

        // All parameters are optional for setup
        expect(properties.keys, contains('projectPath'));
        expect(properties['projectPath'], containsPair('default', '.'));

        expect(properties.keys, contains('runApp'));
        expect(properties['runApp'], containsPair('default', false)); // False for MCP

        expect(properties.keys, contains('verbose'));
        expect(properties['verbose'], containsPair('default', false));

        // No required fields
        final List<String> required = (schema['required'] as List<dynamic>).cast<String>();
        expect(required, isEmpty);
      });
    });

    group('generate_test_template tool', () {
      /// Verifies the generate_test_template tool schema and structure.
      ///
      /// This test ensures that the test generation tool has the correct
      /// parameters for target file, output directory, test type, and force flag.
      test('should have correct schema', () {
        final List<Map<String, dynamic>> tools = toolRegistry.getAllTools();
        final Map<String, dynamic> testTool = tools.firstWhere(
          (tool) => tool['name'] == 'generate_test_template',
        );

        expect(testTool['description'], contains('test file templates'));

        final Map<String, dynamic> schema = testTool['inputSchema'] as Map<String, dynamic>;
        final Map<String, dynamic> properties = schema['properties'] as Map<String, dynamic>;

        // Required targetFile parameter
        expect(properties.keys, contains('targetFile'));
        expect(properties['targetFile'], containsPair('type', 'string'));

        // Optional parameters
        expect(properties.keys, contains('testType'));
        expect(properties['testType'], containsPair('default', 'auto'));
        expect((properties['testType'] as Map).keys, contains('enum'));

        // ignore: avoid_dynamic_calls
        final List<String> testTypes = (properties['testType']['enum'] as List<dynamic>).cast<String>();
        expect(testTypes, containsAll(['auto', 'widget', 'class']));

        // Required fields
        final List<String> required = (schema['required'] as List<dynamic>).cast<String>();
        expect(required, contains('targetFile'));
      });
    });

    group('error handling', () {
      /// Tests error handling for unknown tool names.
      ///
      /// This test ensures that the tool registry properly handles
      /// requests for non-existent tools with clear error messages.
      test('should throw error for unknown tool', () async {
        expect(
          () => toolRegistry.executeTool('unknown_tool', {}),
          throwsA(isA<ArgumentError>()),
        );
      });

      /// Tests parameter validation and error handling.
      ///
      /// This test verifies that tools properly validate their parameters
      /// and provide meaningful error messages for invalid input.
      test('should handle invalid parameters gracefully', () async {
        // Test with missing required parameter
        final Map<String, dynamic> result = await toolRegistry.executeTool('create_flutter_project', {});

        // Get the content of the result.
        final List<Map<String, dynamic>> content = result['content'] as List<Map<String, dynamic>>;

        // Should return MCP error response format
        expect(result, containsPair('isError', true));
        expect(result.keys, contains('content'));
        expect(content, isA<List<Map<String, dynamic>>>());
        expect(content[0], containsPair('type', 'text'));
      });
    });

    group('tool execution routing', () {
      /// Verifies that tool execution is routed to the correct service.
      ///
      /// This test ensures that each tool name maps to the appropriate
      /// service method call and returns proper MCP error responses.
      test('should route tools to correct services', () async {
        final List<String> toolNames = [
          'create_flutter_project',
          'add_flutter_screen',
          'setup_flutter_project',
        ];

        for (final String toolName in toolNames) {
          final Map<String, dynamic> result = await toolRegistry.executeTool(toolName, {'name': 'test'});

          // Get the content of the result.
          final List<Map<String, dynamic>> content = result['content'] as List<Map<String, dynamic>>;

          // Should return MCP error response format (since services will fail)
          expect(result, containsPair('isError', true));
          expect(result.keys, contains('content'));
          expect(content, isA<List<Map<String, dynamic>>>());
          expect(content[0], containsPair('type', 'text'));
        }

        // Test generate_test_template separately since it needs targetFile
        final Map<String, dynamic> testResult = await toolRegistry.executeTool('generate_test_template', {
          'targetFile': 'nonexistent.dart',
        });

        expect(testResult, containsPair('isError', true));
        expect(testResult.keys, contains('content'));
      });
    });
  });
}
