/// Categories of errors that can occur during unused class detection.
///
/// Used to determine appropriate exit codes and error handling strategies.
enum UnusedClassesErrorType {
  /// Target directory does not exist.
  targetNotFound,

  /// Target path is not a directory.
  invalidTarget,

  /// No Dart files found in the target directory.
  noDartFilesFound,

  /// Permission denied when accessing files.
  permissionDenied,

  /// Unknown or unexpected error.
  unknown,
}
