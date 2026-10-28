import Foundation
import SwiftUI

@MainActor
final class PoCViewModel: ObservableObject {

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let message: String
    }

    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var fdCount: Int = 0
    @Published private(set) var initialFD: Int = 0
    @Published private(set) var isRunning: Bool = false

    private let poc = CoreMediaPoC()
    private let iterations = 200

    init() {
        initialFD = CoreMediaPoC.openFDCount()
        fdCount = initialFD
        log("Ready. Baseline FDs: \(initialFD)")
    }

    func run() {
        guard !isRunning else { return }
        isRunning = true
        log("Starting \(iterations) iterations…")

        Task {
            do {
                let result = try await poc.run(iterations: iterations) { [weak self] done, fds in
                    Task { @MainActor in
                        guard let self else { return }
                        self.fdCount = fds
                        if done % 10 == 0 || done == self.iterations {
                            self.log("iter \(done)/\(self.iterations) — FDs: \(fds)")
                        }
                    }
                }
                self.initialFD = result.baseline
                self.fdCount = result.final
                let delta = result.final - result.baseline
                log(delta > 0
                    ? "⚠️ FD leak detected: +\(delta)"
                    : "✅ No leak. delta: \(delta)")
            } catch CoreMediaPoC.PoCError.noSampleFile {
                log("❌ sample.mov missing from bundle — drop one into Resources/.")
            } catch {
                log("❌ \(error.localizedDescription)")
            }
            self.isRunning = false
        }
    }

    func clearLogs() {
        logs.removeAll()
        log("Logs cleared.")
    }

    private func log(_ message: String) {
        logs.append(LogEntry(message: message))
    }
}
