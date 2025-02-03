// lib/utils/responsive_utils.dart

import 'package:flutter/material.dart';

class ResponsiveUtils {
  static Size calculateViewportSize(BoxConstraints constraints, double aspectRatio) {
    double maxWidth = constraints.maxWidth;
    double maxHeight = constraints.maxHeight;
    
    if (maxWidth / maxHeight > aspectRatio) {
      return Size(maxHeight * aspectRatio, maxHeight);
    } else {
      return Size(maxWidth, maxWidth / aspectRatio);
    }
  }

  static double percentToPixelX(double percent, double viewportWidth) {
    return (percent / 100) * viewportWidth;
  }

  static double percentToPixelY(double percent, double viewportHeight) {
    return (percent / 100) * viewportHeight;
  }

  static double pixelToPercentX(double pixels, double viewportWidth) {
    return (pixels / viewportWidth) * 100;
  }

  static double pixelToPercentY(double pixels, double viewportHeight) {
    return (pixels / viewportHeight) * 100;
  }

  static double vwToPixels(double vw, double viewportWidth) {
    return (vw / 100) * viewportWidth;
  }

  static double pixelsToVw(double pixels, double viewportWidth) {
    return (pixels / viewportWidth) * 100;
  }
}