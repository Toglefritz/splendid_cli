# Splendid CLI

<img src="https://github.com/Toglefritz/splendid_cli/blob/main/images/icon.png?raw=true" width=150  >

## Overview

Splendid CLI is a comprehensive command-line toolkit for Flutter developers that streamlines development workflows and enforces best practices. While it started as a project scaffolding tool, it has evolved into a full-featured development assistant that helps with project creation, code generation, testing, and project management.

**Key Features:**
- **Project Scaffolding**: Create Flutter projects with MVC architecture, strong typing, and localization setup
- **Code Generation**: Generate screens, widgets, and test templates following best practices
- **Code Formatting**: Format Dartdoc comments, regular comments, and Dart code to consistent line lengths
- **Localization Tools**: Sort and organize ARB localization files and Dart enum values alphabetically
- **GUI Dashboard**: Visual interface for project management and code generation
- **Brick Management**: Efficient caching system for Mason bricks with offline support
- **Test Automation**: Intelligent test template generation for widgets and classes
- **Development Workflow**: Automated setup and deep cleaning commands for faster project maintenance

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

### 5. Code Formatting

Splendid CLI provides comprehensive code formatting tools to maintain consistent comment and code style across your project.

#### Format All (Unified Formatting)

```bash
splendid_cli format .
```

The unified format command applies all formatters in sequence:
1. Dartdoc comments (/// and /** */)
2. Regular comments (//)
3. Dart code (via dart format)

**Options:**
- `--line-length` (`-l`): Maximum line length for comments (default: 120, range: 40-200)
- `--dry-run`: Preview changes without modifying files
- `--verbose` (`-v`): Show detailed progress

```bash
# Format entire project with 80-character comments
splendid_cli format . 80

# Preview changes without applying
splendid_cli format lib/ --dry-run

# Format with custom line length using flag
splendid_cli format . --line-length 100
```

#### Format Dartdoc Comments

```bash
splendid_cli format-dartdoc lib/
```

Reformats Dartdoc comments (/// and /** */) to specified line length while preserving:
- Code blocks (```dart ... ```)
- Markdown formatting
- List items and headers
- Documentation tags (@param, @returns, etc.)

**Syntax:**
```bash
# Positional argument (convenient)
splendid_cli format-dartdoc <target> <line-length>

# Flag syntax (explicit)
splendid_cli format-dartdoc <target> --line-length <length>
```

**Examples:**
```bash
# Format to 80 characters
splendid_cli format-dartdoc lib/services/api_service.dart 80

# Format entire directory
splendid_cli format-dartdoc . --line-length 120

# Preview changes
splendid_cli format-dartdoc lib/ --dry-run --verbose
```

#### Format Regular Comments

```bash
splendid_cli format-comments lib/
```

Reformats regular // comments to specified line length. Leaves Dartdoc comments (/// and /** */) unchanged.

**Syntax:**
```bash
# Positional argument (convenient)
splendid_cli format-comments <target> <line-length>

# Flag syntax (explicit)
splendid_cli format-comments <target> --line-length <length>
```

**Examples:**
```bash
# Format to 80 characters
splendid_cli format-comments lib/services/api_service.dart 80

# Format entire directory
splendid_cli format-comments . --line-length 120

# Preview changes
splendid_cli format-comments lib/ --dry-run
```

### 6. Localization Management

#### Sort ARB Files

```bash
splendid_cli sort-l10n lib/l10n
```

Sorts Flutter localization (.arb) files alphabetically by key while maintaining the relationship between value entries and their metadata (@key entries).

**Features:**
- Alphabetical sorting by key
- Preserves value-metadata pairs
- Maintains JSON formatting
- Handles multiple files in directory

**Options:**
- `--dry-run`: Preview changes without modifying files
- `--verbose` (`-v`): Show detailed file lists

**Examples:**
```bash
# Sort all ARB files in directory
splendid_cli sort-l10n lib/l10n

# Sort specific file
splendid_cli sort-l10n lib/l10n/app_en.arb

# Preview changes
splendid_cli sort-l10n lib/l10n --dry-run --verbose
```

#### Sort Enum Values

```bash
splendid_cli sort-enum lib/models/status.dart
```

Sorts Dart enum values alphabetically by name within a source file. Handles both simple enums (plain value lists) and enhanced enums with fields, constructors, and methods.

**Features:**
- Alphabetical sorting of enum values by name
- Preserves documentation comments on individual values
- Handles enhanced enums with constructor arguments and members
- Processes all enum declarations in a file independently
- Already-sorted enums are left unchanged

**Options:**
- `--dry-run`: Preview changes without modifying the file
- `--verbose` (`-v`): Show detailed progress

**Examples:**
```bash
# Sort all enums in a file
splendid_cli sort-enum lib/models/status.dart

# Preview which enums would be reordered
splendid_cli sort-enum lib/models/priority.dart --dry-run

# Sort with verbose output using the alias
splendid_cli enum-sort lib/models/color.dart --verbose
```

### 7. Project Maintenance

#### Deep Clean

```bash
splendid_cli deep_clean
```

Performs comprehensive cleaning beyond standard `flutter clean`:
1. `flutter clean` - Remove build artifacts
2. `flutter pub get` - Refresh dependencies
3. `flutter gen-l10n` - Regenerate localization files

**When to use:**
- Build errors after normal flutter clean
- Dependency conflicts or corruption
- After major Flutter SDK updates
- Switching between Flutter channels

**Options:**
- `--verbose` (`-v`): Show detailed Flutter command output

**Examples:**
```bash
# Deep clean current directory
splendid_cli deep_clean

# Deep clean specific project
splendid_cli dc /path/to/flutter/project

# With verbose output
splendid_cli deep_clean --verbose
```

### 8. GUI Dashboard

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

### 9. Brick Cache Management

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

## Command Reference

### Project Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `create <name>` | Create new Flutter project with MVC architecture | - |
| `setup` | Run post-creation setup (pub get, gen-l10n, run) | - |
| `screen <name>` | Generate new screen with MVC pattern | - |
| `deep_clean` | Deep clean project (clean, pub get, gen-l10n) | `dc` |

### Code Generation & Testing

| Command | Description | Aliases |
|---------|-------------|---------|
| `generate-test <file>` | Generate test template for Dart file | `gen-test` |

### Formatting Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `format <target> [length]` | Format Dartdoc, regular comments, and code | `fmt` |
| `format-dartdoc <target> [length]` | Format Dartdoc comments to line length | `fmt-doc`, `format-docs` |
| `format-comments <target> [length]` | Format regular comments to line length | `fmt-comments`, `format-comment` |

### Localization Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `sort-l10n <target>` | Sort ARB localization files alphabetically | `sort-arb`, `l10n-sort` |

### Code Organization Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `sort-enum <dart_file>` | Sort Dart enum values alphabetically by name | `enum-sort` |

### Utility Commands

| Command | Description | Aliases |
|---------|-------------|---------|
| `gui` | Launch GUI dashboard | `dashboard` |
| `cache list` | List all cached bricks | - |
| `cache info` | Show cache information | - |
| `cache clear` | Clear brick cache | - |
| `help [command]` | Display help information | - |

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

5. **Format your code for consistency:**
   ```bash
   # Format everything (Dartdoc, comments, and code)
   splendid_cli format . 80
   
   # Or format specific aspects
   splendid_cli format-dartdoc lib/ 120
   splendid_cli format-comments lib/ 120
   ```

6. **Organize localization files:**
   ```bash
   splendid_cli sort-l10n lib/l10n
   ```

7. **Sort enum values alphabetically:**
   ```bash
   splendid_cli sort-enum lib/models/status.dart
   ```

8. **Deep clean when needed:**
   ```bash
   splendid_cli deep_clean
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

**Consistency**: Enforces MVC architecture and coding standards across your entire project with automated formatting tools

**Speed**: Automates repetitive tasks like project setup, screen generation, test creation, and code formatting

**Best Practices**: Built-in support for strong typing, localization, proper file organization, and consistent comment formatting

**Flexibility**: Works via command line or GUI, online or offline with cached bricks

**IDE Integration**: Available as plugins for popular IDEs with context menu actions

**Comprehensive**: Not just scaffolding—includes testing tools, code formatting, localization management, project maintenance, and workflow automation

**Developer-Friendly**: Supports both flag syntax and convenient positional arguments for faster command execution

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
