// lib/screens/template_preview_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/responsive_utils.dart';

class TemplatePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> editedJson;
  final int templateId;
  final Size viewportSize;

  const TemplatePreviewScreen({
    super.key,
    required this.editedJson,
    required this.templateId,
    required this.viewportSize,
  });

  Future<Uint8List?> _getUpdatedImageBytes() async {
    // Add viewport information to the request
    final jsonWithViewport = Map<String, dynamic>.from(editedJson);
    jsonWithViewport['target_width'] = viewportSize.width.toInt();
    jsonWithViewport['target_height'] = viewportSize.height.toInt();

    return Uint8List.fromList(
      await apiService.generatePreviewImage(templateId, jsonWithViewport),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Template"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Download functionality coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Share functionality coming soon!")),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewSize = ResponsiveUtils.calculateViewportSize(
            constraints,
            viewportSize.width / viewportSize.height,
          );

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<Uint8List?>(
                  future: _getUpdatedImageBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const Text("No preview available");
                    }

                    return Container(
                      width: previewSize.width,
                      height: previewSize.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Preview Size: ${previewSize.width.toInt()}x${previewSize.height.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
