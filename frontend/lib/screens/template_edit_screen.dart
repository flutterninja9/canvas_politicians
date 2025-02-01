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
      'editable_json':
          List<Map<String, dynamic>>.from(widget.template['editable_json'])
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
    print(widget.template);
    print(editedJson);
    apiService.saveEdit(widget.template['id'], editedJson);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Changes Saved!")));
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TemplatePreviewScreen(
            editedJson: editedJson,
            templateId: widget.template['template_id'])));
  }

  @override
  Widget build(BuildContext context) {
    // Get the canvas dimensions from the template
    double canvasWidth = widget.template['canvas_width'].toDouble();
    double canvasHeight = widget.template['canvas_height'].toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Template")),
      body: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(double.infinity), // Infinite canvas
        minScale: 0.1, // Minimum zoom level
        maxScale: 4.0, // Maximum zoom level
        constrained: false,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            children: [
              // Background Image
              Image.network(
                widget.template['image'],
                width: canvasWidth,
                height: canvasHeight,
                fit: BoxFit.cover,
              ),
              // Editable Elements
              ...editedJson['editable_json'].map((element) {
                if (element['type'] == 'image') {
                  return Positioned(
                    left: element['position']['x'].toDouble(),
                    top: element['position']['y'].toDouble(),
                    child: Draggable(
                      feedback: Material(
                        color: Colors.transparent,
                        child: Image.network(
                          element['url'],
                          width: element['size']['width'].toDouble(),
                          height: element['size']['height'].toDouble(),
                        ),
                      ),
                      childWhenDragging: Image.network(
                        element['url'],
                        width: element['size']['width'].toDouble(),
                        height: element['size']['height'].toDouble(),
                      ),
                      onDragEnd: (details) {
                        setState(() {
                          element['position']['x'] = details.offset.dx;
                          element['position']['y'] = details.offset.dy;
                        });
                      },
                      child: Image.network(
                        element['url'],
                        width: element['size']['width'].toDouble(),
                        height: element['size']['height'].toDouble(),
                      ),
                    ),
                  );
                }

                return Positioned(
                  left: element['position']['x'].toDouble(),
                  top: element['position']['y'].toDouble(),
                  child: GestureDetector(
                    onTap: () => showEditOptions(context, element),
                    child: Draggable(
                      feedback: Material(
                        color: Colors.transparent,
                        child: Text(
                          element['text'] ?? 'Default Text',
                          style: TextStyle(
                            fontSize: element['font_size'].toDouble(),
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(
                                element['color'].replaceFirst('#', '0xff'))),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(),
                      onDragEnd: (details) {
                        setState(() {
                          element['position']['x'] = details.offset.dx;
                          element['position']['y'] = details.offset.dy;
                        });
                      },
                      child: Text(
                        element['text'] ?? 'Default Text',
                        style: TextStyle(
                          fontSize: element['font_size'].toDouble(),
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(
                              element['color'].replaceFirst('#', '0xff'))),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveChanges,
        child: const Icon(Icons.save),
      ),
    );
  }
}
