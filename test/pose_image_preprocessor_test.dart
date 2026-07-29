import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/services/pose_image_preprocessor.dart';
import 'package:image/image.dart' as img;

void main() {
  test('wide image is uniformly scaled with vertical letterbox padding', () {
    final source = img.Image(width: 200, height: 100);
    img.fill(source, color: img.ColorRgb8(255, 0, 0));

    final result = letterboxPoseImage(source, size: 100);

    expect(result.width, 100);
    expect(result.height, 100);
    expect(result.getPixel(50, 0).r, 0);
    expect(result.getPixel(50, 24).r, 0);
    expect(result.getPixel(50, 25).r, 255);
    expect(result.getPixel(50, 74).r, 255);
    expect(result.getPixel(50, 75).r, 0);
  });

  test('portrait image is uniformly scaled with horizontal padding', () {
    final source = img.Image(width: 100, height: 200);
    img.fill(source, color: img.ColorRgb8(0, 255, 0));

    final result = letterboxPoseImage(source, size: 100);

    expect(result.getPixel(24, 50).g, 0);
    expect(result.getPixel(25, 50).g, 255);
    expect(result.getPixel(74, 50).g, 255);
    expect(result.getPixel(75, 50).g, 0);
  });
}
