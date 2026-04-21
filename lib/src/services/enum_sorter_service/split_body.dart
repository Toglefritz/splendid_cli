part of 'enum_sorter_service.dart';

/// Internal result of splitting an enum body into values and members sections.
class _SplitBody {
  /// Creates a new split body result.
  const _SplitBody({
    required this.valuesSection,
    required this.membersSection,
    required this.hasMembers,
  });

  /// The portion of the enum body containing value declarations.
  final String valuesSection;

  /// The portion of the enum body after the semicolon (fields, constructors,
  /// methods). Empty string for simple enums.
  final String membersSection;

  /// Whether the enum has a members section (enhanced enum).
  final bool hasMembers;
}
