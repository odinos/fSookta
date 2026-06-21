import 'package:flutter/services.dart';

class VideoFrameExtractionResult {
  const VideoFrameExtractionResult({
    required this.durationMs,
    required this.framePaths,
    required this.frameTimestampMs,
  });

  final int durationMs;
  final List<String> framePaths;
  final List<int> frameTimestampMs;

  double get durationSeconds => durationMs / 1000;
}

class VideoFrameExtractionException implements Exception {
  const VideoFrameExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoFrameExtractionService {
  const VideoFrameExtractionService();

  static const maxDuration = Duration(seconds: 20);
  static const maxFrames = 8;
  static const _channel = MethodChannel('sookta/video_frames');

  Future<int> getDurationMs(String videoPath) async {
    final duration = await _channel.invokeMethod<int>(
      'getVideoDurationMs',
      {'path': videoPath},
    );
    if (duration == null || duration <= 0) {
      throw const VideoFrameExtractionException(
        'Could not read video duration.',
      );
    }
    return duration;
  }

  Future<VideoFrameExtractionResult> extractFrames(
    String videoPath, {
    Duration maxDuration = maxDuration,
    int maxFrames = maxFrames,
  }) async {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'extractFrames',
      {
        'path': videoPath,
        'maxDurationMs': maxDuration.inMilliseconds,
        'maxFrames': maxFrames,
      },
    );
    if (response == null) {
      throw const VideoFrameExtractionException(
        'Video frame extraction returned no data.',
      );
    }

    final durationMs = response['durationMs'] as int?;
    final rawFrames = response['framePaths'] as List<Object?>?;
    final rawTimestamps = response['frameTimestampMs'] as List<Object?>?;
    final framePaths = rawFrames?.whereType<String>().toList() ?? const [];
    final timestamps = rawTimestamps
            ?.map((value) => value is num ? value.toInt() : null)
            .whereType<int>()
            .toList() ??
        const [];
    if (durationMs == null || durationMs <= 0) {
      throw const VideoFrameExtractionException(
        'Could not read video duration.',
      );
    }
    if (durationMs > maxDuration.inMilliseconds) {
      throw VideoFrameExtractionException(
        'Video must be ${maxDuration.inSeconds} seconds or shorter.',
      );
    }
    if (framePaths.isEmpty) {
      throw const VideoFrameExtractionException(
        'Could not extract readable frames from this video.',
      );
    }

    return VideoFrameExtractionResult(
      durationMs: durationMs,
      framePaths: framePaths,
      frameTimestampMs: timestamps.length == framePaths.length
          ? timestamps
          : _fallbackTimestamps(durationMs, framePaths.length),
    );
  }

  List<int> _fallbackTimestamps(int durationMs, int frameCount) {
    if (frameCount <= 0) return const [];
    return [
      for (var index = 0; index < frameCount; index++)
        ((durationMs * (index + 1)) / (frameCount + 1)).round(),
    ];
  }
}
