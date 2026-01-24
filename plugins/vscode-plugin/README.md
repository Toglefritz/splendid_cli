# Splendid CLI Tools - VS Code Extension

VS Code extension that integrates [Splendid CLI](../../README.md) utilities for enhanced Flutter development workflows.

## Requirements

- VS Code 1.85.0 or later
- Splendid CLI installed and available in system PATH
  - Install via: `dart pub global activate splendid_cli`

## Installation

### From Source (Development)

1. Navigate to the extension directory:
   ```bash
   cd plugins/vscode-plugin
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Compile the extension:
   ```bash
   npm run compile
   ```

4. Press F5 in VS Code to launch the Extension Development Host

## Configuration

Configure the extension in VS Code settings:

- `splendidCli.executablePath`: Path to the Splendid CLI executable (default: `splendid_cli`)
- `splendidCli.showNotifications`: Show notifications when commands complete (default: `true`)

## Features

### Sorting ARB Files

Right-click any `.arb` file and select "Sort Localizable Strings" to sort the file alphabetically.

## Development

### Building

```bash
npm run compile
```

### Testing

Press F5 in VS Code to launch the Extension Development Host with the extension loaded.

## License

See [LICENSE](../../LICENSE) in the root of the repository.
