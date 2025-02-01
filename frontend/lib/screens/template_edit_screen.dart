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
  bool isResizing = false;

  @override
  void initState() {
    super.initState();
    print(widget.template);
    editedJson = {
      'editable_elements':
          List<Map<String, dynamic>>.from(widget.template['editable_json'])
    };
  }

  // Convert percentage to pixels
  double getPixelX(double percentage) {
    return percentage * widget.template['canvas_width'] / 100;
  }

  double getPixelY(double percentage) {
    return percentage * widget.template['canvas_height'] / 100;
  }

  // Convert pixels to percentage
  double getPercentageX(double pixels) {
    return (pixels * 100) / widget.template['canvas_width'];
  }

  double getPercentageY(double pixels) {
    return (pixels * 100) / widget.template['canvas_height'];
  }

  Widget buildResizeHandle(
      Map<String, dynamic> element, HandlePosition position) {
    return Positioned(
      left: position == HandlePosition.topLeft ||
              position == HandlePosition.bottomLeft
          ? getPixelX(element['box']['x']) - 12
          : getPixelX(element['box']['x']) + getPixelX(element['box']['width']),
      top: position == HandlePosition.topLeft ||
              position == HandlePosition.topRight
          ? getPixelY(element['box']['y']) - 12
          : getPixelY(element['box']['y']) +
              getPixelY(element['box']['height']),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newWidth = element['box']['width'];
            double newHeight = element['box']['height'];
            double newX = element['box']['x'];
            double newY = element['box']['y'];

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.topRight) {
              double deltaY = getPercentageY(details.delta.dy);
              newHeight -= deltaY;
              newY += deltaY;
            }

            if (position == HandlePosition.bottomLeft ||
                position == HandlePosition.bottomRight) {
              newHeight += getPercentageY(details.delta.dy);
            }

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.bottomLeft) {
              double deltaX = getPercentageX(details.delta.dx);
              newWidth -= deltaX;
              newX += deltaX;
            }

            if (position == HandlePosition.topRight ||
                position == HandlePosition.bottomRight) {
              newWidth += getPercentageX(details.delta.dx);
            }

            // Ensure minimum size
            if (newWidth >= 5 && newHeight >= 5) {
              element['box']['width'] = newWidth;
              element['box']['height'] = newHeight;
              element['box']['x'] = newX;
              element['box']['y'] = newY;
            }
          });
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void showEditOptions(BuildContext context, Map<String, dynamic> element) {
    setState(() => selectedElement = element);
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
                        TextEditingController(text: element['content']['text']);
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
                    element['content']['text'] = newText;
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
                            element['style']['color'] =
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
            ListTile(
              title: Text("Alignment: ${element['box']['alignment']}"),
              trailing: const Icon(Icons.format_align_center),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Choose Alignment"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text("Left"),
                            onTap: () {
                              setState(() {
                                element['box']['alignment'] = 'left';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text("Center"),
                            onTap: () {
                              setState(() {
                                element['box']['alignment'] = 'center';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text("Right"),
                            onTap: () {
                              setState(() {
                                element['box']['alignment'] = 'right';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
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

  Widget buildElementWidget(Map<String, dynamic> element) {
    if (element['type'] == 'image') {
      return Image.network(
        element['content']['url'],
        fit: BoxFit.contain,
      );
    }

    return Text(
      element['content']['text'] ?? 'Default Text',
      style: TextStyle(
        fontSize: element['style']['font_size'].toDouble(),
        fontWeight: FontWeight.bold,
        color: Color(
            int.parse(element['style']['color'].replaceFirst('#', '0xff'))),
      ),
    );
  }

  Widget buildBoxedElement(Map<String, dynamic> element) {
    bool isSelected = selectedElement == element;

    return Positioned(
      left: getPixelX(element['box']['x']),
      top: getPixelY(element['box']['y']),
      child: GestureDetector(
        onTap: () => showEditOptions(context, element),
        child: Container(
          width: getPixelX(element['box']['width']),
          height: getPixelY(element['box']['height']),
          decoration: BoxDecoration(
            border:
                isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: element['box']['alignment'] == 'center'
                      ? Alignment.center
                      : element['box']['alignment'] == 'right'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Draggable(
                    feedback: Material(
                      color: Colors.transparent,
                      child: buildElementWidget(element),
                    ),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      setState(() {
                        element['box']['x'] = getPercentageX(details.offset.dx);
                        element['box']['y'] = getPercentageY(details.offset.dy);
                      });
                    },
                    child: buildElementWidget(element),
                  ),
                ),
              ),
              if (isSelected) ...[
                buildResizeHandle(element, HandlePosition.topLeft),
                buildResizeHandle(element, HandlePosition.topRight),
                buildResizeHandle(element, HandlePosition.bottomLeft),
                buildResizeHandle(element, HandlePosition.bottomRight),
              ],
            ],
          ),
        ),
      ),
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
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false,
        child: SizedBox(
          width: widget.template['canvas_width'].toDouble(),
          height: widget.template['canvas_height'].toDouble(),
          child: Stack(
            children: [
              Image.network(
                widget.template['image'],
                width: widget.template['canvas_width'].toDouble(),
                height: widget.template['canvas_height'].toDouble(),
                fit: BoxFit.cover,
              ),
              ...editedJson['editable_elements']
                  .map<Widget>((element) => buildBoxedElement(element))
                  .toList(),
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

enum HandlePosition { topLeft, topRight, bottomLeft, bottomRight }
