import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/native_editor.dart';
import '../providers/template_provider.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  void _navigateToEditor(BuildContext context, Map<String, dynamic> template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NativeEditor(template: template),
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
        error: (err, _) => const Center(child: Text("Error loading templates")),
      ),
    );
  }
}
