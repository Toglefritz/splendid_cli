import 'dart:io';

import 'enum_sorter_error_type.dart';
import 'enum_sorter_exception.dart';
import 'enum_sorter_request.dart';
import 'enum_sorter_result.dart';
import 'sort_outcome.dart';

part 'enum_value.dart';
part 'split_body.dart';

/// Service for sorting Dart enum values alphabetically by name.
///
/// This service processes Dart source files containing enum declarations and
/// reorders the enum values alphabetically while preserving all other aspects
/// of the enum, including:
/// * Documentation comments on individual values
/// * Constructor arguments and named parameters
/// * Static methods, fields, and constructors defined in the enum body
/// * Trailing semicolons on the last enum value (for enhanced enums)
/// * Documentation comments above the enum declaration itself
///
/// Supports both simple enums:
/// ```dart
/// enum Color {
///   red,
///   green,
///   blue,
/// }
/// ```
///
/// And enhanced enums with fields, constructors, and methods:
/// ```dart
/// enum Priority {
///   high(value: 3),
///   low(value: 1),
///   medium(value: 2);
///
///   final int value;
///   const Priority({required this.value});
/// }
/// ```
///
/// Sorting Behavior:
/// * Only the enum value declarations are reordered
/// * Members after the semicolon (fields, constructors, methods) are untouched
/// * Leading documentation comments on each value travel with their value
/// * The trailing punctuation (comma or semicolon) of the last value is
///   preserved correctly after reordering
///
/// Thread Safety: This service performs file I/O operations and is not
/// thread-safe for concurrent operations on the same file.
class EnumSorterService {
  /// Creates a new instance of [EnumSorterService].
  const EnumSorterService();

  /// Sorts enum values in the specified Dart file alphabetically.
  ///
  /// Reads the file, identifies all enum declarations, sorts their values,
  /// and optionally writes the result back to disk.
  ///
  /// Parameters:
  /// * [request] - Configuration for the sorting operation
  ///
  /// Returns an [EnumSorterResult] containing statistics and any errors.
  ///
  /// Throws [EnumSorterException] for critical errors like missing targets or
  /// invalid file types.
  Future<EnumSorterResult> sortEnums(EnumSorterRequest request) async {
    final File targetFile = File(request.targetPath);

    if (!targetFile.existsSync()) {
      throw EnumSorterException(
        'Target path does not exist: ${request.targetPath}',
        EnumSorterErrorType.targetNotFound,
      );
    }

    if (!request.targetPath.endsWith('.dart')) {
      throw const EnumSorterException(
        'Target file must be a .dart file',
        EnumSorterErrorType.invalidFileType,
      );
    }

    final List<String> errors = <String>[];

    try {
      final String content = await targetFile.readAsString();
      final SortOutcome outcome = _sortAllEnums(content);

      if (outcome.enumsFound == 0) {
        throw const EnumSorterException(
          'No enum declarations found in the target file',
          EnumSorterErrorType.noEnumsFound,
        );
      }

      if (outcome.enumsSorted > 0 && !request.dryRun) {
        await targetFile.writeAsString(outcome.content);
      }

      return EnumSorterResult(
        filePath: request.targetPath,
        enumsFound: outcome.enumsFound,
        enumsSorted: outcome.enumsSorted,
        errors: errors,
        dryRun: request.dryRun,
      );
    } catch (e) {
      if (e is EnumSorterException) rethrow;
      errors.add(e.toString());

      return EnumSorterResult(
        filePath: request.targetPath,
        enumsFound: 0,
        enumsSorted: 0,
        errors: errors,
        dryRun: request.dryRun,
      );
    }
  }

  /// Processes the entire file content, finding and sorting all enums.
  ///
  /// Iterates through the file looking for enum declarations, extracts each
  /// enum body, sorts the values, and reconstructs the file content.
  ///
  /// Parameters:
  /// * [content] - The full Dart source file content
  ///
  /// Returns a [SortOutcome] with the potentially modified content and counts.
  SortOutcome _sortAllEnums(String content) {
    int enumsFound = 0;
    int enumsSorted = 0;
    String result = content;

    // Pattern to match enum declarations, including those preceded by
    // documentation comments. The enum keyword may be preceded by whitespace
    // or appear at the start of a line.
    final RegExp enumPattern = RegExp(
      r'enum\s+\w+[^{]*\{',
      multiLine: true,
    );

    // Process enums from last to first so that string indices remain valid
    // after each replacement.
    final List<RegExpMatch> matches = enumPattern.allMatches(result).toList();

    for (int i = matches.length - 1; i >= 0; i--) {
      final RegExpMatch match = matches[i];
      final int bodyStart = match.end;
      final int? bodyEnd = _findMatchingBrace(result, bodyStart - 1);

      if (bodyEnd == null) continue;

      enumsFound++;

      final String enumBody = result.substring(bodyStart, bodyEnd);
      final String sortedBody = _sortEnumBody(enumBody);

      if (sortedBody != enumBody) {
        enumsSorted++;
        result = result.substring(0, bodyStart) + sortedBody + result.substring(bodyEnd);
      }
    }

    return SortOutcome(
      content: result,
      enumsFound: enumsFound,
      enumsSorted: enumsSorted,
    );
  }

  /// Finds the index of the closing brace that matches the opening brace at
  /// [openIndex].
  ///
  /// Handles nested braces correctly by tracking brace depth.
  ///
  /// Parameters:
  /// * [content] - The source string to search
  /// * [openIndex] - Index of the opening brace character
  ///
  /// Returns the index of the matching closing brace, or null if not found.
  int? _findMatchingBrace(String content, int openIndex) {
    int depth = 1;
    for (int i = openIndex + 1; i < content.length; i++) {
      final String char = content[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }

  /// Sorts the values within a single enum body.
  ///
  /// This method separates the enum values section from the members section
  /// (fields, constructors, methods that appear after the semicolon), sorts
  /// only the values, and reassembles the body.
  ///
  /// For simple enums the values end with a trailing comma. For enhanced enums
  /// the last value ends with a semicolon followed by member declarations.
  ///
  /// Parameters:
  /// * [body] - The content between the opening and closing braces of the enum
  ///
  /// Returns the body with enum values sorted alphabetically.
  String _sortEnumBody(String body) {
    // Split the body into the values section and the members section.
    // The members section starts after the first semicolon that terminates
    // the enum values list.
    final _SplitBody split = _splitValuesAndMembers(body);

    final List<_EnumValue> values = _parseEnumValues(split.valuesSection);

    if (values.isEmpty) return body;

    // Check if already sorted.
    final List<String> names = values.map((v) => v.name).toList();
    final List<String> sortedNames = List<String>.from(names)..sort();
    if (_listEquals(names, sortedNames)) return body;

    // Sort values alphabetically by name.
    values.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    // Reconstruct the values section.
    final StringBuffer buffer = StringBuffer()..write('\n');

    for (int i = 0; i < values.length; i++) {
      final _EnumValue value = values[i];
      final bool isLast = i == values.length - 1;

      // Write leading doc comments.
      if (value.documentation.isNotEmpty) {
        buffer.write(value.documentation);
      }

      // Write the value declaration with appropriate trailing punctuation.
      if (isLast) {
        buffer.writeln(
          '${value.indent}${value.declaration}${split.hasMembers ? ';' : ','}',
        );
      } else {
        buffer.writeln('${value.indent}${value.declaration},');
      }
    }

    // Reassemble with members section if present.
    if (split.hasMembers) {
      buffer.write(split.membersSection);
    }

    return buffer.toString();
  }

  /// Splits the enum body into the values section and the members section.
  ///
  /// The members section begins after the semicolon that terminates the last
  /// enum value. For simple enums there is no members section.
  ///
  /// Parameters:
  /// * [body] - The content between the enum braces
  ///
  /// Returns a [_SplitBody] containing both sections.
  _SplitBody _splitValuesAndMembers(String body) {
    // Walk through the body character by character, tracking brace and
    // parenthesis depth. A semicolon at depth 0 marks the boundary between
    // enum values and enum members.
    int depth = 0;
    for (int i = 0; i < body.length; i++) {
      final String char = body[i];
      if (char == '(' || char == '{' || char == '[') {
        depth++;
      } else if (char == ')' || char == '}' || char == ']') {
        depth--;
      } else if (char == ';' && depth == 0) {
        return _SplitBody(
          valuesSection: body.substring(0, i),
          membersSection: body.substring(i + 1),
          hasMembers: true,
        );
      }
    }

    // No semicolon found — simple enum with only values.
    return _SplitBody(
      valuesSection: body,
      membersSection: '',
      hasMembers: false,
    );
  }

  /// Parses individual enum value declarations from the values section.
  ///
  /// Each value may be preceded by documentation comments and may include
  /// constructor arguments. Values are separated by commas at depth 0.
  ///
  /// Parameters:
  /// * [valuesSection] - The portion of the enum body containing only values
  ///
  /// Returns a list of parsed [_EnumValue] objects.
  List<_EnumValue> _parseEnumValues(String valuesSection) {
    final List<_EnumValue> values = <_EnumValue>[];
    final List<String> lines = valuesSection.split('\n');

    final StringBuffer docBuffer = StringBuffer();
    final StringBuffer declBuffer = StringBuffer();
    String currentIndent = '';
    int depth = 0;
    bool inDeclaration = false;

    for (final String line in lines) {
      final String trimmed = line.trimLeft();

      // Skip blank lines between values when not in a declaration.
      if (trimmed.isEmpty && !inDeclaration) {
        if (docBuffer.isNotEmpty) {
          docBuffer.write('\n');
        }
        continue;
      }

      // Accumulate documentation comment lines.
      if (trimmed.startsWith('///') && !inDeclaration) {
        docBuffer.writeln(line);
        continue;
      }

      // Skip non-doc comment lines (regular comments).
      if (trimmed.startsWith('//') && !trimmed.startsWith('///') && !inDeclaration) {
        continue;
      }

      // Start or continue a value declaration.
      if (!inDeclaration) {
        currentIndent = line.substring(
          0,
          line.length - line.trimLeft().length,
        );
      }

      inDeclaration = true;
      declBuffer.write(trimmed);

      // Track parenthesis depth to handle multi-line constructor calls.
      for (int i = 0; i < trimmed.length; i++) {
        final String char = trimmed[i];
        if (char == '(' || char == '[' || char == '{') {
          depth++;
        } else if (char == ')' || char == ']' || char == '}') {
          depth--;
        }
      }

      // A value declaration ends when we reach depth 0.
      if (depth == 0) {
        String declaration = declBuffer.toString().trim();
        if (declaration.endsWith(',')) {
          declaration = declaration.substring(0, declaration.length - 1);
        }

        if (declaration.isNotEmpty) {
          final RegExp namePattern = RegExp(r'^(\w+)');
          final RegExpMatch? nameMatch = namePattern.firstMatch(declaration);

          if (nameMatch != null) {
            values.add(
              _EnumValue(
                name: nameMatch.group(1)!,
                declaration: declaration,
                documentation: docBuffer.toString(),
                indent: currentIndent,
              ),
            );
          }
        }

        docBuffer.clear();
        declBuffer.clear();
        currentIndent = '';
        inDeclaration = false;
      } else {
        // Multi-line declaration — add a space before the next line.
        declBuffer.write(' ');
      }
    }

    return values;
  }

  /// Compares two lists for element-wise equality.
  ///
  /// Parameters:
  /// * [a] - First list
  /// * [b] - Second list
  ///
  /// Returns true if both lists have the same length and identical elements
  /// at every index.
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
