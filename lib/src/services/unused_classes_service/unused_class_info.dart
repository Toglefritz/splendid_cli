/// Information about a single unused class detected in the project.
///
/// Contains the class name and the file path where it is declared, providing
/// enough context for a developer to locate and evaluate whether the class
/// should be removed or is intentionally unused.
class UnusedClassInfo {
  /// Creates a new unused class information record.
  ///
  /// Parameters:
  /// * [className] - The name of the class that appears unused
  /// * [filePath] - The file path where the class is declared
  const UnusedClassInfo({
    required this.className,
    required this.filePath,
  });

  /// The name of the unused class.
  final String className;

  /// The file path where the class is declared.
  final String filePath;

  @override
  String toString() => '$className ($filePath)';
}
