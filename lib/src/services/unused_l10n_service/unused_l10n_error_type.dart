/// Categories of errors that can occur during unused localization detection.
///
/// Used to determine appropriate exit codes and error handling strategies.
enum UnusedL10nErrorType {
  /// The specified ARB file does not exist.
  arbFileNotFound,

  /// The source directory does not exist.
  sourceNotFound,

  /// The ARB file could not be parsed as valid JSON.
  invalidArbFormat,

  /// No localization keys found in the ARB file.
  noKeysFound,

  /// No Dart source files found in the source directory.
  noDartFilesFound,

  /// Permission denied when accessing files.
  permissionDenied,

  /// Unknown or unexpected error.
  unknown,
}
