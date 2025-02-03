// lib/screens/web_template_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';

class WebTemplateEditor extends StatefulWidget {
  final Map<String, dynamic> template;

  const WebTemplateEditor({
    super.key,
    required this.template,
  });

  @override
  _WebTemplateEditorState createState() => _WebTemplateEditorState();
}

class _WebTemplateEditorState extends State<WebTemplateEditor> {
  InAppWebViewController? _webViewController;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://mellow-entremet-47f87d.netlify.app/'),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;

              // Set up JavaScript handler
              controller.addJavaScriptHandler(
                handlerName: 'flutterHandler',
                callback: (args) {
                  final message = json.decode(args[0]);
                  _handleWebMessage(message);
                },
              );
            },
            onLoadStop: (controller, url) {
              setState(() => isLoading = false);
              _initializeEditor();
            },
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _initializeEditor() {
    // Send template data to web editor
    _webViewController?.postWebMessage(
      message: WebMessage(
          data: json.encode({
        'type': 'loadTemplate',
        'data': widget.template,
      })),
      targetOrigin: WebUri('*'),
    );
  }

  void _handleWebMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'editorState':
        // Handle editor state update
        final editorState = message['data'];
        print('Editor state updated: $editorState');
        break;
    }
  }

  Future<void> _saveTemplate() async {
    // Request editor state
    await _webViewController?.evaluateJavascript(source: 'getEditorState()');
  }
}
