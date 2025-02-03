// lib/screens/template_edit_screen.dart

import 'package:flutter/material.dart';
import '../models/template_types.dart';
import '../utils/responsive_utils.dart';
import '../widgets/element_creation_sidebar.dart';
import '../widgets/property_sidebar.dart';
import '../services/api_service.dart';
import 'template_preview_screen.dart';

class TemplateEditScreen extends StatefulWidget {
  final Map<String, dynamic> template;
  const TemplateEditScreen({super.key, required this.template});

  @override
  _TemplateEditScreenState createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  late List<TemplateElement> elements;
  bool isCreationSidebarExpanded = true;
  TemplateElement? selectedElement;
  late final TransformationController transformationController;
  final GlobalKey _stackKey = GlobalKey();
  late double _canvasAspectRatio;
  late Size _viewportSize;

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();
    _canvasAspectRatio =
        widget.template['original_width'] / widget.template['original_height'];

    // Convert existing elements to strongly typed objects
    elements = (widget.template['editable_json'] as List? ?? [])
        .map((e) => TemplateElement.fromJson(e))
        .toList();
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  void _handleNewElement(TemplateElement element) {
    setState(() {
      elements.add(element);
      selectedElement = element;
    });
  }

  Widget _buildResizeHandle(TemplateElement element, HandlePosition position) {
    return Positioned(
      left: position == HandlePosition.topLeft ||
              position == HandlePosition.bottomLeft
          ? -12
          : ResponsiveUtils.percentToPixelX(
              element.box.widthPercent, _viewportSize.width),
      top: position == HandlePosition.topLeft ||
              position == HandlePosition.topRight
          ? -12
          : ResponsiveUtils.percentToPixelY(
              element.box.heightPercent, _viewportSize.height),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double deltaX = ResponsiveUtils.pixelToPercentX(
                details.delta.dx, _viewportSize.width);
            double deltaY = ResponsiveUtils.pixelToPercentY(
                details.delta.dy, _viewportSize.height);

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.topRight) {
              element.box.yPercent += deltaY;
              element.box.heightPercent -= deltaY;
            }

            if (position == HandlePosition.bottomLeft ||
                position == HandlePosition.bottomRight) {
              element.box.heightPercent += deltaY;
            }

            if (position == HandlePosition.topLeft ||
                position == HandlePosition.bottomLeft) {
              element.box.xPercent += deltaX;
              element.box.widthPercent -= deltaX;
            }

            if (position == HandlePosition.topRight ||
                position == HandlePosition.bottomRight) {
              element.box.widthPercent += deltaX;
            }

            // Ensure minimum size and bounds
            element.box.widthPercent =
                element.box.widthPercent.clamp(1.0, 100.0);
            element.box.heightPercent =
                element.box.heightPercent.clamp(1.0, 100.0);
            element.box.xPercent = element.box.xPercent
                .clamp(0.0, 100.0 - element.box.widthPercent);
            element.box.yPercent = element.box.yPercent
                .clamp(0.0, 100.0 - element.box.heightPercent);
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

  Widget _buildElementWidget(TemplateElement element, Size elementSize) {
    if (element.type == 'image') {
      return Image.network(
        element.content['url'] ?? '',
        width: elementSize.width,
        height: elementSize.height,
        fit: BoxFit.contain,
      );
    }

    // Convert font size from vw to pixels
    double fontSizePixels = ResponsiveUtils.vwToPixels(
        element.style.fontSizeVw, _viewportSize.width);

    return Text(
      element.content['text'] ?? 'Default Text',
      style: TextStyle(
        fontSize: fontSizePixels,
        fontWeight: FontWeight.bold,
        color: Color(int.parse(element.style.color.replaceFirst('#', '0xff'))),
      ),
    );
  }

  Widget _buildBoxedElement(TemplateElement element) {
    bool isSelected = selectedElement == element;
    double x = ResponsiveUtils.percentToPixelX(
        element.box.xPercent, _viewportSize.width);
    double y = ResponsiveUtils.percentToPixelY(
        element.box.yPercent, _viewportSize.height);
    double width = ResponsiveUtils.percentToPixelX(
        element.box.widthPercent, _viewportSize.width);
    double height = ResponsiveUtils.percentToPixelY(
        element.box.heightPercent, _viewportSize.height);

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => setState(() => selectedElement = element),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border:
                isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: element.box.alignment == 'center'
                      ? Alignment.center
                      : element.box.alignment == 'right'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Draggable(
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildElementWidget(element, Size(width, height)),
                    ),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      final RenderBox box = _stackKey.currentContext!
                          .findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.offset);

                      setState(() {
                        element.box.xPercent = ResponsiveUtils.pixelToPercentX(
                            localPosition.dx
                                .clamp(0, _viewportSize.width - width),
                            _viewportSize.width);
                        element.box.yPercent = ResponsiveUtils.pixelToPercentY(
                            localPosition.dy
                                .clamp(0, _viewportSize.height - height),
                            _viewportSize.height);
                      });
                    },
                    child: _buildElementWidget(element, Size(width, height)),
                  ),
                ),
              ),
              if (isSelected) ...[
                _buildResizeHandle(element, HandlePosition.topLeft),
                _buildResizeHandle(element, HandlePosition.topRight),
                _buildResizeHandle(element, HandlePosition.bottomLeft),
                _buildResizeHandle(element, HandlePosition.bottomRight),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    // Convert elements to JSON
    final editedJson = {
      'editable_elements': elements.map((e) => e.toJson()).toList(),
      'viewport': {
        'width': _viewportSize.width,
        'height': _viewportSize.height,
      }
    };

    apiService.saveEdit(widget.template['id'], editedJson);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Changes Saved!")));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplatePreviewScreen(
          editedJson: editedJson,
          templateId: widget.template['id'],
          viewportSize: _viewportSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate viewport size maintaining aspect ratio
          _viewportSize = ResponsiveUtils.calculateViewportSize(
              constraints, _canvasAspectRatio);

          return Row(
            children: [
              ElementCreationSidebar(
                isExpanded: isCreationSidebarExpanded,
                onToggle: () => setState(() {
                  isCreationSidebarExpanded = !isCreationSidebarExpanded;
                }),
                onCreateElement: _handleNewElement,
                viewportSize: _viewportSize,
              ),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    transformationController: transformationController,
                    minScale: 0.1,
                    maxScale: 4.0,
                    constrained: false,
                    child: SizedBox(
                      width: _viewportSize.width,
                      height: _viewportSize.height,
                      child: Stack(
                        key: _stackKey,
                        children: [
                          Image.network(
                            widget.template['image'],
                            width: _viewportSize.width,
                            height: _viewportSize.height,
                            fit: BoxFit.contain,
                          ),
                          ...elements.map(_buildBoxedElement),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedElement != null)
                PropertySidebar(
                  element: selectedElement!,
                  viewportSize: _viewportSize,
                  onUpdate: () => setState(() {}),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum HandlePosition { topLeft, topRight, bottomLeft, bottomRight }
