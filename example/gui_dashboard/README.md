# Splendid CLI GUI Dashboard

A Flutter desktop application that provides a graphical user interface for the Splendid CLI tools. This GUI makes it easy to use all CLI functionality through point-and-click interactions instead of command-line operations.

## Features

- **Project Creation**: Visual wizard for creating new Flutter projects with MVC architecture
- **Screen Generation**: Easy interface for adding new screens with route/controller/view pattern
- **Test Generation**: Simple dialog for generating test files for widgets and classes
- **Project Management**: Setup and formatting tools with real-time feedback
- **File Browser**: Integrated file selection for project navigation
- **Command Output**: Real-time display of CLI command execution and results

## Requirements

- Flutter SDK (3.19.0 or later)
- Desktop platform support enabled for Flutter
- Splendid CLI installed and available in PATH

## Usage

### Via Splendid CLI (Recommended)

Launch the GUI dashboard using the Splendid CLI:

```bash
# Launch GUI for current directory
splendid_cli gui

# Launch GUI for specific project
splendid_cli gui --project-path /path/to/project
```

### Direct Flutter Execution

You can also run the GUI directly for development:

```bash
# Navigate to the GUI directory
cd example/gui_dashboard

# Run using the helper scripts
./run_gui.sh        # On macOS/Linux
run_gui.bat         # On Windows

# Or run directly with Flutter
flutter pub get
flutter run -d windows  # or macos/linux
```

## Architecture

The GUI follows the same MVC architecture pattern as the CLI-generated projects:

- **Routes**: Entry points for screens (`*_route.dart`)
- **Controllers**: Business logic and state management (`*_controller.dart`)
- **Views**: UI presentation layer (`*_view.dart`)
- **Services**: Backend communication and CLI integration
- **Components**: Reusable UI widgets
- **Dialogs**: Modal interfaces for user input

## Key Components

### Dashboard Screen
- Main interface with project information and command buttons
- Real-time project status and Flutter detection
- Expandable output panel for command results

### CLI Service
- Handles execution of Splendid CLI commands
- Manages process lifecycle and output capture
- Provides structured results for UI display

### Dialog System
- Create Project: Full project creation wizard
- Add Screen: Screen generation with MVC pattern
- Generate Test: Test file creation interface

## Development

To run the GUI in development mode:

```bash
cd example/gui_dashboard
flutter run -d windows  # or macos/linux
```

To build for distribution:

```bash
flutter build windows  # or macos/linux
```

## Platform Support

The GUI supports all Flutter desktop platforms:
- Windows
- macOS  
- Linux

## Integration

The GUI integrates seamlessly with the Splendid CLI:
- Executes CLI commands as separate processes
- Captures and displays command output
- Handles all CLI error conditions
- Provides visual feedback for all operations

This provides a user-friendly alternative to command-line usage while maintaining full access to all CLI functionality.