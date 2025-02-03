// lib/widgets/native_editor_web.dart
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:js' as js;
// Import the correct package for platformViewRegistry
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

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
  final String viewType = 'editor-view';
  final _iframeElement = html.IFrameElement();

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    // Set up the iframe
    _iframeElement
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..src = 'assets/editor.html'; // Make sure this path is correct

    // Register event listener for messages from the editor
    html.window.onMessage.listen((event) {
      if (event.data != null) {
        try {
          final message = js.JsObject.fromBrowserObject(event.data);
          _handleWebMessage(message);
        } catch (e) {
          print('Error handling message: $e');
        }
      }
    });

    // Register the element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => _iframeElement,
    );
  }

  void _handleWebMessage(js.JsObject message) {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'editorState':
        // Handle editor state updates
        break;
      case 'error':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'].toString())),
        );
        break;
    }
  }

  void _sendToEditor(String type, dynamic data) {
    final message = js.JsObject.jsify({
      'type': type,
      'data': data,
    });

    _iframeElement.contentWindow?.postMessage(message, '*');
  }

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
      body: Column(
        children: [
          Expanded(
            child: HtmlElementView(
              viewType: viewType,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Add Text'),
            onTap: () {
              Navigator.pop(context);
              _sendToEditor('setText', {
                'text': 'New Text',
                'fontSize': 24,
                'color': '#000000',
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Add Image'),
            onTap: () {
              Navigator.pop(context);
              _showImageUploadDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showImageUploadDialog() {
    // Create file input element
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoad.listen((event) {
          _sendToEditor('setImage', {
            'url': reader.result,
            'width': 200,
            'height': 200,
          });
        });
      }
    });
  }

  void _saveTemplate() {
    _sendToEditor('getState', null);
  }
}
