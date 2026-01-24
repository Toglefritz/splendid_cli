# Splendid CLI

<img src="https://github.com/Toglefritz/splendid_cli/blob/main/images/icon.png?raw=true" width=150  >

## Overview

Splendid CLI is a comprehensive command-line toolkit for Flutter developers that streamlines development workflows and enforces best practices. While it started as a project scaffolding tool, it has evolved into a full-featured development assistant that helps with project creation, code generation, testing, and project management.

**Key Features:**
- **Project Scaffolding**: Create Flutter projects with MVC architecture, strong typing, and localization setup
- **Code Generation**: Generate screens, widgets, and test templates following best practices
- **GUI Dashboard**: Visual interface for project management and code generation
- **Brick Management**: Efficient caching system for Mason bricks with offline support
- **Test Automation**: Intelligent test template generation for widgets and classes
- **Development Workflow**: Automated setup commands for faster project initialization

## Installation

To install Splendid CLI globally, run:

```bash
dart pub global activate splendid_cli
```

Make sure to add Dart's pub cache bin directory to your PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Architecture & Design

### MVC Pattern

Splendid CLI enforces a strict MVC (Model-View-Controller) pattern:

- **Route**: StatefulWidget entry point for each screen
- **Controller**: Extends State, handles business logic and state management
- **View**: StatelessWidget for pure UI presentation

This separation ensures maintainable, testable code with clear responsibilities.

### Strong Typing

All generated code uses explicit typing:
- No `var` or `dynamic` unless absolutely necessary
- Full type annotations for collections and function signatures
- Nullable types (`String?`) over dynamic when null values are expected

### Localization First

Every project includes l10n setup:
- ARB files for string management
- Automatic generation with `flutter gen-l10n`
- No hard-coded strings in UI code

### Brick System

The CLI uses Mason bricks for code generation with intelligent loading:

1. **Development Mode**: Uses local `bricks/` directory when available
2. **Global Installation**: Downloads from GitHub and caches locally
3. **Offline Support**: Cached bricks work offline after first download
4. **Automatic Fallback**: Seamlessly falls back: local → cached → remote

Bricks are cached in `~/.splendid_cli/bricks/` for fast offline access.

## Core Features

### 1. Project Creation

Create new Flutter projects with opinionated architecture and best practices built-in:

```bash
splendid_cli create my_awesome_app
```

**What you get:**
- MVC architecture pattern (Route → Controller → View)
- Strong typing enforcement throughout the codebase
- Localization (l10n) setup with ARB files
- Proper project structure with organized directories
- Platform-specific configurations
- Best practice coding standards pre-configured

**Options:**
- `--output-directory` (`-o`): Specify where to create the project
- `--platforms`: Choose platforms (android,ios,web,windows,macos,linux)
- `--force`: Overwrite existing directories

### 2. Project Setup Automation

```bash
cd my_awesome_app
splendid_cli setup
```

Automates the tedious post-creation setup steps:
- `flutter pub get` - Downloads and installs dependencies
- `flutter gen-l10n` - Generates localization files
- `flutter run` - Launches the application (optional)

**Options:**
- `--project` (`-p`): Specify the Flutter project directory
- `--no-run`: Skip running the app after setup
- `--verbose` (`-v`): Enable verbose output

```bash
# Setup any Flutter project
splendid_cli setup --project path/to/flutter/project --no-run
```

### 3. Screen Generation

```bash
splendid_cli screen game
```

Generate complete screens following MVC architecture patterns. Creates three files:

- **Route**: `lib/screens/game/game_route.dart` - StatefulWidget entry point
- **Controller**: `lib/screens/game/game_controller.dart` - Business logic and state management  
- **View**: `lib/screens/game/game_view.dart` - UI presentation layer

**Features:**
- Automatic name conversion (PascalCase → snake_case)
- Placeholder content demonstrating MVC separation
- Ready-to-customize templates
- Proper imports and structure

**Options:**
- `--force`: Overwrite existing screen files

```bash
# Create screen with PascalCase name
splendid_cli screen UserProfile

# Overwrite existing screen
splendid_cli screen settings --force
```

### 4. Test Template Generation

```bash
splendid_cli generate-test lib/services/api_service.dart
# or use the shorter alias:
splendid_cli gen-test lib/services/api_service.dart
```

Intelligent test template generation that adapts to your code:

**Auto-Detection:**
- Analyzes file content to determine if it's a widget or class
- Generates appropriate test structure automatically
- Creates comprehensive test categories and examples

**Widget Tests:**
- Uses `testWidgets` with Flutter testing utilities
- Includes widget tree building and interaction tests
- Finder patterns and gesture simulation examples

**Class Tests:**
- Uses standard `test()` functions
- Organized test groups for different functionality
- Mock setup and teardown examples

**Options:**
- `--output` (`-o`): Custom output directory
- `--type` (`-t`): Specify test type (auto, widget, class)
- `--force`: Overwrite existing test files

```bash
# Auto-detect test type
splendid_cli gen-test lib/services/auth_service.dart

# Explicit widget test
splendid_cli gen-test lib/widgets/my_widget.dart --type=widget

# Custom output location
splendid_cli gen-test lib/models/user.dart --output=test/unit/models
```

### 5. GUI Dashboard

```bash
# List cached bricks
splendid_cli cache list

# Show cache information
splendid_cli cache info

# Clear all cached bricks
splendid_cli cache clear

# Clear cache without confirmation
splendid_cli cache clear --force
```

Efficient management of locally cached Mason bricks:

**Features:**
- View all cached bricks and their sizes
- Check cache location and total size
- Clear cache to free up disk space
- Automatic re-download when needed

**How It Works:**
1. **Development Mode**: Uses local `bricks/` directory when available
2. **Global Installation**: Downloads from GitHub and caches locally
3. **Offline Support**: Cached bricks work offline after first download
4. **Automatic Fallback**: Seamlessly falls back: local → cached → remote

Bricks are cached in `~/.splendid_cli/bricks/` for fast offline access.

```bash
# Launch the GUI dashboard
splendid_cli gui

# Launch for specific project
splendid_cli gui --project-path /path/to/project
```

A full-featured desktop application for visual project management:

**Features:**
- Visual project creation wizard with platform selection
- Screen generation interface with live preview
- Test file generation with file browser
- Real-time command output and progress feedback
- Cross-platform desktop support (Windows, macOS, Linux)
- Integrated terminal output viewer

**Options:**
- `--project-path` (`-p`): Initial project directory
- `--debug`: Launch with additional logging

**Requirements:**
- Flutter SDK installed and available in PATH
- Desktop platform support enabled for Flutter

See [example/gui_dashboard/README.md](example/gui_dashboard/README.md) for detailed documentation.

### 6. Brick Cache Management

## Command Reference

### Project Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `create <name>` | Create new Flutter project with MVC architecture | - |
| `setup` | Run post-creation setup (pub get, gen-l10n, run) | - |
| `screen <name>` | Generate new screen with MVC pattern | - |

### Development Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `generate-test <file>` | Generate test template for Dart file | `gen-test` |
| `gui` | Launch GUI dashboard | `dashboard` |

### Utility Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `cache list` | List all cached bricks | - |
| `cache info` | Show cache information | - |
| `cache clear` | Clear brick cache | - |
| `help` | Display help information | - |

### Global Options

Most commands support these common options:

- `--help` (`-h`): Show command-specific help
- `--verbose` (`-v`): Enable verbose output
- `--force`: Overwrite existing files without confirmation

## Quick Start Guide

### Command Line Workflow

1. **Create a new Flutter project:**
   ```bash
   splendid_cli create my_app
   ```

2. **Set up the project:**
   ```bash
   cd my_app
   splendid_cli setup
   ```

3. **Add screens as you develop:**
   ```bash
   splendid_cli screen home
   splendid_cli screen user_profile
   splendid_cli screen settings
   ```

4. **Generate tests for your code:**
   ```bash
   splendid_cli gen-test lib/services/auth_service.dart
   splendid_cli gen-test lib/widgets/custom_button.dart
   ```

### GUI Workflow

Prefer a visual interface? Launch the GUI dashboard:

```bash
splendid_cli gui
```

The GUI provides the same functionality with a user-friendly interface, file browsers, and real-time feedback.

## IDE Integration

Splendid CLI can be integrated directly into your IDE for seamless access to its features:

### IntelliJ IDEA / Android Studio Plugin

[View Plugin Documentation →](plugins/intellij-plugin/README.md)

### VS Code Extension

[View Plugins Overview →](plugins/README.md)

## Why Splendid CLI?

**Consistency**: Enforces MVC architecture and coding standards across your entire project

**Speed**: Automates repetitive tasks like project setup, screen generation, and test creation

**Best Practices**: Built-in support for strong typing, localization, and proper file organization

**Flexibility**: Works via command line or GUI, online or offline with cached bricks

**IDE Integration**: Available as plugins for popular IDEs with context menu actions

**Comprehensive**: Not just scaffolding—includes testing tools, project management, and workflow automation

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and ensure tests pass.
4. Submit a pull request with a clear description of your changes.

Please adhere to the project's coding style and include tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

In the creation of this application, artificial intelligence (AI) tools have been utilized. These tools have assisted in various stages of the tools's development, from initial code generation to the optimization of algorithms.

It is emphasized that the AI's contributions have been thoroughly overseen. Each segment of AI-assisted code has undergone meticulous scrutiny to ensure adherence to high standards of quality, reliability, and performance. This scrutiny was conducted by the sole developer responsible for the app's creation.

Rigorous testing has been applied to all AI-suggested outputs, encompassing a wide array of conditions and use cases. Modifications have been implemented where necessary, ensuring that the AI's contributions are well-suited to the specific requirements and limitations inherent in the technologies related to this app's functionality.

Commitment to the apps's accuracy and functionality is paramount, and feedback or issue reports from users are invited to facilitate continuous improvement.

It is to be understood that this tool, like all software, is subject to evolution over time. The developer is dedicated to its progressive refinement and is actively working to surpass the expectations of the community.
