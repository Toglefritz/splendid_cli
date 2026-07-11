/// Information about a single unused localization key detected in the project.
///
/// Contains the key name and its description (if available from the ARB file),
/// providing enough context for a developer to evaluate whether the key should
/// be removed or is intentionally preserved for future use.
class UnusedL10nInfo {
  /// Creates a new unused localization key information record.
  ///
  /// Parameters:
  /// * [key] - The ARB localization key that appears unused
  /// * [description] - Optional description from the ARB file's `@` metadata
  const UnusedL10nInfo({
    required this.key,
    this.description,
  });

  /// The localization key that appears unused.
  final String key;

  /// Description from the ARB file's `@key` metadata, if present.
  ///
  /// Helps developers understand the original purpose of the key when
  /// deciding whether to remove it.
  final String? description;

  @override
  String toString() => description != null ? '$key — $description' : key;
}
