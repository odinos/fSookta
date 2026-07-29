import AVFoundation
import CoreImage
import CoreVideo
import Foundation

guard CommandLine.arguments.count == 2 else {
  fatalError("Usage: swift generate_video_contract_fixture.swift <output.mp4>")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.removeItem(at: outputURL)

let width = 360
let height = 640
let framesPerSecond = 10
let durationSeconds = 4
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let input = AVAssetWriterInput(
  mediaType: .video,
  outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
  ]
)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
  assetWriterInput: input,
  sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String:
      kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
  ]
)
guard writer.canAdd(input) else {
  fatalError("Cannot add video input")
}
writer.add(input)
guard writer.startWriting() else {
  fatalError(writer.error?.localizedDescription ?? "Cannot start writer")
}
writer.startSession(atSourceTime: .zero)

let context = CIContext()
let colorSpace = CGColorSpaceCreateDeviceRGB()
let frameDuration = CMTime(value: 1, timescale: Int32(framesPerSecond))
let frameRect = CGRect(x: 0, y: 0, width: width, height: height)

for frameIndex in 0..<(framesPerSecond * durationSeconds) {
  while !input.isReadyForMoreMediaData {
    Thread.sleep(forTimeInterval: 0.002)
  }
  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferPoolCreatePixelBuffer(
    nil,
    adaptor.pixelBufferPool!,
    &pixelBuffer
  )
  guard status == kCVReturnSuccess, let pixelBuffer else {
    fatalError("Cannot allocate pixel buffer")
  }

  let progress = CGFloat(frameIndex) /
    CGFloat(framesPerSecond * durationSeconds - 1)
  let background = CIImage(
    color: CIColor(
      red: 0.08 + progress * 0.12,
      green: 0.35,
      blue: 0.18
    )
  ).cropped(to: frameRect)
  let marker = CIImage(color: CIColor(red: 1, green: 0.75, blue: 0.1))
    .cropped(
      to: CGRect(
        x: 30 + progress * 240,
        y: 220,
        width: 60,
        height: 200
      )
    )
    .composited(over: background)
  context.render(
    marker,
    to: pixelBuffer,
    bounds: frameRect,
    colorSpace: colorSpace
  )
  let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
  guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
    fatalError(writer.error?.localizedDescription ?? "Cannot append frame")
  }
}

input.markAsFinished()
let semaphore = DispatchSemaphore(value: 0)
writer.finishWriting {
  semaphore.signal()
}
semaphore.wait()
guard writer.status == .completed else {
  fatalError(writer.error?.localizedDescription ?? "Video generation failed")
}
