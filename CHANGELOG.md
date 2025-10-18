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
