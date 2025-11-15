/// Categories of errors that can occur during L10n sorting.
///
/// Used to determine appropriate exit codes and error handling strategies.
enum L10nSorterErrorType {
  /// Target file or directory does not exist.
  targetNotFound,

  /// Target is not a valid .arb file.
  invalidFileType,

  /// No .arb files found in target directory.
  noFilesFound,

  /// Permission denied when accessing files.
  permissionDenied,

  /// Unknown or unexpected error.
  unknown,
}
