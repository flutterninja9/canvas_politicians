// lib/widgets/native_editor_mobile.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../controllers/native_editor_controller.dart';

class PlatformEditor extends StatefulWidget {
  final Map<String, dynamic> template;

  const PlatformEditor({
    super.key,
    required this.template,
  });

  @override
  State<PlatformEditor> createState() => _PlatformEditorState();
}

class _PlatformEditorState extends State<PlatformEditor> {
  NativeEditorController? _controller;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMenu,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: InAppWebView(
        initialFile: "assets/editor.html",
        onWebViewCreated: _onWebViewCreated,
        onLoadStop: (controller, url) {
          setState(() => isLoading = false);
          _initializeEditor();
        },
      ),
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = NativeEditorController(
      webViewController: controller,
      context: context,
      onError: _handleError,
      onStateChanged: _handleStateChanged,
    );

    controller.addJavaScriptHandler(
      handlerName: 'flutterHandler',
      callback: (args) {
        final message = args.first as Map<String, dynamic>;
        _controller?.handleWebMessage(message);
      },
    );
  }

  // Rest of the implementation...
  void _showAddMenu() {
    // show a modal bottom sheet with options

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          ListTile(
            title: const Text('Add Text'),
            onTap: () {
              _sendToEditor('text', null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Add Image'),
            onTap: () {
              _sendToEditor('image', null);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _sendToEditor(String type, Map<String, dynamic>? data) {
    final message = {
      'type': type,
      'data': data,
    };

    if (type == "text") {
      _controller?.addText(
        text: 'New Text',
        fontSize: 24,
        color: '#000000',
      );
    } else {
      _controller?.addImage();
    }
  }

  void _saveTemplate() {
    // Implementation
  }

  void _handleError(String error) {
    // Implementation
  }

  void _handleStateChanged(Map<String, dynamic> state) {
    // Implementation
  }

  void _initializeEditor() {
    // Implementation
  }
}
