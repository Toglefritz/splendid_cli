# Testing the Plugin with Android Studio 2025.2+

Due to compatibility issues between the IntelliJ Platform Gradle Plugin and Android Studio 2025.2+, the `./gradlew runIde` command may not work correctly. Instead, install the plugin directly into your Android Studio installation for testing.

## Installation for Testing

### 1. Build the Plugin

```bash
cd plugins/intellij-plugin
./gradlew buildPlugin
```

This creates: `build/distributions/splendid-cli-intellij-plugin-1.0.0.zip`

### 2. Install in Android Studio

1. Open Android Studio
2. Go to **Settings/Preferences** → **Plugins**
3. Click the ⚙️ (gear icon) → **Install Plugin from Disk...**
4. Select `build/distributions/splendid-cli-intellij-plugin-1.0.0.zip`
5. Click **OK** and restart Android Studio

### 3. Verify Installation

After restart:
1. Go to **Settings/Preferences** → **Tools** → **Splendid CLI Tools**
2. Verify the plugin settings page appears
3. Configure the CLI path if needed

## Testing the Sort L10n Feature

### 1. Create a Test Flutter Project

```bash
# Create a new Flutter project or use an existing one
flutter create test_project
cd test_project
```

### 2. Create a Test ARB File

Create `lib/l10n/app_en.arb` with unsorted content:

```json
{
  "zebra": "Zebra",
  "apple": "Apple",
  "banana": "Banana",
  "cherry": "Cherry"
}
```

### 3. Test the Plugin

1. Open the project in Android Studio
2. Right-click on `app_en.arb` in the Project view
3. Select **"Sort Localizable Strings"**
4. Verify the file is sorted alphabetically
5. Check for a success notification

Expected result:
```json
{
  "apple": "Apple",
  "banana": "Banana",
  "cherry": "Cherry",
  "zebra": "Zebra"
}
```

## Troubleshooting

### Plugin Doesn't Appear in Menu

- Verify the plugin is enabled in **Settings** → **Plugins**
- Check that you're right-clicking on a `.arb` file
- Restart Android Studio

### "CLI Not Found" Error

1. Ensure Splendid CLI is installed:
   ```bash
   dart pub global activate splendid_cli
   ```

2. Add to PATH:
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```

3. Or configure the path in plugin settings:
   - **Settings** → **Tools** → **Splendid CLI Tools**
   - Set **CLI Path** to the full path of `splendid_cli`

### Finding the CLI Path

```bash
which splendid_cli
# Output: /Users/username/.pub-cache/bin/splendid_cli
```

## Rebuilding After Changes

After making code changes:

```bash
# Rebuild the plugin
./gradlew clean buildPlugin

# Uninstall the old version in Android Studio
# Settings → Plugins → Splendid CLI Tools → Uninstall

# Install the new version
# Settings → Plugins → ⚙️ → Install Plugin from Disk

# Restart Android Studio
```

## Known Issues

### runIde Command Fails

The `./gradlew runIde` command fails with Android Studio 2025.2+ due to JFR (Java Flight Recorder) compatibility issues. This is a known limitation of the IntelliJ Platform Gradle Plugin with newer Android Studio versions.

**Workaround**: Install the plugin directly into Android Studio as described above.

### Build Warnings

You may see warnings about deprecated APIs. These are non-critical and don't affect functionality. They will be addressed in future updates.

## Alternative: Use IntelliJ IDEA for Development

If you need to use `runIde` for development, you can temporarily switch to IntelliJ IDEA:

1. Install IntelliJ IDEA Community Edition
2. Update `build.gradle.kts`:
   ```kotlin
   val localIdePath = "/Applications/IntelliJ IDEA CE.app/Contents"
   ```
3. Run `./gradlew runIde`

The plugin works identically in both IDEs.
