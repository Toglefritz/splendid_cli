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
