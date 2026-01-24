/// Integration test for the --org flag functionality.
///
/// This test verifies that the --org flag properly sets the organization
/// identifier in generated Flutter projects, ensuring that the organization is
/// correctly applied to platform-specific configuration files like Android's
/// build.gradle and iOS bundle identifiers.
///
/// Test Categories:
/// * Organization flag parsing and validation
/// * Integration with Flutter CLI create command
/// * Verification of generated project configuration
/// * Error handling for invalid organization formats
///
/// This test requires Flutter CLI to be available and creates actual project
/// files for verification.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:splendid_cli/splendid_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Organization Flag Integration', () {
    late Directory tempDir;
    late SplendidCommandRunner runner;

    /// Set up test environment with temporary directory and command runner.
    ///
    /// Creates a fresh temporary directory for each test to ensure isolation
    /// and prevent interference between tests. The temporary directory is
    /// automatically cleaned up after each test completes.
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('org_flag_integration_');
      runner = SplendidCommandRunner();
    });

    /// Clean up test resources after each test.
    ///
    /// Removes the temporary directory and all its contents to prevent disk
    /// space accumulation during test runs.
    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Tests that the --org flag correctly sets Android application ID.
    ///
    /// This test creates a Flutter project with a custom organization and
    /// verifies that the Android build configuration contains the correct
    /// application ID and namespace based on the provided organization.
    test('should set Android application ID with custom organization', () async {
      const String projectName = 'android_org_test';
      const String customOrg = 'io.github.testuser';

      final int exitCode = await runner.run([
        'create',
        projectName,
        '--org=$customOrg',
        '--platforms=android',
        '--output-directory=${tempDir.path}',
        '--force',
      ]);

      expect(exitCode, equals(0), reason: 'Project creation should succeed');

      // Verify Android configuration contains correct organization
      final File buildFile = File(path.join(tempDir.path, projectName, 'android', 'app', 'build.gradle.kts'));
      expect(buildFile.existsSync(), isTrue, reason: 'Android build file should exist');

      final String buildContent = buildFile.readAsStringSync();
      expect(
        buildContent,
        contains('namespace = "$customOrg.$projectName"'),
        reason: 'Android namespace should include custom organization',
      );
      expect(
        buildContent,
        contains('applicationId = "$customOrg.$projectName"'),
        reason: 'Android application ID should include custom organization',
      );
    }, skip: 'Requires Flutter CLI and may be slow');

    /// Tests that the --org flag correctly sets iOS bundle identifier.
    ///
    /// This test creates a Flutter project with a custom organization and
    /// verifies that the iOS project configuration contains the correct bundle
    /// identifier based on the provided organization.
    test('should set iOS bundle identifier with custom organization', () async {
      const String projectName = 'ios_org_test';
      const String customOrg = 'com.mycompany.mobile';

      final int exitCode = await runner.run([
        'create',
        projectName,
        '--org=$customOrg',
        '--platforms=ios',
        '--output-directory=${tempDir.path}',
        '--force',
      ]);

      expect(exitCode, equals(0), reason: 'Project creation should succeed');

      // Verify iOS configuration contains correct organization
      final File projectFile = File(
        path.join(
          tempDir.path,
          projectName,
          'ios',
          'Runner.xcodeproj',
          'project.pbxproj',
        ),
      );
      expect(projectFile.existsSync(), isTrue, reason: 'iOS project file should exist');

      final String projectContent = projectFile.readAsStringSync();
      expect(
        projectContent,
        contains('PRODUCT_BUNDLE_IDENTIFIER = $customOrg.$projectName'),
        reason: 'iOS bundle identifier should include custom organization',
      );
    }, skip: 'Requires Flutter CLI and may be slow');

    /// Tests that default organization is used when --org flag is not provided.
    ///
    /// This test verifies that when no custom organization is specified, the
    /// default 'com.example' organization is properly applied to the generated
    /// project configuration.
    test('should use default organization when --org flag not provided', () async {
      const String projectName = 'default_org_test';

      final int exitCode = await runner.run([
        'create',
        projectName,
        '--platforms=android',
        '--output-directory=${tempDir.path}',
        '--force',
      ]);

      expect(exitCode, equals(0), reason: 'Project creation should succeed');

      // Verify default organization is used
      final File buildFile = File(path.join(tempDir.path, projectName, 'android', 'app', 'build.gradle.kts'));
      expect(buildFile.existsSync(), isTrue, reason: 'Android build file should exist');

      final String buildContent = buildFile.readAsStringSync();
      expect(
        buildContent,
        contains('namespace = "com.example.$projectName"'),
        reason: 'Should use default com.example organization',
      );
      expect(
        buildContent,
        contains('applicationId = "com.example.$projectName"'),
        reason: 'Should use default com.example organization',
      );
    }, skip: 'Requires Flutter CLI and may be slow');

    /// Tests that invalid organization formats are rejected with helpful error
    /// messages.
    ///
    /// This test verifies that the command properly validates organization
    /// format and provides clear error messages when invalid formats are
    /// provided, helping users understand the expected format.
    test('should reject invalid organization formats with helpful errors', () async {
      const String projectName = 'invalid_org_test';
      final List<String> invalidOrganizations = [
        'invalid',
        'com',
        'com.',
        '.com.example',
        'com..example',
      ];

      for (final String invalidOrg in invalidOrganizations) {
        final int exitCode = await runner.run([
          'create',
          projectName,
          '--org=$invalidOrg',
          '--output-directory=${tempDir.path}',
          '--force',
        ]);

        expect(
          exitCode,
          equals(64),
          reason: 'Invalid organization "$invalidOrg" should return usage error',
        );
      }
    });

    /// Tests that organization validation works with different platform
    /// combinations.
    ///
    /// This test ensures that the organization flag works correctly regardless
    /// of which platforms are enabled, verifying that the validation and
    /// application logic is platform-agnostic.
    test('should work with different platform combinations', () async {
      const String projectName = 'multi_platform_test';
      const String customOrg = 'edu.university.department';

      final List<String> platformCombinations = [
        'android',
        'ios',
        'web',
        'android,ios',
        'android,web',
        'ios,web',
      ];

      for (final String platforms in platformCombinations) {
        final int exitCode = await runner.run([
          'create',
          '${projectName}_${platforms.replaceAll(',', '_')}',
          '--org=$customOrg',
          '--platforms=$platforms',
          '--output-directory=${tempDir.path}',
          '--force',
        ]);

        expect(
          exitCode,
          equals(0),
          reason: 'Project creation should succeed for platforms: $platforms',
        );
      }
    }, skip: 'Requires Flutter CLI and may be slow');
  });
}
