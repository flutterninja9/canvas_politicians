import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/template_types.dart';

class PropertySidebar extends StatelessWidget {
  final TemplateElement element;
  final Size viewportSize;
  final VoidCallback onUpdate;

  const PropertySidebar({
    super.key,
    required this.element,
    required this.viewportSize,
    required this.onUpdate,
  });

  Widget _buildSectionTitle(BuildContext context, String title) {
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

  Widget _buildNumberInput({
    required String label,
    required double value,
    required Function(double) onChanged,
    double? min,
    double? max,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label${suffix != null ? ' ($suffix)' : ''}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value.toStringAsFixed(2),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    double? newValue = double.tryParse(text);
                    if (newValue != null) {
                      if (min != null) {
                        newValue = newValue.clamp(min, max ?? double.infinity);
                      }
                      onChanged(newValue);
                      onUpdate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  double newValue = value - 1;
                  if (min != null) {
                    newValue = newValue.clamp(min, max ?? double.infinity);
                  }
                  onChanged(newValue);
                  onUpdate();
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  double newValue = value + 1;
                  if (max != null) {
                    newValue =
                        newValue.clamp(min ?? double.negativeInfinity, max);
                  }
                  onChanged(newValue);
                  onUpdate();
                },
              ),
            ],
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
              selected: {element.box.alignment},
              onSelectionChanged: (Set<String> newSelection) {
                element.box.alignment = newSelection.first;
                onUpdate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color'),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              // Show color picker dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Pick a color'),
                    content: BlockPicker(
                      pickerColor: Color(
                        int.parse(
                            element.style.color.replaceFirst('#', '0xff')),
                      ),
                      onColorChanged: (color) {
                        element.style.color =
                            '#${color.value.toRadixString(16).substring(2)}';
                        onUpdate();
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
                  int.parse(element.style.color.replaceFirst('#', '0xff')),
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

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {
                    onUpdate();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(context, 'Position & Size'),
                _buildNumberInput(
                  label: 'X Position',
                  value: element.box.xPercent,
                  onChanged: (value) => element.box.xPercent = value,
                  min: 0,
                  max: 100 - element.box.widthPercent,
                  suffix: '%',
                ),
                _buildNumberInput(
                  label: 'Y Position',
                  value: element.box.yPercent,
                  onChanged: (value) => element.box.yPercent = value,
                  min: 0,
                  max: 100 - element.box.heightPercent,
                  suffix: '%',
                ),
                _buildNumberInput(
                  label: 'Width',
                  value: element.box.widthPercent,
                  onChanged: (value) => element.box.widthPercent = value,
                  min: 1,
                  max: 100 - element.box.xPercent,
                  suffix: '%',
                ),
                _buildNumberInput(
                  label: 'Height',
                  value: element.box.heightPercent,
                  onChanged: (value) => element.box.heightPercent = value,
                  min: 1,
                  max: 100 - element.box.yPercent,
                  suffix: '%',
                ),
                _buildSectionTitle(context, 'Alignment'),
                _buildAlignmentSelector(),
                if (element.type == 'text') ...[
                  _buildSectionTitle(context, 'Text Style'),
                  _buildNumberInput(
                    label: 'Font Size',
                    value: element.style.fontSizeVw,
                    onChanged: (value) => element.style.fontSizeVw = value,
                    min: 0.1,
                    max: 20,
                    suffix: 'vw',
                  ),
                  _buildColorPicker(context),
                  _buildTextInput(
                    'Text Content',
                    element.content['text'] ?? '',
                    (value) {
                      element.content['text'] = value;
                      onUpdate();
                    },
                  ),
                ],
                if (element.type == 'image') ...[
                  _buildSectionTitle(context, 'Image Properties'),
                  _buildTextInput(
                    'Image URL',
                    element.content['url'] ?? '',
                    (value) {
                      element.content['url'] = value;
                      onUpdate();
                    },
                  ),
                ],
                _buildSectionTitle(context, 'Layer'),
                _buildNumberInput(
                  label: 'Z-Index',
                  value: element.zIndex.toDouble(),
                  onChanged: (value) {
                    element.zIndex = value.toInt();
                    onUpdate();
                  },
                  min: 0,
                  max: 999,
                ),
              ],
            ),
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
}
