import 'package:flutter/material.dart';
import '{{name.snakeCase()}}_controller.dart';

/// Route widget for the {{name.lowerCase()}} screen.
///
/// Following MVC patterns, this route serves only as the entry point and
/// delegates all logic to the [{{name.pascalCase()}}Controller] through
/// `createState()`.
class {{name.pascalCase()}}Route extends StatefulWidget {
  /// Creates the {{name.lowerCase()}} route widget.
  const {{name.pascalCase()}}Route({super.key});

  @override
  State<{{name.pascalCase()}}Route> createState() => {{name.pascalCase()}}Controller();
}