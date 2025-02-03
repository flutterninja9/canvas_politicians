// lib/screens/template_list_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'template_edit_screen.dart';  // Old editor
import 'web_template_editor.dart';   // New web-based editor
import '../providers/template_provider.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  void _navigateToEditor(BuildContext context, Map<String, dynamic> template) {
    // For now, let's add a choice dialog to test both editors
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Editor'),
        content: const Text('Which editor would you like to use?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateEditScreen(template: template),
                ),
              );
            },
            child: const Text('Original Editor'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WebTemplateEditor(template: template),
                ),
              );
            },
            child: const Text('New Web Editor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Template")),
      body: templates.when(
        data: (templates) => ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              title: Text(template['name']),
              leading: Image.network(template['image'], width: 50, height: 50),
              onTap: () => _navigateToEditor(context, template),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          if (err is DioException) {
            print((err.requestOptions.uri.toString()));
            print((_.toString()));
          }
          print((err.toString()));
          print((_.toString()));
          return const Center(child: Text("Error loading templates"));
        },
      ),
    );
  }
}