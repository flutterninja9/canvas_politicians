import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'template_edit_screen.dart';
import '../providers/template_provider.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Select Template")),
      body: templates.when(
        data: (templates) => ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              title: Text(template['name']),
              leading: Image.network(template['image'], width: 50, height: 50),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateEditScreen(template: template),
                ),
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) {
          if (err is DioException) {
            print((err.requestOptions.uri.toString()));
            print((_.toString()));
          }
          print((err.toString()));
          print((_.toString()));
          return Center(child: Text("Error loading templates"));
        },
      ),
    );
  }
}
