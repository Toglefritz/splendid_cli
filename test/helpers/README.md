# Test Helpers

This directory contains helper utilities for the Splendid CLI test suite.

## ProjectCleanupHelper

The `ProjectCleanupHelper` automatically cleans up test artifacts that may be created during test execution, particularly when tests run CLI commands that create projects or directories at the root level.

### Usage

Add to your test files:

```dart
import 'helpers/project_cleanup_helper.dart';

void main() {
  group('Your Test Group', () {
    // Set up automatic cleanup
    setUpAll(() {
      ProjectCleanupHelper.setupAutomaticCleanup();
    });

    // Clean up after all tests complete
    tearDownAll(() {
      ProjectCleanupHelper.cleanupTestArtifacts();
    });

    // Your tests here...
  });
}
```

### What it cleans up

The helper automatically removes common test directory names that may be created during CLI testing:

- `test_project`
- `integration_test_app`
- `mobile_only_app`
- `force_overwrite_app`
- `existing_directory_app`
- `mvc_structure_test`
- `test_app`
- `my_app`
- `flutter_demo`
- `awesome_project`
- `simple`
- `app123`
- `existing_project`
- `existing_project_force`
- `options_test_app`
- `game`
- `user_profile`
- `test_screen`

### Methods

- `cleanupTestArtifacts()` - Removes all known test directories
- `cleanupSpecificDirectory(String name)` - Removes a specific directory
- `cleanupDirectoriesMatching(RegExp pattern)` - Removes directories matching a pattern
- `findExistingTestArtifacts()` - Lists existing test directories
- `setupAutomaticCleanup()` - Sets up signal handlers for cleanup on exit

### Safety

The helper is designed to be safe:
- Only removes directories from a predefined list
- Handles errors gracefully without failing tests
- Never removes important directories like `lib`, `bin`, `test`, `.git`
- Logs cleanup actions for visibility

This ensures that test runs don't leave behind artifacts that could interfere with subsequent tests or consume disk space.