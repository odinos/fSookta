import Flutter
import UIKit
import AVFoundation
import Darwin

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    SooktaTensorFlowLiteLoader.preload()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SooktaVideoFrameExtractor") {
      SooktaVideoFrameExtractor.register(with: registrar)
    }
  }
}

private enum SooktaTensorFlowLiteLoader {
  private static let frameworkPath = "TensorFlowLiteC.framework/TensorFlowLiteC"

  static func preload() {
    var candidates: [String] = []
    if let frameworkDirectory = Bundle.main.privateFrameworksURL {
      candidates.append(
        frameworkDirectory.appendingPathComponent(frameworkPath).path
      )
    }
    candidates.append("@rpath/\(frameworkPath)")
    candidates.append(frameworkPath)

    for path in candidates {
      if dlopen(path, RTLD_NOW | RTLD_GLOBAL) != nil {
        return
      }
    }

    if let error = dlerror() {
      NSLog("Sookta could not preload TensorFlowLiteC: \(String(cString: error))")
    } else {
      NSLog("Sookta could not preload TensorFlowLiteC.")
    }
  }
}

final class SooktaVideoFrameExtractor: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "sookta/video_frames",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(SooktaVideoFrameExtractor(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getVideoDurationMs":
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let arguments = call.arguments as? [String: Any],
                let path = arguments["path"] as? String else {
            throw VideoFrameError.invalidArguments
          }
          let durationMs = try self.durationMs(path: path)
          DispatchQueue.main.async { result(durationMs) }
        } catch {
          self.fail(result, error)
        }
      }
    case "extractFrames":
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let arguments = call.arguments as? [String: Any],
                let path = arguments["path"] as? String else {
            throw VideoFrameError.invalidArguments
          }
          let maxDurationMs = arguments["maxDurationMs"] as? Int ?? 20_000
          let maxFrames = arguments["maxFrames"] as? Int ?? 4
          let durationMs = try self.durationMs(path: path)
          if durationMs > maxDurationMs {
            throw VideoFrameError.tooLong
          }
          let framePaths = try self.extractFrameFiles(
            path: path,
            durationMs: durationMs,
            maxFrames: maxFrames
          )
          DispatchQueue.main.async {
            result([
              "durationMs": durationMs,
              "framePaths": framePaths.map { $0.path },
              "frameTimestampMs": framePaths.map { $0.timestampMs },
            ])
          }
        } catch {
          self.fail(result, error)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func durationMs(path: String) throws -> Int {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let seconds = CMTimeGetSeconds(asset.duration)
    guard seconds.isFinite, seconds > 0 else {
      throw VideoFrameError.unreadableDuration
    }
    return Int((seconds * 1000).rounded())
  }

  private func extractFrameFiles(
    path: String,
    durationMs: Int,
    maxFrames: Int
  ) throws -> [(path: String, timestampMs: Int)] {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 720, height: 720)
    generator.requestedTimeToleranceBefore = CMTime(seconds: 0.25, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = CMTime(seconds: 0.25, preferredTimescale: 600)

    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("sookta_video_frames", isDirectory: true)
    try FileManager.default.createDirectory(
      at: outputDirectory,
      withIntermediateDirectories: true
    )
    if let files = try? FileManager.default.contentsOfDirectory(
      at: outputDirectory,
      includingPropertiesForKeys: nil
    ) {
      for file in files where file.lastPathComponent.hasPrefix("frame_") {
        try? FileManager.default.removeItem(at: file)
      }
    }

    let frameCount = max(1, min(maxFrames, 8))
    let durationSeconds = Double(durationMs) / 1000.0
    var frames: [(path: String, timestampMs: Int)] = []
    for index in 0..<frameCount {
      let fraction = Double(index + 1) / Double(frameCount + 1)
      let seconds = durationSeconds * fraction
      let time = CMTime(seconds: seconds, preferredTimescale: 600)
      let image = try generator.copyCGImage(at: time, actualTime: nil)
      let uiImage = UIImage(cgImage: image)
      guard let data = uiImage.jpegData(compressionQuality: 0.86) else {
        continue
      }
      let file = outputDirectory.appendingPathComponent(
        "frame_\(Int(Date().timeIntervalSince1970 * 1000))_\(index).jpg"
      )
      try data.write(to: file, options: .atomic)
      frames.append((path: file.path, timestampMs: Int((seconds * 1000).rounded())))
    }
    return frames
  }

  private func fail(_ result: @escaping FlutterResult, _ error: Error) {
    DispatchQueue.main.async {
      result(FlutterError(
        code: "VIDEO_FRAME_EXTRACTION_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }
}

private enum VideoFrameError: LocalizedError {
  case invalidArguments
  case unreadableDuration
  case tooLong

  var errorDescription: String? {
    switch self {
    case .invalidArguments:
      return "Video path is required."
    case .unreadableDuration:
      return "Could not read video duration."
    case .tooLong:
      return "Video must be 20 seconds or shorter."
    }
  }
}
