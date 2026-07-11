/// Unused Localization Detection Service Library
///
/// This library provides functionality for detecting localization keys defined
/// in ARB files that are not referenced in any Dart source file within a
/// Flutter project. Useful for identifying abandoned translation strings that
/// can be safely removed to reduce maintenance burden.
///
/// Main exports:
/// * `UnusedL10nService` - Core service for detection operations
/// * `UnusedL10nRequest` - Request configuration
/// * `UnusedL10nResult` - Operation results
/// * `UnusedL10nInfo` - Information about a single unused key
/// * `UnusedL10nException` - Exception type for errors
/// * `UnusedL10nErrorType` - Error categories
library;

export 'unused_l10n_service/unused_l10n_error_type.dart';
export 'unused_l10n_service/unused_l10n_exception.dart';
export 'unused_l10n_service/unused_l10n_info.dart';
export 'unused_l10n_service/unused_l10n_request.dart';
export 'unused_l10n_service/unused_l10n_result.dart';
export 'unused_l10n_service/unused_l10n_service.dart';
