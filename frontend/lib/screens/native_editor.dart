// // lib/widgets/native_editor.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import '../controllers/native_editor_controller.dart';

// class NativeEditor extends StatefulWidget {
//   final Map<String, dynamic> template;

//   const NativeEditor({
//     super.key,
//     required this.template,
//   });

//   @override
//   State<NativeEditor> createState() => _NativeEditorState();
// }

// class _NativeEditorState extends State<NativeEditor> {
//   NativeEditorController? _controller;
//   bool isLoading = true;
//   Map<String, dynamic>? currentState;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Editor'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.undo),
//             onPressed: _controller?.canUndo == true ? _controller?.undo : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.redo),
//             onPressed: _controller?.canRedo == true ? _controller?.redo : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _showAddMenu,
//           ),
//           IconButton(
//             icon: const Icon(Icons.save),
//             onPressed: _saveTemplate,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           InAppWebView(
//             initialFile: "assets/editor.html",
//             onWebViewCreated: (controller) {
//               _controller = NativeEditorController(
//                 webViewController: controller,
//                 context: context,
//                 onError: _handleError,
//                 onStateChanged: _handleStateChanged,
//               );

//               controller.addJavaScriptHandler(
//                 handlerName: 'flutterHandler',
//                 callback: (args) {
//                   final message = args.first as Map<String, dynamic>;
//                   _controller?.handleWebMessage(message);
//                 },
//               );
//             },
//             onLoadStop: (controller, url) {
//               setState(() => isLoading = false);
//               _initializeEditor();
//             },
//             gestureRecognizers: const {},
//           ),
//           if (isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }

//   void _showAddMenu() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Icons.text_fields),
//             title: const Text('Add Text'),
//             onTap: () {
//               Navigator.pop(context);
//               _controller?.addText(text: 'New Text');
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.image),
//             title: const Text('Add Image'),
//             onTap: () {
//               Navigator.pop(context);
//               _controller?.addImage();
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleError(String error) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(error)),
//     );
//   }

//   void _handleStateChanged(Map<String, dynamic> state) {
//     setState(() => currentState = state);
//   }

//   Future<void> _saveTemplate() async {
//     // Implement save functionality
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Template saved!')),
//     );
//   }

//   void _initializeEditor() {
//     // Initialize with template data
//     // Your initialization logic here
//   }
// }
