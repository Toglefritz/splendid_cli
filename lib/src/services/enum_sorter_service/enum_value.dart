part of 'enum_sorter_service.dart';

/// Internal representation of a single enum value with its metadata.
///
/// Captures all the information needed to reconstruct the value declaration
/// in its sorted position, including documentation and indentation.
class _EnumValue {
  /// Creates a new enum value representation.
  ///
  /// Parameters:
  /// * [name] - The identifier name of the enum value
  /// * [declaration] - The full declaration text (without trailing comma)
  /// * [documentation] - Any leading documentation comment lines
  /// * [indent] - The whitespace indentation prefix
  const _EnumValue({
    required this.name,
    required this.declaration,
    required this.documentation,
    required this.indent,
  });

  /// The identifier name of the enum value (e.g., "firstItem").
  final String name;

  /// The full declaration text without trailing comma or semicolon.
  ///
  /// For simple enums this is just the name. For enhanced enums this includes
  /// constructor arguments, e.g., "firstItem(namedParam: 'value')".
  final String declaration;

  /// Leading documentation comment lines including newlines.
  ///
  /// Empty string if the value has no documentation.
  final String documentation;

  /// The whitespace indentation prefix for this value.
  final String indent;
}
