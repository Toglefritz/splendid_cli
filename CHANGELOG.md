## 5.3.0

### Intelligent Device Selection

- **Multi-Device Support**: Setup command now handles multiple connected devices automatically without user prompts
- **Smart Device Priority**: Intelligent selection prioritizes desktop > web > mobile devices for optimal development experience
- **Manual Device Selection**: New `--device` flag allows users to specify exact device ID for flutter run
- **Pre-Run Device Feedback**: Shows device selection information before starting the app, allowing users to cancel if needed
- **Clear Selection Reasoning**: Explains why each device was selected (user specified, automatic priority, only available)
- **Alternative Device Display**: Lists other available devices with instructions on how to select them
- **Graceful Error Handling**: Clear error messages when specified devices are not found, with list of available alternatives
- **Backward Compatibility**: Existing setup workflows continue unchanged when only one device is available
- **Device Validation**: Robust validation ensures specified devices exist before attempting to run applications
- **Comprehensive Testing**: Full test coverage for device selection logic and error scenarios

## 5.2.0

### Organization Identifier Support

- **Custom Organization**: New `--org` flag for the `create` command sets organization in reverse domain name notation
- **Platform Integration**: Organization automatically applied to Android application ID and iOS bundle identifier
- **Format Validation**: Robust validation ensures proper reverse domain format (e.g., com.example, org.mycompany)
- **Default Behavior**: Uses 'com.example' when no organization specified, maintaining backward compatibility
- **Error Handling**: Clear error messages with examples guide users toward correct organization format
- **Comprehensive Testing**: Full test coverage for organization validation and platform-specific configuration
- **Flutter CLI Alignment**: Matches Flutter's native `--org` flag behavior for consistency and familiarity

## 5.1.0

### Blank Screen Generation

- **Minimal Scaffolding**: New `--blank` flag for the `screen` command creates clean MVC structure without example content
- **Developer Choice**: Option to generate screens with or without the icon selection game placeholder
- **Clean Templates**: Blank screens include only essential MVC components (route, controller, view) with helpful comments
- **Flexible Workflow**: Developers can start with minimal scaffolding and add functionality as needed
- **Flag Combination**: `--blank` flag works seamlessly with existing `--force` flag for overwriting screens
- **Dual Brick System**: Separate Mason bricks for regular and blank screen generation ensure optimal templates
- **Comprehensive Testing**: Full test coverage for blank screen generation and flag combinations

## 5.0.1

### Command Aliases

- **Enhanced Usability**: Added convenient shorter aliases for core commands to improve developer experience
- **Alias Support**: Commands now support multiple invocation patterns for faster typing and better discoverability
- **Backward Compatibility**: All existing command names continue to work alongside new aliases
- **Consistent Patterns**: Aliases follow consistent naming conventions across all commands

## 5.0.0

### GUI Dashboard

- **Visual Interface**: New `gui` command launches a Flutter desktop application for visual project management
- **Cross-Platform Desktop**: Full support for Windows, macOS, and Linux desktop platforms
- **Project Creation Wizard**: Visual interface for creating Flutter projects with platform selection and parameter configuration
- **Screen Generation Interface**: Point-and-click screen creation with MVC architecture preview
- **Test Generation Tools**: File browser integration for selecting target files and generating comprehensive test templates
- **Real-Time Output**: Live command execution feedback with expandable output panel and copy-to-clipboard functionality
- **Project Detection**: Automatic Flutter project detection with visual status indicators
- **Command Preview**: Shows exact CLI commands before execution for transparency and learning
- **File System Integration**: Native file picker dialogs for project and file selection
- **Responsive Design**: Adaptive grid layout that works across different screen sizes
- **Error Handling**: Comprehensive error display and recovery with user-friendly messages
- **MVC Architecture**: GUI follows the same architectural patterns as generated projects
- **Dependency Isolation**: Separate Flutter dependencies for GUI to avoid version conflicts with CLI

## 4.1.1

### Version Management

- **Dynamic Version Reading**: Version flag now dynamically reads from `pubspec.yaml` instead of hardcoded value
- **Automatic Synchronization**: CLI version output always matches the package version without manual updates
- **Short Flag Support**: Added `-v` shortcut for `--version` flag following standard CLI conventions
- **Error Resilience**: Graceful fallback to 'unknown' when version cannot be determined from pubspec.yaml

## 4.1.0

### Version Support

- **Version Flag**: Added `--version` global option to display current CLI version
- **Standard Compliance**: Follows standard CLI conventions for version information display
- **Priority Handling**: Version flag takes precedence over other arguments when provided

## 4.0.0

### Dartdoc Comment Formatting

- **Comment Reformatting**: New `format-dartdoc` command for automated Dartdoc comment line length adjustment
- **Line Length Migration**: Seamlessly convert comments from 80 to 120 characters (or any specified length between 40-200)
- **Intelligent Wrapping**: Smart text wrapping that respects word boundaries and preserves readability
- **Format Preservation**: Maintains code blocks (```dart), markdown headers, lists, and documentation tags
- **Batch Processing**: Process individual files or entire directory trees with recursive .dart file discovery
- **Safety Features**: Dry-run mode for previewing changes without file modification
- **Build Directory Skipping**: Automatically excludes .dart_tool/, build/, and other generated file directories
- **Dual Comment Support**: Handles both /// single-line and /** */ multi-line Dartdoc comment styles
- **Command Aliases**: Multiple invocation options (`format-dartdoc`, `fmt-doc`, `format-docs`)
- **Comprehensive Help**: Detailed usage documentation with examples and formatting behavior explanations

## 3.1.1

### Screen Template Improvements

- **Linter Compliance**: Fixed linter warnings in generated screen templates
- **Code Quality**: Minor adjustments to screen brick templates for better code standards
- **Template Refinement**: Improved generated code quality without functional changes


## 3.1.0

### Hybrid Brick Loading System

- **Smart Brick Resolution**: Hybrid loading system that checks local development bricks first, then cached bricks, then downloads from GitHub
- **Global Installation Support**: Fixes PathNotFoundException when CLI is installed globally via `dart pub global activate`
- **Automatic Caching**: Downloaded bricks are cached locally in `~/.splendid_cli/bricks/` for offline use
- **Cache Management**: New `cache` command with `list`, `info`, and `clear` subcommands for managing brick cache
- **Seamless Fallback**: Transparent fallback from local → cached → remote without user intervention
- **Development Friendly**: Preserves local brick usage during development while enabling production deployments
- **Offline Support**: Cached bricks work without internet connection after first download


## 3.0.0

### MCP Server Integration

- **AI Integration**: `--mcp-server` flag enables Model Context Protocol server mode for AI systems
- **Programmatic Access**: Exposes all CLI functionality through standardized MCP tools
- **Tool Registry**: Four core tools for project creation, screen generation, setup, and test generation
- **JSON-RPC Communication**: Standards-compliant MCP server with proper error handling
- **AI-Driven Development**: Enables AI assistants to scaffold Flutter projects autonomously
- **Protocol Compliance**: Full MCP specification support with initialization and capability negotiation

## 2.0.0

### Screen Generation

- **Screen Scaffolding**: `screen` command for adding MVC-structured screens to existing Flutter projects
- **MVC Architecture**: Generates route, controller, and view files following established patterns
- **Interactive Placeholder**: Icon selection game demonstrating proper MVC separation
- **Smart Naming**: Automatic conversion between naming conventions (PascalCase → snake_case)
- **Enhanced Help**: Updated CLI help system with comprehensive screen command documentation
- **Robust Validation**: Flutter project detection and Dart identifier validation

## 1.0.0

### Initial Release

- **Project Scaffolding**: `create` command for generating Flutter projects with MVC architecture
- **Project Setup**: `setup` command for automated dependency installation and localization generation  
- **Test Generation**: `generate-test` command for creating comprehensive test templates
- **Strong Typing**: All generated code follows explicit typing patterns
- **Localization Ready**: Pre-configured l10n setup with ARB files
- **Cross-Platform**: Support for all Flutter platforms (Android, iOS, Web, Desktop)
- **Developer Experience**: Intuitive CLI with helpful
