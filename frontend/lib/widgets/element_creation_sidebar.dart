import 'package:flutter/material.dart';

class ElementCreationSidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(Map<String, dynamic>) onCreateElement;

  const ElementCreationSidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onCreateElement,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 250 : 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle button
          ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 8),
            leading: isExpanded ? const Icon(Icons.add_box) : null,
            title: isExpanded ? const Text('Add Elements') : null,
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.chevron_left : Icons.chevron_right),
              onPressed: onToggle,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(isExpanded ? 16 : 8),
              children: [
                if (isExpanded) ...[
                  Text(
                    'Text Elements',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildDraggableElement(
                  icon: Icons.title,
                  label: 'Heading',
                  isExpanded: isExpanded,
                  element: {
                    'type': 'text',
                    'content': {'text': 'New Heading'},
                    'style': {
                      'font_size': 32.0,
                      'color': '#000000',
                    },
                    'box': {
                      'x': 100.0,
                      'y': 100.0,
                      'width': 300.0,
                      'height': 50.0,
                      'alignment': 'center',
                    },
                  },
                  onCreateElement: onCreateElement,
                ),
                const SizedBox(height: 8),
                _buildDraggableElement(
                  icon: Icons.text_fields,
                  label: 'Body Text',
                  isExpanded: isExpanded,
                  element: {
                    'type': 'text',
                    'content': {'text': 'New Text Block'},
                    'style': {
                      'font_size': 16.0,
                      'color': '#000000',
                    },
                    'box': {
                      'x': 100.0,
                      'y': 100.0,
                      'width': 200.0,
                      'height': 100.0,
                      'alignment': 'left',
                    },
                  },
                  onCreateElement: onCreateElement,
                ),
                const SizedBox(height: 16),
                if (isExpanded) ...[
                  Text(
                    'Media Elements',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildDraggableElement(
                  icon: Icons.image,
                  label: 'Image',
                  isExpanded: isExpanded,
                  element: {
                    'type': 'image',
                    'content': {
                      'url': 'https://via.placeholder.com/200x200',
                    },
                    'style': {},
                    'box': {
                      'x': 100.0,
                      'y': 100.0,
                      'width': 200.0,
                      'height': 200.0,
                      'alignment': 'center',
                    },
                  },
                  onCreateElement: onCreateElement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableElement({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required Map<String, dynamic> element,
    required Function(Map<String, dynamic>) onCreateElement,
  }) {
    return Draggable<Map<String, dynamic>>(
      data: element,
      feedback: Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(icon),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(isExpanded ? 12 : 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
