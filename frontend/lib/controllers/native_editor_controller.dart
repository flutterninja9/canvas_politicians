// lib/controllers/native_editor_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class NativeEditorController {
  final InAppWebViewController webViewController;
  final BuildContext context;
  final Function(String) onError;
  final Function(Map<String, dynamic>) onStateChanged;

  bool _canUndo = false;
  bool _canRedo = false;

  NativeEditorController({
    required this.webViewController,
    required this.context,
    required this.onError,
    required this.onStateChanged,
  });

  bool get canUndo => _canUndo;
  bool get canRedo => _canRedo;

  Future<void> addText({
    required String text,
    double? fontSize,
    String? color,
    String? fontFamily,
    double? x,
    double? y,
  }) async {
    try {
      await webViewController.evaluateJavascript(source: '''
  editor.addText('$text', {
    fontSize: ${fontSize ?? 24},
    color: '${color ?? '#000000'}',
    fontFamily: '${fontFamily ?? 'Arial'}',
    left: ${x ?? 100},
    top: ${y ?? 100}
  });
''');
    } catch (e) {
      onError('Failed to add text: $e');
    }
  }

  Future<void> addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // In a real app, you'd upload this image to your server first
        // Here we're using it directly for demo purposes
        await webViewController.evaluateJavascript(source: '''
          editor.addImage({
            type: 'setImage',
            data: {
              url: '${image.path}',
              x: 100,
              y: 100
            }
          });
        ''');
      }
    } catch (e) {
      onError('Failed to add image: $e');
    }
  }

  Future<void> updateElement(String id, Map<String, dynamic> properties) async {
    try {
      final propertiesJson = json.encode(properties);
      await webViewController.evaluateJavascript(source: '''
        methodChannel.handleMessage({
          type: 'updateElement',
          data: {
            id: '$id',
            properties: $propertiesJson
          }
        });
      ''');
    } catch (e) {
      onError('Failed to update element: $e');
    }
  }

  Future<void> deleteElement(String id) async {
    try {
      await webViewController.evaluateJavascript(source: '''
        methodChannel.handleMessage({
          type: 'deleteElement',
          data: { id: '$id' }
        });
      ''');
    } catch (e) {
      onError('Failed to delete element: $e');
    }
  }

  Future<void> undo() async {
    if (!_canUndo) return;
    try {
      await webViewController.evaluateJavascript(
          source: "methodChannel.handleMessage({type: 'undo'});");
    } catch (e) {
      onError('Failed to undo: $e');
    }
  }

  Future<void> redo() async {
    if (!_canRedo) return;
    try {
      await webViewController.evaluateJavascript(
          source: "methodChannel.handleMessage({type: 'redo'});");
    } catch (e) {
      onError('Failed to redo: $e');
    }
  }

  void handleWebMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'editorState':
        onStateChanged(message['data']);
        break;
      case 'historyChanged':
        _canUndo = message['data']['canUndo'] ?? false;
        _canRedo = message['data']['canRedo'] ?? false;
        break;
      case 'error':
        onError(message['data']['message']);
        break;
    }
  }
}
