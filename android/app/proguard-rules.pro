# Keep on-device ML runtime classes for release builds that enable shrinking.
# The app currently targets iOS first, but these rules keep Android release
# readiness aligned with TensorFlow Lite and ONNX runtime dependencies.
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**
