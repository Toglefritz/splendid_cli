/// Unused Classes Detection Service Library
///
/// This library provides functionality for detecting class declarations in a
/// Dart project that are not referenced by any other file in the codebase.
/// Useful for identifying abandoned or dead code that can be safely removed.
///
/// Main exports:
/// * `UnusedClassesService` - Core service for detection operations
/// * `UnusedClassesRequest` - Request configuration
/// * `UnusedClassesResult` - Operation results
/// * `UnusedClassInfo` - Information about a single unused class
/// * `UnusedClassesException` - Exception type for errors
/// * `UnusedClassesErrorType` - Error categories
library;

export 'unused_classes_service/unused_class_info.dart';
export 'unused_classes_service/unused_classes_error_type.dart';
export 'unused_classes_service/unused_classes_exception.dart';
export 'unused_classes_service/unused_classes_request.dart';
export 'unused_classes_service/unused_classes_result.dart';
export 'unused_classes_service/unused_classes_service.dart';
