// lib/widgets/native_editor.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import conditionally based on platform
import 'native_editor_mobile.dart' if (dart.library.html) 'native_editor_web.dart'
    as platform_editor;

class NativeEditor extends StatelessWidget {
  final Map<String, dynamic> template;

  const NativeEditor({
    Key? key,
    required this.template,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use appropriate implementation based on platform
    return platform_editor.PlatformEditor(template: template);
  }
}