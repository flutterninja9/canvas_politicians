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
  late final TransformationController transformationController;
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();
    editedJson = {
      'editable_elements':
          List<Map<String, dynamic>>.from(widget.template['editable_json'])
    };
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  Widget buildResizeHandle(
      Map<String, dynamic> element, HandlePosition position) {
    return Positioned(
      left: position == HandlePosition.topLeft ||
              position == HandlePosition.bottomLeft
          ? element['box']['x'] - 12
          : element['box']['x'] + element['box']['width'],
      top: position == HandlePosition.topLeft ||
              position == HandlePosition.topRight
          ? element['box']['y'] - 12
          : element['box']['y'] + element['box']['height'],
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newWidth = element['box']['width'];
            double newHeight = element['box']['height'];
            double newX = element['box']['x'];
            double newY = element['box']['y'];

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.topRight) {
              newHeight -= details.delta.dy;
              newY += details.delta.dy;
            }

            if (position == HandlePosition.bottomLeft ||
                position == HandlePosition.bottomRight) {
              newHeight += details.delta.dy;
            }

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.bottomLeft) {
              newWidth -= details.delta.dx;
              newX += details.delta.dx;
            }

            if (position == HandlePosition.topRight ||
                position == HandlePosition.bottomRight) {
              newWidth += details.delta.dx;
            }

            // Ensure minimum size and bounds
            if (newWidth >= 5 && newHeight >= 5) {
              // Validate bounds
              if (newX >= 0 &&
                  newY >= 0 &&
                  newX + newWidth <= widget.template['canvas_width'] &&
                  newY + newHeight <= widget.template['canvas_height']) {
                element['box']['width'] = newWidth;
                element['box']['height'] = newHeight;
                element['box']['x'] = newX;
                element['box']['y'] = newY;
              }
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

  Widget buildBoxedElement(Map<String, dynamic> element) {
    bool isSelected = selectedElement == element;

    return Positioned(
      left: element['box']['x'].toDouble(),
      top: element['box']['y'].toDouble(),
      child: GestureDetector(
        onTap: () => showEditOptions(context, element),
        child: Container(
          width: element['box']['width'].toDouble(),
          height: element['box']['height'].toDouble(),
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
                    feedback: Builder(builder: (context) {
                      final scale =
                          transformationController.value.getMaxScaleOnAxis();

                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          color: Colors.transparent,
                          child: buildElementWidget(element),
                        ),
                      );
                    }),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      final RenderBox box = _stackKey.currentContext!
                          .findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.offset);

                      setState(() {
                        // Ensure the element stays within bounds
                        double newX = localPosition.dx
                            .clamp(
                                0,
                                widget.template['canvas_width'] -
                                    element['box']['width'])
                            .toDouble();
                        double newY = localPosition.dy
                            .clamp(
                                0,
                                widget.template['canvas_height'] -
                                    element['box']['height'])
                            .toDouble();

                        element['box']['x'] = newX;
                        element['box']['y'] = newY;
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
        transformationController: transformationController,
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false,
        child: SizedBox(
          width: widget.template['canvas_width'].toDouble(),
          height: widget.template['canvas_height'].toDouble(),
          child: Stack(
            key: _stackKey,
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
