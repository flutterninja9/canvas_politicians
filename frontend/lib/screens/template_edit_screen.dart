import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:frontend/screens/template_preview_screen.dart';
import '../services/api_service.dart';

class TemplateEditScreen extends StatefulWidget {
  final Map<String, dynamic> template;
  const TemplateEditScreen({super.key, required this.template});

  @override
  _TemplateEditScreenState createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  late Map<String, dynamic> editedJson;
  Color selectedColor = Colors.black;
  Map<String, dynamic>? selectedElement;

  @override
  void initState() {
    super.initState();
    editedJson = {
      'elements': List<Map<String, dynamic>>.from(
          widget.template['editable_json']['elements'])
    };
  }

  void showEditOptions(BuildContext context, Map<String, dynamic> element) {
    selectedElement = element;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Change Text"),
              trailing: const Icon(Icons.text_fields),
              onTap: () async {
                String? newText = await showDialog(
                  context: context,
                  builder: (context) {
                    TextEditingController controller =
                        TextEditingController(text: element['text']);
                    return AlertDialog(
                      title: const Text("Edit Text"),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text),
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  },
                );
                if (newText != null) {
                  setState(() {
                    element['text'] = newText;
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Change Color"),
              trailing: const Icon(Icons.color_lens),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Pick a Color"),
                      content: BlockPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            element['color'] =
                                "#${color.value.toRadixString(16)}";
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void saveChanges() {
    apiService.saveEdit(widget.template['id'], editedJson);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Changes Saved!")));
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TemplatePreviewScreen(
            editedJson: editedJson, templateId: widget.template['id'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Template")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Get the image dimensions from the template
          double imageWidth = widget.template['image_width'].toDouble();
          double imageHeight = widget.template['image_height'].toDouble();

          // Calculate scaling factor to fit screen while maintaining aspect ratio
          double scale = constraints.maxWidth / imageWidth;
          double scaledHeight = imageHeight * scale;

          return Stack(
            children: [
              Center(
                child: Image.network(
                  widget.template['image'],
                  width: imageWidth * scale,
                  height: scaledHeight,
                  fit: BoxFit.contain,
                ),
              ),
              ...editedJson['elements'].asMap().entries.map((entry) {
                int index = entry.key;
                var element = entry.value;
                return Positioned(
                  left: imageWidth * element['x'] * scale,
                  top: imageHeight * element['y'] * scale,
                  child: GestureDetector(
                    onTap: () => showEditOptions(context, element),
                    child: Draggable(
                      feedback: Material(
                        color: Colors.transparent,
                        child: Text(
                          element['text'] ?? 'Default Text',
                          style: TextStyle(
                            fontSize: 20 * scale, // Scale font size too
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(
                                element['color'].replaceFirst('#', '0xff'))),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(),
                      onDragEnd: (details) {
                        setState(() {
                          element['x'] =
                              details.offset.dx / (imageWidth * scale);
                          element['y'] =
                              details.offset.dy / (imageHeight * scale);
                        });
                      },
                      child: Text(
                        element['text'] ?? 'Default Text',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(
                              element['color'].replaceFirst('#', '0xff'))),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              Positioned(
                bottom: 20,
                left: 20,
                child: ElevatedButton(
                  onPressed: saveChanges,
                  child: const Text("Save"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
