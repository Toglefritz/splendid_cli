# Splendid CLI

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

After installation, you can use the `splendid` command to scaffold your Flutter projects and features.

### Creating a new project

```bash
splendid create app_name
```

This command scaffolds a new Flutter project named `example_app` with MVC architecture, strong typing, localization setup, and other conventions.

### Adding a feature

```bash
cd example_app
splendid feature welcome
```

This command generates a new feature called `welcome` with the necessary MVC components and localization support.

## Available Commands

- `splendid create <project_name>`: Creates a new Flutter project with Splendid CLI standards.
- `splendid feature <feature_name>`: Adds a new feature module to your existing project.
- `splendid doctor`: Checks your environment and project for common issues.
- `splendid help`: Displays help information about commands.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and ensure tests pass.
4. Submit a pull request with a clear description of your changes.

Please adhere to the project's coding style and include tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
