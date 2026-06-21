package com.kdev.sookta

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "sookta/video_frames"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getVideoDurationMs" -> handleDuration(call, result)
                    "extractFrames" -> handleExtractFrames(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleDuration(call: MethodCall, result: MethodChannel.Result) {
        Thread {
            try {
                val path = call.argument<String>("path")
                    ?: throw IllegalArgumentException("Video path is required.")
                val durationMs = readDurationMs(path)
                postSuccess(result, durationMs)
            } catch (error: Throwable) {
                postError(result, error)
            }
        }.start()
    }

    private fun handleExtractFrames(call: MethodCall, result: MethodChannel.Result) {
        Thread {
            try {
                val path = call.argument<String>("path")
                    ?: throw IllegalArgumentException("Video path is required.")
                val maxDurationMs = call.argument<Int>("maxDurationMs") ?: 20_000
                val maxFrames = call.argument<Int>("maxFrames") ?: 4
                val durationMs = readDurationMs(path)
                if (durationMs > maxDurationMs) {
                    throw IllegalArgumentException("Video must be 20 seconds or shorter.")
                }

                val frames = extractFrameFiles(path, durationMs, maxFrames)
                postSuccess(
                    result,
                    mapOf(
                        "durationMs" to durationMs,
                        "framePaths" to frames.map { it.path },
                        "frameTimestampMs" to frames.map { it.timestampMs },
                    ),
                )
            } catch (error: Throwable) {
                postError(result, error)
            }
        }.start()
    }

    private fun readDurationMs(path: String): Int {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val value = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION,
            )
            return value?.toIntOrNull()
                ?: throw IllegalArgumentException("Could not read video duration.")
        } finally {
            retriever.release()
        }
    }

    private fun extractFrameFiles(
        path: String,
        durationMs: Int,
        maxFrames: Int,
    ): List<VideoFrame> {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val outputDir = File(cacheDir, "sookta_video_frames").apply {
                mkdirs()
            }
            outputDir.listFiles()?.forEach { file ->
                if (file.name.startsWith("frame_")) file.delete()
            }

            val frameCount = maxOf(1, minOf(maxFrames, 8))
            val durationUs = durationMs * 1000L
            val frames = mutableListOf<VideoFrame>()
            for (index in 0 until frameCount) {
                val fraction = (index + 1).toDouble() / (frameCount + 1).toDouble()
                val timeUs = (durationUs * fraction).toLong()
                val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    retriever.getScaledFrameAtTime(
                        timeUs,
                        MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                        720,
                        720,
                    )
                } else {
                    retriever.getFrameAtTime(
                        timeUs,
                        MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                    )
                } ?: continue

                val frameFile = File(
                    outputDir,
                    "frame_${System.currentTimeMillis()}_$index.jpg",
                )
                FileOutputStream(frameFile).use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 86, stream)
                }
                bitmap.recycle()
                frames.add(
                    VideoFrame(
                        path = frameFile.absolutePath,
                        timestampMs = (timeUs / 1000L).toInt(),
                    ),
                )
            }
            return frames
        } finally {
            retriever.release()
        }
    }

    private data class VideoFrame(
        val path: String,
        val timestampMs: Int,
    )

    private fun postSuccess(result: MethodChannel.Result, value: Any) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, error: Throwable) {
        mainHandler.post {
            result.error(
                "VIDEO_FRAME_EXTRACTION_FAILED",
                error.message ?: "Video frame extraction failed.",
                null,
            )
        }
    }
}
