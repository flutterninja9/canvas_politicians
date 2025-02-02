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

  Widget buildPropertySidebar() {
    if (selectedElement == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Element Properties',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => selectedElement = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Position Section
                _buildSectionTitle('Position & Size'),
                _buildNumberInput(
                  'X Position',
                  selectedElement!['box']['x'],
                  (value) =>
                      setState(() => selectedElement!['box']['x'] = value),
                  min: 0,
                  max: widget.template['canvas_width'] -
                      selectedElement!['box']['width'],
                ),
                _buildNumberInput(
                  'Y Position',
                  selectedElement!['box']['y'],
                  (value) =>
                      setState(() => selectedElement!['box']['y'] = value),
                  min: 0,
                  max: widget.template['canvas_height'] -
                      selectedElement!['box']['height'],
                ),
                _buildNumberInput(
                  'Width',
                  selectedElement!['box']['width'],
                  (value) =>
                      setState(() => selectedElement!['box']['width'] = value),
                  min: 20,
                  max: widget.template['canvas_width'] -
                      selectedElement!['box']['x'],
                ),
                _buildNumberInput(
                  'Height',
                  selectedElement!['box']['height'],
                  (value) =>
                      setState(() => selectedElement!['box']['height'] = value),
                  min: 20,
                  max: widget.template['canvas_height'] -
                      selectedElement!['box']['y'],
                ),

                // Alignment Section
                _buildSectionTitle('Alignment'),
                _buildAlignmentSelector(),

                // Style Section
                _buildSectionTitle('Style'),
                if (selectedElement!['type'] == 'text') ...[
                  _buildNumberInput(
                    'Font Size',
                    selectedElement!['style']['font_size'],
                    (value) => setState(
                        () => selectedElement!['style']['font_size'] = value),
                    min: 8,
                    max: 200,
                  ),
                  _buildColorPicker(),
                  _buildTextInput(
                    'Text Content',
                    selectedElement!['content']['text'],
                    (value) => setState(
                        () => selectedElement!['content']['text'] = value),
                  ),
                ],

                if (selectedElement!['type'] == 'image') ...[
                  _buildTextInput(
                    'Image URL',
                    selectedElement!['content']['url'],
                    (value) => setState(
                        () => selectedElement!['content']['url'] = value),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildNumberInput(
    String label,
    double value,
    Function(double) onChanged, {
    double? min,
    double? max,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    double? newValue = double.tryParse(text);
                    if (newValue != null) {
                      if (min != null)
                        newValue = newValue.clamp(min, max ?? double.infinity);
                      onChanged(newValue);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  double newValue = value - 1;
                  if (min != null)
                    newValue = newValue.clamp(min, max ?? double.infinity);
                  onChanged(newValue);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  double newValue = value + 1;
                  if (max != null)
                    newValue =
                        newValue.clamp(min ?? double.negativeInfinity, max);
                  onChanged(newValue);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(
      String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color'),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Pick a color'),
                    content: BlockPicker(
                      pickerColor: Color(
                        int.parse(selectedElement!['style']['color']
                            .replaceFirst('#', '0xff')),
                      ),
                      onColorChanged: (color) {
                        setState(() {
                          selectedElement!['style']['color'] =
                              '#${color.value.toRadixString(16).substring(2)}';
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Color(
                  int.parse(selectedElement!['style']['color']
                      .replaceFirst('#', '0xff')),
                ),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'left',
                  icon: Icon(Icons.format_align_left),
                ),
                ButtonSegment(
                  value: 'center',
                  icon: Icon(Icons.format_align_center),
                ),
                ButtonSegment(
                  value: 'right',
                  icon: Icon(Icons.format_align_right),
                ),
              ],
              selected: {selectedElement!['box']['alignment']},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  selectedElement!['box']['alignment'] = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
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
        onTap: () => setSelectedElement(context, element),
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

  void setSelectedElement(
    BuildContext context,
    Map<String, dynamic> element,
  ) {
    setState(() => selectedElement = element);
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
      appBar: AppBar(elevation: 0),
      body: Row(
        children: [
          Expanded(
            child: InteractiveViewer(
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
          ),
          buildPropertySidebar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveChanges,
        child: const Icon(Icons.save),
      ),
    );
  }
}

enum HandlePosition { topLeft, topRight, bottomLeft, bottomRight }
