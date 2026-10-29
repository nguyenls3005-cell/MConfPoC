import Foundation
import CoreMedia
import AVFoundation

/// PoC harness for CVE-2026-112706.
/// Repeatedly opens/closes media assets and sample-buffer pipelines
/// to surface an FD leak in CoreMedia's descriptor handling.
final class CoreMediaPoC {

    enum PoCError: Error {
        case noSampleFile
        case readerFailed
    }

    private let bundleAssetName: String
    private let bundleAssetExtension: String

    init(bundleAssetName: String = "sample", bundleAssetExtension: String = "mov") {
        self.bundleAssetName = bundleAssetName
        self.bundleAssetExtension = bundleAssetExtension
    }

    /// Number of currently open file descriptors for this process.
    /// Uses fcntl instead of /dev/fd because iOS sandbox blocks directory listing.
    static func openFDCount() -> Int {
        var count = 0
        for fd in 0..<1024 {
            if fcntl(Int32(fd), F_GETFD) != -1 {
                count += 1
            }
        }
        return count
    }

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

    private func iterate(assetURL: URL) async throws {
        let asset = AVURLAsset(url: assetURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        // Safely load tracks using the modern async API
        let tracks = try await asset.load(.tracks)
        let reader = try AVAssetReader(asset: asset)
        
        for track in tracks {
            guard track.mediaType == .video || track.mediaType == .audio else { continue }
            // nil settings means passthrough, avoiding pixel buffer format crashes
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            if reader.canAdd(output) { reader.add(output) }
        }
        
        guard reader.startReading() else {
            throw PoCError.readerFailed
        }

        // Drain buffers safely without hanging forever
        if let first = reader.outputs.first as? AVAssetReaderTrackOutput {
            var safety = 0
            while reader.status == .reading && safety < 16 {
                if first.copyNextSampleBuffer() == nil { break }
                safety += 1
            }
        }

        reader.cancelReading()
        try? FileManager.default.removeItem(at: assetURL)
    }

    func run(iterations: Int,
             onProgress: @escaping @Sendable (Int, Int) -> Void) async throws -> (baseline: Int, final: Int) {
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