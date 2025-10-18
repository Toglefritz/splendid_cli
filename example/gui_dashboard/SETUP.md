# Splendid CLI GUI Dashboard Setup Guide

This guide helps you set up and run the Splendid CLI GUI Dashboard on your system.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.16.0 or later)
   - Download from: https://flutter.dev/docs/get-started/install
   - Ensure `flutter` command is available in your PATH

2. **Desktop Platform Support**
   - **Windows**: Included with Flutter
   - **macOS**: Included with Flutter  
   - **Linux**: May require additional setup

### Verify Installation

Run these commands to verify your setup:

```bash
# Check Flutter installation
flutter --version

# Check desktop support
flutter config --list

# Verify platform availability
flutter devices
```

## Running the GUI

### Method 1: Via Splendid CLI (Recommended)

```bash
# Install Splendid CLI if not already installed
dart pub global activate splendid_cli

# Launch GUI for current directory
splendid_cli gui

# Launch GUI for specific project
splendid_cli gui --project-path /path/to/your/project

# Launch in debug mode
splendid_cli gui --debug
```

### Method 2: Direct Flutter Execution

```bash
# Navigate to GUI directory
cd example/gui_dashboard

# Get dependencies
flutter pub get

# Run on your platform
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux

# Or use the helper scripts
./run_gui.sh              # macOS/Linux
run_gui.bat               # Windows
```

## Troubleshooting

### Common Issues

#### "Flutter not found"
- Ensure Flutter is installed and in your PATH
- Restart your terminal after installation
- Run `flutter doctor` to check for issues

#### "No desktop devices available"
- Enable desktop support: `flutter config --enable-<platform>-desktop`
- Where `<platform>` is `windows`, `macos`, or `linux`

#### "Dependency resolution failed"
- Run `flutter clean` in the gui_dashboard directory
- Run `flutter pub get` again
- Check Flutter version compatibility

#### "GUI won't launch from CLI"
- Verify Splendid CLI is installed: `splendid_cli --version`
- Check that Flutter is in PATH: `which flutter` (Unix) or `where flutter` (Windows)
- Try running with debug flag: `splendid_cli gui --debug`

### Platform-Specific Notes

#### Windows
- Requires Windows 10 version 1903 or later
- Visual Studio 2019 or later may be required for building

#### macOS
- Requires macOS 10.14 or later
- Xcode may be required for building

#### Linux
- Additional dependencies may be required
- Run `flutter doctor` for specific requirements

## Development Setup

If you want to modify the GUI:

```bash
# Clone the repository
git clone <repository-url>
cd splendid_cli/example/gui_dashboard

# Get dependencies
flutter pub get

# Run in development mode
flutter run -d <platform> --debug

# Run tests
flutter test

# Build for release
flutter build <platform>
```

## Features Overview

The GUI provides visual interfaces for:

- **Project Creation**: Wizard with platform selection
- **Screen Generation**: MVC architecture with preview
- **Test Generation**: File browser integration
- **Project Setup**: One-click dependency installation
- **Code Formatting**: Automated code formatting
- **Real-time Output**: Command execution feedback

## Getting Help

- **CLI Help**: `splendid_cli help gui`
- **Flutter Issues**: `flutter doctor`
- **GUI Issues**: Check the output panel in the GUI
- **Documentation**: See README.md files in the project

## Performance Tips

- Close other resource-intensive applications
- Use release mode for better performance: `--release`
- Ensure adequate system resources (4GB+ RAM recommended)
- Use SSD storage for better Flutter performance