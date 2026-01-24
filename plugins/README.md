# Splendid CLI IDE Plugins

This directory contains IDE plugins that integrate Splendid CLI functionality into popular development environments.

## Available Plugins

### IntelliJ IDEA / Android Studio Plugin

Location: [`intellij-plugin/`](./intellij-plugin/)

Integrates Splendid CLI tools into IntelliJ IDEA and Android Studio, providing context menu actions and IDE-native workflows for Flutter development.

**Features**:
- Sort localizable strings in `.arb` files
- Create Flutter screens with MVC pattern
- Generate test files
- Format Dartdoc comments

[View Documentation →](./intellij-plugin/README.md)

### VS Code Extension

Location: [`vscode-plugin/`](./vscode-plugin/)

Integrates Splendid CLI tools into VS Code, providing context menu actions and IDE-native workflows for Flutter development.

**Features**:
- Sort localizable strings in `.arb` files
- Create Flutter screens with MVC pattern
- Generate test files
- Format Dartdoc comments

[View Documentation →](./vscode-plugin/README.md)

## Architecture

Both plugins follow a similar architecture pattern:

```
Plugin Layer (IDE-specific)
    ↓
CLI Executor Service
    ↓
Splendid CLI (shared implementation)
```

This design ensures:
- **Consistency**: Same functionality across all IDEs
- **Maintainability**: Core logic lives in the CLI
- **Testability**: CLI can be tested independently
- **Flexibility**: Easy to add new IDE integrations

## Contributing

Contributions to plugin development are welcome! Please:

1. Check existing issues and PRs
2. Follow the coding standards in each plugin's documentation
3. Test thoroughly in the target IDE
4. Update documentation for new features

## Requirements

All plugins require:
- Splendid CLI installed and available in system PATH
- Dart/Flutter development environment
- IDE-specific requirements (see individual plugin READMEs)

## Installation

### For Users

Installation instructions are available in each plugin's README:
- [IntelliJ Plugin Installation](./intellij-plugin/README.md#installation)
- [VS Code Extension Installation](./vscode-plugin/README.md) (coming soon)

### For Developers

Each plugin has its own development setup:
- [IntelliJ Plugin Development](./intellij-plugin/README.md#development)
- [VS Code Extension Development](./vscode-plugin/README.md) (coming soon)

## License

All plugins are licensed under the same license as the main Splendid CLI project. See [LICENSE](../LICENSE) in the repository root.
