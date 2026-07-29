import 'dart:math' as math;

import 'package:image/image.dart' as img;

img.Image letterboxPoseImage(
  img.Image source, {
  required int size,
}) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'must be greater than zero');
  }

  final scale = math.min(size / source.width, size / source.height);
  final resizedWidth = math.max(1, (source.width * scale).round());
  final resizedHeight = math.max(1, (source.height * scale).round());
  final resized = img.copyResize(
    source,
    width: resizedWidth,
    height: resizedHeight,
    interpolation: img.Interpolation.linear,
  );
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - resizedWidth) ~/ 2,
    dstY: (size - resizedHeight) ~/ 2,
  );
  return canvas;
}
