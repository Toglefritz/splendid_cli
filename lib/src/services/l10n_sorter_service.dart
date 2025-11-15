/// L10n Sorter Service Library
///
/// This library provides functionality for sorting Flutter localization (.arb) files
/// alphabetically while preserving the relationship between value entries and their
/// metadata entries.
///
/// Main exports:
/// * [L10nSorterService] - Core service for sorting operations
/// * [L10nSorterRequest] - Request configuration
/// * [L10nSorterResult] - Operation results
/// * [L10nSorterException] - Exception type for errors
/// * [L10nSorterErrorType] - Error categories
library;

import '../../splendid_cli.dart';

export 'l10n_sorter_service/l10n_sorter_error_type.dart';
export 'l10n_sorter_service/l10n_sorter_exception.dart';
export 'l10n_sorter_service/l10n_sorter_request.dart';
export 'l10n_sorter_service/l10n_sorter_result.dart';
export 'l10n_sorter_service/l10n_sorter_service.dart';
