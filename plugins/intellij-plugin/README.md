# Splendid CLI Tools - IntelliJ IDEA Plugin

IntelliJ IDEA/Android Studio plugin that integrates [Splendid CLI](../../README.md) utilities into the IDE for enhanced Flutter development workflows.

## Requirements

- IntelliJ IDEA 2023.2+ or Android Studio Hedgehog (2023.1.1)+
- Dart plugin installed
- Splendid CLI installed and available in system PATH
  - Install via: `dart pub global activate splendid_cli`

## Installation

### From JetBrains Marketplace

1. Open Settings/Preferences → Plugins
2. Search for "Splendid CLI Tools"
3. Click Install
4. Restart the IDE

### From Disk (Local Development)

See [INSTALL.md](INSTALL.md) for detailed installation instructions including:
- Installing using IntelliJ IDEA (recommended)
- Installing using command-line Gradle
- Using the setup script
- Troubleshooting common issues

**Quick install:**
```bash
cd plugins/intellij-plugin
./gradlew buildPlugin
# Then install the ZIP from build/distributions/ via Settings → Plugins → Install Plugin from Disk
```

**Note**: If `gradlew` is not available, either run `gradle wrapper` first or use IntelliJ's Gradle tool window.

## Configuration

After installation, configure the plugin:

1. Open Settings/Preferences → Tools → Splendid CLI Tools
2. (Optional) Set custom CLI executable path if not in system PATH
3. Configure notification and auto-refresh preferences

## Usage

### Sorting ARB Files

1. Right-click any `.arb` file in the project view or editor
2. Select "Sort Localizable Strings"
3. The file will be sorted alphabetically with progress indication
4. File automatically refreshes to show changes

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for comprehensive development documentation including:
- Setting up the development environment
- Running and debugging the plugin
- Adding new features
- Testing and building
- Common issues and solutions

### Prerequisites

- JDK 17 or later
- IntelliJ IDEA with Plugin DevKit

### Quick Start

```bash
# Option 1: Using IntelliJ (recommended)
# Open plugins/intellij-plugin in IntelliJ IDEA
# Use Gradle tool window: Tasks → intellij → runIde

# Option 2: Using command line
cd plugins/intellij-plugin
gradle wrapper          # First time only
./gradlew runIde       # Run in test IDE
./gradlew buildPlugin  # Build distributable ZIP
```

### Project Structure

```
src/main/
├── kotlin/com/splendidcli/intellij/
│   ├── actions/           # IDE actions (menu items, context actions)
│   │   └── SortL10nAction.kt
│   ├── services/          # Project-level services
│   │   └── CliExecutorService.kt
│   └── settings/          # Plugin configuration
│       ├── PluginSettings.kt
│       └── PluginSettingsConfigurable.kt
└── resources/
    └── META-INF/
        └── plugin.xml     # Plugin configuration
```

### Adding New Actions

1. Create action class in `actions/` package extending `AnAction`
2. Implement `update()` to control visibility/enabled state
3. Implement `actionPerformed()` to execute the action
4. Register action in `plugin.xml`
5. Use `CliExecutorService` to execute CLI commands

Example:

```kotlin
class MyNewAction : AnAction() {
    override fun update(e: AnActionEvent) {
        // Control when action is visible/enabled
    }
    
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        val executor = project.getService(CliExecutorService::class.java)
        
        // Execute CLI command
        val result = executor.execute("my-command", "--arg", "value")
        
        if (result.isSuccess) {
            // Handle success
        } else {
            // Handle error
        }
    }
}
```

## Testing

The plugin can be tested in a sandboxed IDE instance:

```bash
./gradlew runIde
```

This launches a new IDE window with the plugin installed where you can test functionality without affecting your main IDE installation.

## Publishing

### To JetBrains Marketplace

1. Create account at [JetBrains Marketplace](https://plugins.jetbrains.com/)
2. Build plugin: `./gradlew buildPlugin`
3. Upload `build/distributions/splendid-cli-intellij-plugin-*.zip`
4. Submit for review

## License

See [LICENSE](../../LICENSE) in the root of the repository.

## Contributing

Contributions are welcome! Please see the main [README](../../README.md) for contribution guidelines.
