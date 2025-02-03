// lib/widgets/element_creation_sidebar.dart

import 'package:flutter/material.dart';
import '../models/template_types.dart';
import '../utils/image_upload_dialog.dart';

class ElementCreationSidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(TemplateElement) onCreateElement;
  final Size viewportSize;

  const ElementCreationSidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onCreateElement,
    required this.viewportSize,
  });

  TemplateElement _createTextElement({
    required String text,
    required double fontSizeVw,
    required String type,
  }) {
    return TemplateElement(
      type: 'text',
      box: TemplateBox(
        xPercent: 10,
        yPercent: 10,
        widthPercent: 80,
        heightPercent: 10,
        alignment: 'center',
      ),
      content: {'text': text},
      style: TemplateStyle(
        fontSizeVw: fontSizeVw,
        color: '#000000',
      ),
    );
  }

  TemplateElement _createImageElement() {
    return TemplateElement(
      type: 'image',
      box: TemplateBox(
        xPercent: 10,
        yPercent: 10,
        widthPercent: 30,
        heightPercent: 30,
        alignment: 'center',
      ),
      content: {
        'url': 'https://via.placeholder.com/200x200',
      },
      style: TemplateStyle(
        fontSizeVw: 0,
        color: '#000000',
      ),
    );
  }

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
                _buildElementButton(
                  context: context,
                  icon: Icons.title,
                  label: 'Heading',
                  onTap: () => onCreateElement(_createTextElement(
                    text: 'New Heading',
                    fontSizeVw: 6.0,
                    type: 'heading',
                  )),
                ),
                const SizedBox(height: 8),
                _buildElementButton(
                  context: context,
                  icon: Icons.text_fields,
                  label: 'Body Text',
                  onTap: () => onCreateElement(_createTextElement(
                    text: 'New Text Block',
                    fontSizeVw: 4.0,
                    type: 'body',
                  )),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Media Elements',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildElementButton(
                  context: context,
                  icon: Icons.image,
                  label: 'Image',
                  onTap: () async {
                    final url = await showImageUploadDialog(context);
                    if (url != null) {
                      final element = _createImageElement();
                      element.content['url'] = url;
                      onCreateElement(element);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
