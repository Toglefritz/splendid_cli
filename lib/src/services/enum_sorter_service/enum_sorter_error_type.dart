/// Categories of errors that can occur during enum sorting.
///
/// Used to determine appropriate exit codes and error handling strategies.
enum EnumSorterErrorType {
  /// Target file or directory does not exist.
  targetNotFound,

  /// Target is not a valid .dart file.
  invalidFileType,

  /// No enum declarations found in the target file.
  noEnumsFound,

  /// Permission denied when accessing files.
  permissionDenied,

  /// Unknown or unexpected error.
  unknown,
}
