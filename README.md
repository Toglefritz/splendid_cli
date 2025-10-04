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

## Available Commands

- `splendid_cli create <project_name>`: Creates a new Flutter project with Splendid CLI standards.
- `splendid_cli setup`: Sets up a Flutter project by running pub get, gen-l10n, and optionally flutter run.
- `splendid_cli help`: Displays help information about commands.

### Create Command Options

- `--output-directory` (`-o`): Specify where to create the project
- `--platforms`: Choose which platforms to enable (android,ios,web,windows,macos,linux)
- `--force`: Overwrite existing directories

### Setup Command Options

- `--project` (`-p`): Specify the Flutter project directory to setup
- `--no-run`: Skip running the app after setup
- `--verbose` (`-v`): Enable verbose output from Flutter commands

## Quick Start

1. Create a new Flutter project:
   ```bash
   splendid_cli create my_app
   ```

2. Set up the project:
   ```bash
   splendid_cli setup --project my_app
   ```

That's it! Your Flutter project is ready for development with MVC architecture and all dependencies installed.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and ensure tests pass.
4. Submit a pull request with a clear description of your changes.

Please adhere to the project's coding style and include tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
