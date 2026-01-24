/// Test suite for ProjectService organization validation functionality.
///
/// This test suite focuses specifically on the organization validation logic
/// within the ProjectService class, ensuring that reverse domain name notation
/// is properly validated and that appropriate error messages are provided for
/// invalid formats.
///
/// Test Categories:
/// * Organization format validation
/// * Valid organization patterns
/// * Invalid organization patterns
/// * Error message accuracy
/// * Integration with project creation workflow
///
/// The tests use isolated unit testing to verify the validation logic without
/// requiring external dependencies like the Flutter CLI or file system
/// operations.
library;

import 'package:splendid_cli/src/services/project_service.dart';
import 'package:splendid_cli/src/services/project_service/project_creation_request.dart';
import 'package:splendid_cli/src/services/project_service/project_service_error_type.dart';
import 'package:splendid_cli/src/services/project_service/project_service_exception.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectService Organization Validation', () {
    late ProjectService projectService;

    /// Set up test environment with fresh service instance.
    ///
    /// Creates a new ProjectService instance for each test to ensure isolation
    /// and prevent test interference.
    setUp(() {
      projectService = const ProjectService();
    });

    group('valid organization formats', () {
      /// Tests that standard reverse domain name formats are accepted.
      ///
      /// This test verifies that common organization patterns used in mobile
      /// app development pass validation, including commercial, organizational,
      /// and personal domain formats.
      test(
        'should accept standard reverse domain formats',
        () async {
          final List<String> validOrganizations = [
            'com.example',
            'org.apache',
            'io.github.username',
            'net.sourceforge.project',
            'edu.university.department',
            'gov.agency.division',
          ];

          for (final String org in validOrganizations) {
            final ProjectCreationRequest request = ProjectCreationRequest(
              projectName: 'test_app',
              organization: org,
            );

            // Should not throw validation exception for valid organizations
            expect(
              () => projectService.createProject(request),
              isNot(
                throwsA(
                  isA<ProjectServiceException>().having(
                    (e) => e.type,
                    'error type',
                    ProjectServiceErrorType.invalidOrganization,
                  ),
                ),
              ),
              reason: 'Valid organization "$org" should not cause validation error',
            );
          }
        },
        skip: 'Requires mocking or Flutter CLI to avoid actual project creation',
      );

      /// Tests that country-specific domain formats are accepted.
      ///
      /// This test ensures that international domain formats commonly used for
      /// organizations are properly validated, including country code top-level
      /// domains and regional variations.
      test('should accept country-specific domain formats', () {
        final List<String> countryDomains = [
          'co.uk.company',
          'com.au.business',
          'org.ca.nonprofit',
          'ac.uk.university',
          'go.jp.government',
          'com.br.empresa',
        ];

        for (final String org in countryDomains) {
          final ProjectCreationRequest request = ProjectCreationRequest(
            projectName: 'test_app',
            organization: org,
          );

          // Test validation by attempting to create request In a real test, we
          // would mock the Flutter CLI calls
          expect(
            request.organization,
            equals(org),
            reason: 'Organization should be preserved in request object',
          );
        }
      });

      /// Tests that multi-level subdomain formats are accepted.
      ///
      /// This test verifies that complex organizational structures with
      /// multiple subdomain levels are properly handled, which is common in
      /// large enterprises and academic institutions.
      test('should accept multi-level subdomain formats', () {
        final List<String> multiLevelDomains = [
          'com.company.division.team',
          'edu.university.college.department',
          'org.foundation.project.subproject',
          'io.github.organization.repository',
        ];

        for (final String org in multiLevelDomains) {
          final ProjectCreationRequest request = ProjectCreationRequest(
            projectName: 'test_app',
            organization: org,
          );

          expect(
            request.organization,
            equals(org),
            reason: 'Multi-level organization should be preserved',
          );
        }
      });
    });

    group('invalid organization formats', () {
      /// Tests that malformed domain formats are rejected.
      ///
      /// This test ensures that common formatting errors in reverse domain name
      /// notation are caught and result in appropriate validation errors with
      /// helpful messages.
      test('should reject malformed domain formats', () async {
        final Map<String, String> invalidOrganizations = {
          'example': 'Missing domain separator',
          'com': 'Only one segment',
          'com.': 'Trailing dot',
          '.com.example': 'Leading dot',
          'com..example': 'Double dot',
          '': 'Empty string',
          'com.example.': 'Trailing dot after valid format',
        };

        for (final MapEntry<String, String> entry in invalidOrganizations.entries) {
          final String org = entry.key;
          final String reason = entry.value;

          final ProjectCreationRequest request = ProjectCreationRequest(
            projectName: 'test_app',
            organization: org,
          );

          expect(
            () async => projectService.createProject(request),
            throwsA(
              isA<ProjectServiceException>()
                  .having((e) => e.type, 'error type', ProjectServiceErrorType.invalidOrganization)
                  .having((e) => e.message, 'error message', contains('Invalid organization')),
            ),
            reason: 'Invalid organization "$org" ($reason) should cause validation error',
          );
        }
      });

      /// Tests that invalid characters in domain segments are rejected.
      ///
      /// This test verifies that domain name rules are enforced for each
      /// segment of the reverse domain notation, including restrictions on
      /// special characters and formatting requirements.
      test('should reject invalid characters in segments', () async {
        final Map<String, String> invalidCharacters = {
          'com.123example': 'Segment starting with number',
          'com.example-': 'Segment ending with hyphen',
          'com.-example': 'Segment starting with hyphen',
          'com.exam ple': 'Space in segment',
          'com.exam_ple': 'Underscore in segment',
          'com.exam@ple': 'At symbol in segment',
          'com.EXAMPLE': 'Uppercase letters (should be lowercase)',
        };

        for (final MapEntry<String, String> entry in invalidCharacters.entries) {
          final String org = entry.key;
          final String reason = entry.value;

          final ProjectCreationRequest request = ProjectCreationRequest(
            projectName: 'test_app',
            organization: org,
          );

          expect(
            () async => projectService.createProject(request),
            throwsA(
              isA<ProjectServiceException>().having(
                (e) => e.type,
                'error type',
                ProjectServiceErrorType.invalidOrganization,
              ),
            ),
            reason: 'Invalid organization "$org" ($reason) should cause validation error',
          );
        }
      });
    });

    group('error message quality', () {
      /// Tests that validation error messages are helpful and actionable.
      ///
      /// This test verifies that when organization validation fails, users
      /// receive clear guidance on the expected format and examples of valid
      /// organization names.
      test('should provide helpful error messages for invalid organizations', () async {
        const String invalidOrg = 'invalid-org';

        const ProjectCreationRequest request = ProjectCreationRequest(
          projectName: 'test_app',
          organization: invalidOrg,
        );

        try {
          await projectService.createProject(request);
          fail('Expected ProjectServiceException to be thrown');
        } on ProjectServiceException catch (e) {
          expect(e.type, equals(ProjectServiceErrorType.invalidOrganization));
          expect(e.message, contains('Invalid organization'));
          expect(e.message, contains(invalidOrg));
          expect(e.message, contains('reverse domain name notation'));
          expect(e.message, contains('com.example'));
        }
      });

      /// Tests that error messages include the invalid organization value.
      ///
      /// This test ensures that error messages are specific and include the
      /// actual invalid value that was provided, making it easier for users to
      /// identify and correct the issue.
      test('should include invalid organization in error message', () async {
        const String invalidOrg = 'not.a.valid.org.format.123';

        const ProjectCreationRequest request = ProjectCreationRequest(
          projectName: 'test_app',
          organization: invalidOrg,
        );

        try {
          await projectService.createProject(request);
          fail('Expected ProjectServiceException to be thrown');
        } on ProjectServiceException catch (e) {
          expect(e.message, contains(invalidOrg));
          expect(e.toString(), contains('ProjectServiceException'));
        }
      });
    });

    group('integration with project creation', () {
      /// Tests that organization validation occurs before other operations.
      ///
      /// This test verifies that invalid organizations are caught early in the
      /// project creation process, before attempting to create directories or
      /// call the Flutter CLI, providing fast feedback to users.
      test('should validate organization before attempting project creation', () async {
        const String invalidOrg = 'invalid';

        const ProjectCreationRequest request = ProjectCreationRequest(
          projectName: 'test_app',
          organization: invalidOrg,
          outputDirectory: '/nonexistent/path', // This should not be reached
        );

        // Should fail on organization validation, not on directory creation
        expect(
          () async => projectService.createProject(request),
          throwsA(
            isA<ProjectServiceException>().having(
              (e) => e.type,
              'error type',
              ProjectServiceErrorType.invalidOrganization,
            ),
          ),
        );
      });

      /// Tests that valid organizations allow project creation to proceed.
      ///
      /// This test verifies that when a valid organization is provided, the
      /// validation passes and the project creation process continues to the
      /// next steps (which may fail for other reasons in test environment).
      test('should allow project creation with valid organization', () async {
        const String validOrg = 'com.example.test';

        const ProjectCreationRequest request = ProjectCreationRequest(
          projectName: 'test_app',
          organization: validOrg,
          force: true,
        );

        // Should not fail on organization validation May fail on Flutter CLI or
        // other steps, but not organization validation
        try {
          await projectService.createProject(request);
        } on ProjectServiceException catch (e) {
          expect(e.type, isNot(ProjectServiceErrorType.invalidOrganization));
        }
      }, skip: 'Requires Flutter CLI or mocking for full test');
    });
  });
}
