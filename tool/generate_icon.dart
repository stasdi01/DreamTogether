/// Generates app icon assets for DreamTogether.
///
/// Run from the project root:
///   dart run tool/generate_icon.dart
///
/// Produces:
///   assets/icon/app_icon.png    – 1024×1024, gradient bg + heart (launcher icon)
///   assets/icon/app_icon_fg.png – 1024×1024, white heart on transparent (adaptive / splash)

import 'dart:io';
import 'dart:math' hide Point;
import 'package:image/image.dart' as img;

void main() {
  _generateFullIcon();
  _generateForegroundIcon();
  print('Done! Check assets/icon/');
}

// ── Full icon (gradient background + white heart) ────────────────────────────

void _generateFullIcon() {
  const size = 1024;
  final image = img.Image(width: size, height: size, numChannels: 4);

  // Gradient: #1E1B4B (top) → #6B21A8 (bottom)
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (30 + (107 - 30) * t).round();
    final g = (27 + (33 - 27) * t).round();
    final b = (75 + (168 - 75) * t).round();
    for (var x = 0; x < size; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  _drawHeart(
    image,
    cx: size / 2,
    cy: size / 2 + 30,
    scale: 24.0,
    color: img.ColorRgba8(255, 255, 255, 255),
  );

  _save(image, 'assets/icon/app_icon.png');
}

// ── Foreground icon (white heart on transparent) ─────────────────────────────

void _generateForegroundIcon() {
  const size = 1024;
  final image = img.Image(width: size, height: size, numChannels: 4);

  // Fully transparent background
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Slightly smaller heart so it sits within the adaptive safe zone (66%)
  _drawHeart(
    image,
    cx: size / 2,
    cy: size / 2 + 20,
    scale: 18.0,
    color: img.ColorRgba8(255, 255, 255, 255),
  );

  _save(image, 'assets/icon/app_icon_fg.png');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Draws a filled heart using the standard parametric heart curve.
///   x(t) = 16·sin³(t)
///   y(t) = 13·cos(t) − 5·cos(2t) − 2·cos(3t) − cos(4t)
void _drawHeart(
  img.Image image, {
  required double cx,
  required double cy,
  required double scale,
  required img.Color color,
}) {
  final vertices = <img.Point>[];
  for (var i = 0; i <= 360; i++) {
    final t = i * pi / 180;
    final x = 16 * pow(sin(t), 3);
    final y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t));
    vertices.add(img.Point(cx + x * scale, cy + y * scale));
  }
  img.fillPolygon(image, vertices: vertices, color: color);
}

void _save(img.Image image, String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('  → $path');
}
