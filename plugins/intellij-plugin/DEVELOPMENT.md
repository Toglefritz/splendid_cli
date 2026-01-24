# IntelliJ Plugin Development Guide

This guide covers the development workflow for the Splendid CLI IntelliJ IDEA plugin.

## Prerequisites

### Required Software

- **JDK 17 or later**: Required for IntelliJ Platform SDK
  ```bash
  # Verify Java version
  java -version
  ```

- **IntelliJ IDEA**: Community or Ultimate Edition
  - Download from: https://www.jetbrains.com/idea/download/

- **Splendid CLI**: For testing the integration
  ```bash
  dart pub global activate splendid_cli
  ```

### Recommended IntelliJ Plugins

- **Plugin DevKit**: Usually bundled with IntelliJ IDEA
- **Kotlin**: For Kotlin language support

## Initial Setup

You have two options for initial setup:

### Option A: Quick Setup (Using setup.sh)

For a fast automated setup, use the provided script:

```bash
cd plugins/intellij-plugin
chmod +x setup.sh
./setup.sh
```

This script will:
- Check that Java 17+ is installed
- Check if Splendid CLI is in your PATH
- Generate the Gradle wrapper (if Gradle is installed)
- Build the plugin
- Display next steps

After running the script, skip to [Development Workflow](#development-workflow).

### Option B: Manual Setup

If you prefer manual control or the script doesn't work for your environment:

#### 1. Clone and Open Project

```bash
# Navigate to the plugin directory
cd plugins/intellij-plugin

# Open in IntelliJ IDEA
idea .
# Or use File → Open and select the intellij-plugin directory
```

#### 2. Generate Gradle Wrapper (First Time Only)

The project doesn't include the Gradle wrapper scripts. Generate them:

```bash
# If you have Gradle installed globally
gradle wrapper

# This creates gradlew and gradlew.bat scripts
```

If you don't have Gradle installed, IntelliJ will handle this automatically when you open the project.

##### 3. Gradle Sync

IntelliJ should automatically detect the Gradle project and sync dependencies. If not:

1. Open the Gradle tool window (View → Tool Windows → Gradle)
2. Click the refresh icon to sync

#### 4. Configure SDK

Ensure the project SDK is set to JDK 17+:

1. File → Project Structure → Project
2. Set Project SDK to JDK 17 or later
3. Set Project language level to "17 - Sealed types, always-strict floating-point semantics"

## Development Workflow

### Running the Plugin

The easiest way to test the plugin is to run it in a sandboxed IDE instance:

```bash
# From command line (after generating wrapper)
./gradlew runIde

# Or if using system Gradle
gradle runIde

# Or use the Gradle tool window in IntelliJ (recommended):
# Gradle → Tasks → intellij → runIde
```

This launches a new IDE window with:
- The plugin installed and active
- Separate settings and configuration
- No impact on your main IDE installation

### Testing the Sort L10n Action

1. Run the plugin with `./gradlew runIde`
2. In the test IDE, open or create a Flutter project
3. Create a test `.arb` file with unsorted entries:
   ```json
   {
     "zebra": "Zebra",
     "apple": "Apple",
     "banana": "Banana"
   }
   ```
4. Right-click the `.arb` file in the project view or editor
5. Select "Sort Localizable Strings"
6. Verify the file is sorted and a notification appears

### Making Changes

The typical development cycle:

1. **Edit Code**: Make changes to Kotlin files
2. **Stop Test IDE**: Close the sandboxed IDE window
3. **Rebuild**: Gradle automatically rebuilds on next run
4. **Test**: Run `./gradlew runIde` again to test changes

**Hot Reload**: Unfortunately, IntelliJ plugins don't support hot reload. You must restart the test IDE to see changes.

### Debugging

To debug the plugin:

1. In your main IntelliJ IDEA, set breakpoints in the plugin code
2. Run the plugin in debug mode:
   ```bash
   ./gradlew runIde --debug-jvm
   ```
3. Or use the Gradle tool window: Right-click runIde → Debug
4. The debugger will attach when breakpoints are hit

## Project Structure

### Key Files

```
plugins/intellij-plugin/
├── build.gradle.kts              # Build configuration
├── gradle.properties             # Plugin metadata and versions
├── settings.gradle.kts           # Gradle settings
│
├── src/main/
│   ├── kotlin/com/splendidcli/intellij/
│   │   ├── actions/              # IDE actions (menu items)
│   │   │   └── SortL10nAction.kt
│   │   ├── services/             # Project-level services
│   │   │   └── CliExecutorService.kt
│   │   └── settings/             # Plugin configuration
│   │       ├── PluginSettings.kt
│   │       └── PluginSettingsConfigurable.kt
│   │
│   └── resources/
│       └── META-INF/
│           └── plugin.xml        # Plugin descriptor
│
└── build/
    └── distributions/            # Built plugin ZIP files
```

### Understanding plugin.xml

The `plugin.xml` file is the plugin's manifest. It defines:

- **Plugin metadata**: ID, name, description, vendor
- **Dependencies**: Required plugins (Dart, Platform)
- **Extensions**: Services, settings pages, notification groups
- **Actions**: Menu items and their locations

When adding new features, you'll typically:
1. Create the implementation class (action, service, etc.)
2. Register it in `plugin.xml`

### Service Architecture

**CliExecutorService**: Project-level service for CLI interaction
- Detects CLI installation
- Executes commands with proper error handling
- Shows notifications
- Manages settings integration

**PluginSettings**: Persistent configuration storage
- Stores user preferences
- Automatically persisted across IDE restarts
- Accessed via `PluginSettings.getInstance(project)`

## Adding New Features

### Adding a New Action

Let's walk through adding a hypothetical "Format Dartdoc" action:

#### 1. Create the Action Class

```kotlin
// src/main/kotlin/com/splendidcli/intellij/actions/FormatDartdocAction.kt
package com.splendidcli.intellij.actions

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.vfs.VirtualFile
import com.splendidcli.intellij.services.CliExecutorService

class FormatDartdocAction : AnAction() {
    override fun update(e: AnActionEvent) {
        val file: VirtualFile? = e.getData(CommonDataKeys.VIRTUAL_FILE)
        val isDartFile: Boolean = file?.extension == "dart"
        e.presentation.isEnabledAndVisible = isDartFile && e.project != null
    }

    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        val file: VirtualFile = e.getData(CommonDataKeys.VIRTUAL_FILE) ?: return
        val executor: CliExecutorService = project.getService(CliExecutorService::class.java)
        
        // Execute CLI command
        val result = executor.execute("format", "--file", file.path, "--line-length", "80")
        
        // Handle result...
    }
}
```

#### 2. Register in plugin.xml

```xml
<actions>
    <!-- Existing actions... -->
    
    <action id="SplendidCli.FormatDartdoc"
            class="com.splendidcli.intellij.actions.FormatDartdocAction"
            text="Format Dartdoc Comments"
            description="Format Dartdoc comments to 80 character line length">
        <add-to-group group-id="EditorPopupMenu" anchor="last"/>
    </action>
</actions>
```

#### 3. Test

Run `./gradlew runIde` and verify the action appears for `.dart` files.

### Adding a New Setting

To add a new user-configurable setting:

#### 1. Add Property to PluginSettings

```kotlin
// In PluginSettings.kt
var defaultLineLength: Int = 80
```

#### 2. Add UI Component to PluginSettingsConfigurable

```kotlin
// In PluginSettingsConfigurable.kt
private var lineLengthField: JBTextField? = null

override fun createComponent(): JComponent {
    val lineLengthFieldInstance = JBTextField()
    lineLengthField = lineLengthFieldInstance
    
    return FormBuilder.createFormBuilder()
        // ... existing components ...
        .addLabeledComponent(
            JBLabel("Default line length:"),
            lineLengthFieldInstance,
            1,
            false
        )
        .panel
}

override fun isModified(): Boolean {
    val settings = PluginSettings.getInstance(project)
    return lineLengthField?.text?.toIntOrNull() != settings.defaultLineLength
}

override fun apply() {
    val settings = PluginSettings.getInstance(project)
    settings.defaultLineLength = lineLengthField?.text?.toIntOrNull() ?: 80
}

override fun reset() {
    val settings = PluginSettings.getInstance(project)
    lineLengthField?.text = settings.defaultLineLength.toString()
}
```

## Building and Distribution

### Building the Plugin

```bash
# Build plugin ZIP (with wrapper)
./gradlew buildPlugin

# Or with system Gradle
gradle buildPlugin

# Or use IntelliJ Gradle tool window:
# Gradle → Tasks → build → buildPlugin

# Output location:
# build/distributions/splendid-cli-intellij-plugin-1.0.0.zip
```

### Verifying the Plugin

```bash
# Verify plugin structure and compatibility
./gradlew verifyPlugin
# Or: gradle verifyPlugin
```

This checks:
- Plugin descriptor validity
- API compatibility
- Required dependencies
- File structure

### Testing the Built Plugin

To test the built ZIP file:

1. Build: `./gradlew buildPlugin` (or `gradle buildPlugin`)
2. Open IntelliJ IDEA or Android Studio (your main installation)
3. Settings → Plugins → ⚙️ → Install Plugin from Disk
4. Select `build/distributions/splendid-cli-intellij-plugin-*.zip`
5. Restart IDE
6. Test functionality

## Common Issues and Solutions

### Issue: "Cannot resolve symbol" errors in IDE

**Solution**: Gradle sync issue
```bash
# Reimport Gradle project
./gradlew clean build
# Or: gradle clean build
# Then: File → Invalidate Caches / Restart
```

### Issue: Plugin doesn't appear in test IDE

**Solution**: Check plugin.xml registration
- Verify action is registered in `<actions>` section
- Check that class name matches actual class
- Look for errors in the IDE log (Help → Show Log)

### Issue: CLI not found when testing

**Solution**: Ensure CLI is in PATH
```bash
# Verify CLI is accessible
which splendid_cli

# If not found, install it
dart pub global activate splendid_cli

# Add to PATH if needed
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Issue: Changes not reflected in test IDE

**Solution**: Rebuild required
- Close the test IDE window
- Changes require a full restart of the test IDE
- Run `./gradlew runIde` (or `gradle runIde`) again

### Issue: Gradle wrapper not found

**Solution**: Generate the wrapper or use system Gradle
```bash
# Option 1: Generate wrapper (requires Gradle installed)
gradle wrapper

# Option 2: Use system Gradle for all commands
gradle runIde
gradle buildPlugin

# Option 3: Use IntelliJ's Gradle tool window (recommended)
# View → Tool Windows → Gradle, then run tasks from there
```

## Best Practices

### Code Style

- Follow Kotlin coding conventions
- Use explicit types for public APIs
- Document all public classes and methods
- Keep actions focused and single-purpose

### Error Handling

- Always handle CLI execution failures gracefully
- Show user-friendly error messages in notifications
- Log detailed errors for debugging
- Never let exceptions crash the IDE

### Performance

- Run CLI commands in background tasks
- Use progress indicators for long operations
- Don't block the UI thread
- Cache expensive computations

### Testing

- Test with various file types and edge cases
- Verify behavior when CLI is not installed
- Test with different project structures
- Check notification messages are clear

## Resources

### IntelliJ Platform SDK Documentation

- [Plugin Development](https://plugins.jetbrains.com/docs/intellij/welcome.html)
- [Action System](https://plugins.jetbrains.com/docs/intellij/basic-action-system.html)
- [Services](https://plugins.jetbrains.com/docs/intellij/plugin-services.html)
- [Settings](https://plugins.jetbrains.com/docs/intellij/settings-guide.html)

### Gradle IntelliJ Plugin

- [Documentation](https://plugins.jetbrains.com/docs/intellij/tools-gradle-intellij-plugin.html)
- [GitHub Repository](https://github.com/JetBrains/gradle-intellij-plugin)

### Community

- [IntelliJ Platform Slack](https://plugins.jetbrains.com/slack)
- [Plugin Development Forum](https://intellij-support.jetbrains.com/hc/en-us/community/topics/200366979-IntelliJ-IDEA-Open-API-and-Plugin-Development)

## Next Steps

Now that you're set up for development:

1. Run the plugin and test the sort-l10n action
2. Review the existing code to understand the patterns
3. Check the [README](README.md) for planned features
4. Pick a feature to implement and start coding!

Questions? Open an issue in the main repository.
