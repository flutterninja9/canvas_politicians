import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TemplatePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> editedJson;
  final int templateId;
  const TemplatePreviewScreen({
    super.key,
    required this.editedJson,
    required this.templateId,
  });

  Future<Uint8List?> _getUpdatedImageBytes() async {
    return Uint8List.fromList(
        await apiService.generatePreviewImage(templateId, editedJson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Template")),
      body: FutureBuilder<Uint8List?>(
        future: _getUpdatedImageBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("No preview available"));
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 400,
                width: 499,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
      ),
    );
  }
}
