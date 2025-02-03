class TemplateBox {
  double xPercent;
  double yPercent;
  double widthPercent;
  double heightPercent;
  String alignment;

  TemplateBox({
    required this.xPercent,
    required this.yPercent,
    required this.widthPercent,
    required this.heightPercent,
    this.alignment = 'left',
  });

  factory TemplateBox.fromJson(Map<String, dynamic> json) {
    return TemplateBox(
      xPercent: json['x_percent']?.toDouble() ?? 0.0,
      yPercent: json['y_percent']?.toDouble() ?? 0.0,
      widthPercent: json['width_percent']?.toDouble() ?? 0.0,
      heightPercent: json['height_percent']?.toDouble() ?? 0.0,
      alignment: json['alignment'] ?? 'left',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x_percent': xPercent,
      'y_percent': yPercent,
      'width_percent': widthPercent,
      'height_percent': heightPercent,
      'alignment': alignment,
    };
  }
}

class TemplateStyle {
  double fontSizeVw;
  String color;

  TemplateStyle({
    required this.fontSizeVw,
    required this.color,
  });

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    return TemplateStyle(
      fontSizeVw: json['font_size']?.toDouble() ?? 4.0,
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_size': fontSizeVw,
      'color': color,
    };
  }
}

class TemplateElement {
  String type;
  TemplateBox box;
  Map<String, dynamic> content;
  TemplateStyle style;
  int zIndex;

  TemplateElement({
    required this.type,
    required this.box,
    required this.content,
    required this.style,
    this.zIndex = 0,
  });

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    return TemplateElement(
      type: json['type'] ?? 'text',
      box: TemplateBox.fromJson(json['box'] ?? {}),
      content: json['content'] ?? {},
      style: TemplateStyle.fromJson(json['style'] ?? {}),
      zIndex: json['z_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'box': box.toJson(),
      'content': content,
      'style': style.toJson(),
      'z_index': zIndex,
    };
  }
}
