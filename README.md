# Splendid CLI

<img src="./images/icon.png" width=150  >

## Overview

Splendid CLI is a command-line interface tool designed to scaffold Flutter projects following MVC architecture standards. It promotes strong typing, localization (l10n), and other best practices to help developers build maintainable and scalable Flutter applications quickly and efficiently.

## Installation

To install Splendid CLI globally, run:

```bash
dart pub global activate splendid_cli
```

Make sure to add Dart's pub cache bin directory to your PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Usage

After installation, you can use the `splendid_cli` command to scaffold your Flutter projects.

### Creating a new project

```bash
splendid_cli create my_awesome_app
```

This command scaffolds a new Flutter project named `my_awesome_app` with MVC architecture, strong typing, localization setup, and other conventions.

### Setting up a project after creation

```bash
cd my_awesome_app
splendid_cli setup
```

This command runs the post-creation setup steps:
- `flutter pub get` - Downloads and installs dependencies
- `flutter gen-l10n` - Generates localization files
- `flutter run` - Launches the application (optional with `--no-run`)

You can also run setup on any Flutter project:

```bash
splendid_cli setup --project path/to/flutter/project --no-run
```

### Generating test templates

```bash
splendid_cli generate-test lib/services/api_service.dart
# or use the shorter alias:
splendid_cli gen-test lib/services/api_service.dart
```

This command generates a comprehensive test template for the specified Dart file. The CLI automatically detects whether the file contains Flutter widgets or regular Dart classes and generates the appropriate test structure:

- **Widget tests**: Use `testWidgets` with Flutter testing utilities
- **Class tests**: Use standard `test()` functions with comprehensive test categories
- **Auto-detection**: Automatically chooses the right template based on file content

You can also specify the test type explicitly:

```bash
# Generate a widget test template
splendid_cli gen-test lib/widgets/my_widget.dart --type=widget

# Generate a class test template  
splendid_cli gen-test lib/models/user.dart --type=class

# Use custom output directory
splendid_cli gen-test lib/services/auth_service.dart --output=test/unit/services
```

## Available Commands

- `splendid_cli create <project_name>`: Creates a new Flutter project with Splendid CLI standards.
- `splendid_cli setup`: Sets up a Flutter project by running pub get, gen-l10n, and optionally flutter run.
- `splendid_cli generate-test <dart_file>` (alias: `gen-test`): Generates test file templates for Dart classes and Flutter widgets.
- `splendid_cli help`: Displays help information about commands.

### Create Command Options

- `--output-directory` (`-o`): Specify where to create the project
- `--platforms`: Choose which platforms to enable (android,ios,web,windows,macos,linux)
- `--force`: Overwrite existing directories

### Setup Command Options

- `--project` (`-p`): Specify the Flutter project directory to setup
- `--no-run`: Skip running the app after setup
- `--verbose` (`-v`): Enable verbose output from Flutter commands

### Generate-Test Command Options

- `--output` (`-o`): Specify custom output directory for the generated test file
- `--type` (`-t`): Specify test type (auto, widget, class) - defaults to auto-detection
- `--force`: Overwrite existing test files without confirmation

## Quick Start

1. Create a new Flutter project:
   ```bash
   splendid_cli create my_app
   ```

2. Set up the project:
   ```bash
   splendid_cli setup --project my_app
   ```

3. Generate test templates as you develop:
   ```bash
   splendid_cli gen-test lib/services/my_service.dart
   splendid_cli gen-test lib/widgets/my_widget.dart --type=widget
   ```

That's it! Your Flutter project is ready for development with MVC architecture, all dependencies installed, and comprehensive test templates available on demand.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and ensure tests pass.
4. Submit a pull request with a clear description of your changes.

Please adhere to the project's coding style and include tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
