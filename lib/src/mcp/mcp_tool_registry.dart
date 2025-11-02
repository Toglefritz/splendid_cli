import '../services/project_service.dart';
import '../services/project_service/project_creation_request.dart';
import '../services/project_service/project_service_exception.dart';
import '../services/project_service/project_setup_request.dart';
import '../services/screen_service.dart';
import '../services/test_service.dart';
import '../services/test_service/test_generation_request.dart';
import '../services/test_service/test_service_exception.dart';
import '../services/test_service/test_type.dart';

/// Registry for MCP tools that maps CLI functionality to MCP tool definitions.
///
/// This class serves as the bridge between the MCP protocol and our CLI services. It defines the available tools, their
/// schemas, and handles execution by translating MCP requests into service calls.
///
/// Each tool corresponds to a major CLI command:
/// * `create_flutter_project` - Creates new Flutter projects
/// * `add_flutter_screen` - Adds screens to existing projects
/// * `setup_flutter_project` - Sets up project dependencies
/// * `generate_test_template` - Generates test files
class McpToolRegistry {
  /// Service for project operations.
  final ProjectService _projectService;

  /// Service for screen operations.
  final ScreenService _screenService;

  /// Service for test operations.
  final TestService _testService;

  /// Creates a new tool registry with the required services.
  McpToolRegistry({
    required ProjectService projectService,
    required ScreenService screenService,
    required TestService testService,
  }) : _projectService = projectService,
       _screenService = screenService,
       _testService = testService;

  /// Returns all available MCP tools with their definitions.
  ///
  /// Each tool definition includes:
  /// * `name` - Unique identifier for the tool
  /// * `description` - Human-readable description of what the tool does
  /// * `inputSchema` - JSON Schema defining the expected parameters
  ///
  /// The schemas are used by AI clients for parameter validation and to understand what arguments each tool expects.
  List<Map<String, dynamic>> getAllTools() {
    return [
      _createFlutterProjectTool(),
      _addFlutterScreenTool(),
      _setupFlutterProjectTool(),
      _generateTestTemplateTool(),
    ];
  }

  /// Executes a tool with the given arguments.
  ///
  /// This method routes tool execution to the appropriate service based on the tool name and converts the service
  /// response to MCP format.
  ///
  /// Parameters:
  /// * [toolName] - Name of the tool to execute
  /// * [arguments] - Arguments to pass to the tool
  ///
  /// Returns:
  /// * `Future<Map<String, dynamic>>` containing the MCP-formatted result
  ///
  /// Throws:
  /// * [ArgumentError] if the tool name is not recognized
  Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'create_flutter_project':
        return _executeCreateProject(arguments);
      case 'add_flutter_screen':
        return _executeAddScreen(arguments);
      case 'setup_flutter_project':
        return _executeSetupProject(arguments);
      case 'generate_test_template':
        return _executeGenerateTest(arguments);
      default:
        throw ArgumentError('Unknown tool: $toolName');
    }
  }

  /// Defines the create_flutter_project tool.
  ///
  /// This tool creates new Flutter projects with MVC architecture, corresponding to the `splendid_cli create` command.
  Map<String, dynamic> _createFlutterProjectTool() {
    return {
      'name': 'create_flutter_project',
      'description': 'Create a new Flutter project with MVC architecture, strong typing, and localization setup',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': 'Name of the Flutter project (must be a valid Dart package name)',
            'pattern': r'^[a-z][a-z0-9_]*$',
          },
          'outputDirectory': {
            'type': 'string',
            'description': 'Optional custom output directory for the project',
          },
          'platforms': {
            'type': 'string',
            'description': 'Comma-separated list of platforms to enable',
            'default': 'android,ios,web,windows,macos,linux',
          },
          'force': {
            'type': 'boolean',
            'description': 'Whether to overwrite existing directories',
            'default': false,
          },
        },
        'required': ['name'],
      },
    };
  }

  /// Defines the add_flutter_screen tool.
  ///
  /// This tool adds new screens with MVC architecture to existing projects, corresponding to the `splendid_cli screen`
  /// command.
  Map<String, dynamic> _addFlutterScreenTool() {
    return {
      'name': 'add_flutter_screen',
      'description': 'Add a new screen with MVC architecture to an existing Flutter project',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description': 'Name of the screen to create (must be a valid Dart identifier)',
            'pattern': r'^[a-zA-Z_][a-zA-Z0-9_]*$',
          },
          'projectPath': {
            'type': 'string',
            'description': 'Path to the Flutter project directory',
            'default': '.',
          },
          'force': {
            'type': 'boolean',
            'description': 'Whether to overwrite existing screen files',
            'default': false,
          },
        },
        'required': ['name'],
      },
    };
  }

  /// Defines the setup_flutter_project tool.
  ///
  /// This tool sets up Flutter projects by running necessary commands, corresponding to the `splendid_cli setup`
  /// command.
  Map<String, dynamic> _setupFlutterProjectTool() {
    return {
      'name': 'setup_flutter_project',
      'description': 'Setup a Flutter project by running pub get, gen-l10n, and optionally flutter run',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'projectPath': {
            'type': 'string',
            'description': 'Path to the Flutter project directory',
            'default': '.',
          },
          'runApp': {
            'type': 'boolean',
            'description': 'Whether to run the app after setup',
            'default': false, // Default to false for MCP to avoid long-running processes
          },
          'verbose': {
            'type': 'boolean',
            'description': 'Whether to enable verbose output',
            'default': false,
          },
        },
        'required': <String>[],
      },
    };
  }

  /// Defines the generate_test_template tool.
  ///
  /// This tool generates test file templates for Dart classes and widgets, corresponding to the `splendid_cli
  /// generate-test` command.
  Map<String, dynamic> _generateTestTemplateTool() {
    return {
      'name': 'generate_test_template',
      'description': 'Generate test file templates for Dart classes and Flutter widgets',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'targetFile': {
            'type': 'string',
            'description': 'Path to the Dart file to generate tests for',
          },
          'outputDirectory': {
            'type': 'string',
            'description': 'Optional custom output directory for the test file',
          },
          'testType': {
            'type': 'string',
            'description': 'Type of test to generate',
            'enum': ['auto', 'widget', 'class'],
            'default': 'auto',
          },
          'force': {
            'type': 'boolean',
            'description': 'Whether to overwrite existing test files',
            'default': false,
          },
        },
        'required': ['targetFile'],
      },
    };
  }

  /// Executes the create_flutter_project tool.
  ///
  /// Converts MCP arguments to a ProjectCreationRequest and calls the project service, then formats the response for
  /// MCP.
  Future<Map<String, dynamic>> _executeCreateProject(Map<String, dynamic> arguments) async {
    try {
      // Validate required parameters
      if (!arguments.containsKey('name') || arguments['name'] == null) {
        throw ArgumentError('Missing required parameter: name');
      }

      final request = ProjectCreationRequest(
        projectName: arguments['name'] as String,
        outputDirectory: arguments['outputDirectory'] as String?,
        platforms: arguments['platforms'] as String? ?? 'android,ios,web,windows,macos,linux',
        force: arguments['force'] as bool? ?? false,
      );

      final result = await _projectService.createProject(request);

      if (result.success) {
        return {
          'content': [
            {
              'type': 'text',
              'text':
                  'Successfully created Flutter project: ${result.projectName}\n'
                  'Location: ${result.targetPath}\n'
                  'Platforms: ${result.platforms}\n\n'
                  'Next steps:\n'
                  '1. cd ${result.targetPath}\n'
                  '2. Run setup_flutter_project to install dependencies\n'
                  '3. Start developing your Flutter app!',
            },
          ],
        };
      } else {
        return {
          'isError': true,
          'content': [
            {
              'type': 'text',
              'text': 'Failed to create project: ${result.error}',
            },
          ],
        };
      }
    } on ProjectServiceException catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Project creation failed: ${e.message}',
          },
        ],
      };
    } catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Project creation failed: $e',
          },
        ],
      };
    }
  }

  /// Executes the add_flutter_screen tool.
  ///
  /// Converts MCP arguments to a ScreenCreationRequest and calls the screen service, then formats the response for MCP.
  Future<Map<String, dynamic>> _executeAddScreen(Map<String, dynamic> arguments) async {
    try {
      final request = ScreenCreationRequest(
        screenName: arguments['name'] as String,
        projectPath: arguments['projectPath'] as String? ?? '.',
        force: arguments['force'] as bool? ?? false,
      );

      final result = await _screenService.createScreen(request);

      if (result.success) {
        final fileList = result.createdFiles.map((file) => '  • $file').join('\n');

        return {
          'content': [
            {
              'type': 'text',
              'text':
                  'Successfully created screen: ${result.screenName}\n\n'
                  'Generated files:\n$fileList\n\n'
                  'Next steps:\n'
                  '1. Add navigation to the new screen in your app\n'
                  '2. Customize the screen content as needed\n'
                  '3. Update any routing configuration',
            },
          ],
        };
      } else {
        return {
          'isError': true,
          'content': [
            {
              'type': 'text',
              'text': 'Failed to create screen: ${result.error}',
            },
          ],
        };
      }
    } on ScreenServiceException catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Screen creation failed: ${e.message}',
          },
        ],
      };
    }
  }

  /// Executes the setup_flutter_project tool.
  ///
  /// Converts MCP arguments to a ProjectSetupRequest and calls the project service, then formats the response for MCP.
  Future<Map<String, dynamic>> _executeSetupProject(Map<String, dynamic> arguments) async {
    try {
      final request = ProjectSetupRequest(
        projectPath: arguments['projectPath'] as String? ?? '.',
        runApp: arguments['runApp'] as bool? ?? false,
        verbose: arguments['verbose'] as bool? ?? false,
      );

      final result = await _projectService.setupProject(request);

      if (result.success) {
        final commandList = result.executedCommands.map((cmd) => '  • $cmd').join('\n');

        return {
          'content': [
            {
              'type': 'text',
              'text':
                  'Successfully setup Flutter project!\n\n'
                  'Executed commands:\n$commandList\n\n'
                  'Your Flutter project is ready for development.',
            },
          ],
        };
      } else {
        return {
          'isError': true,
          'content': [
            {
              'type': 'text',
              'text': 'Failed to setup project: ${result.error}',
            },
          ],
        };
      }
    } on ProjectServiceException catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Project setup failed: ${e.message}',
          },
        ],
      };
    }
  }

  /// Executes the generate_test_template tool.
  ///
  /// Converts MCP arguments to a TestGenerationRequest and calls the test service, then formats the response for MCP.
  Future<Map<String, dynamic>> _executeGenerateTest(Map<String, dynamic> arguments) async {
    try {
      // Convert string testType to enum
      TestType testType = TestType.auto;
      final testTypeStr = arguments['testType'] as String? ?? 'auto';
      switch (testTypeStr) {
        case 'widget':
          testType = TestType.widget;
        case 'class':
          testType = TestType.class_;
        default:
          testType = TestType.auto;
      }

      // Validate required parameters
      if (!arguments.containsKey('targetFile') || arguments['targetFile'] == null) {
        throw ArgumentError('Missing required parameter: targetFile');
      }

      final request = TestGenerationRequest(
        targetFile: arguments['targetFile'] as String,
        outputDirectory: arguments['outputDirectory'] as String?,
        testType: testType,
        force: arguments['force'] as bool? ?? false,
      );

      final result = await _testService.generateTest(request);

      if (result.success) {
        return {
          'content': [
            {
              'type': 'text',
              'text':
                  'Successfully generated test template!\n\n'
                  'Target file: ${result.targetFile}\n'
                  'Test file: ${result.outputPath}\n'
                  'Test type: ${result.testType.name}\n\n'
                  'The test template includes comprehensive test structure with setup, teardown, and example test cases.',
            },
          ],
        };
      } else {
        return {
          'isError': true,
          'content': [
            {
              'type': 'text',
              'text': 'Failed to generate test: ${result.error}',
            },
          ],
        };
      }
    } on TestServiceException catch (e) {
      return {
        'isError': true,
        'content': [
          {
            'type': 'text',
            'text': 'Test generation failed: ${e.message}',
          },
        ],
      };
    }
  }
}
