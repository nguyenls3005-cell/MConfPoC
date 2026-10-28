import SwiftUI

struct ContentView: View {
    @StateObject private var vm = PoCViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                triggerButton
                statusCard
                logSection
            }
            .padding()
            .navigationTitle("MConfPoC")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CVE-2026-112706")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("CoreMedia File-Descriptor Leak PoC")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var triggerButton: some View {
        Button(action: { vm.run() }) {
            HStack {
                Image(systemName: vm.isRunning ? "hourglass" : "play.fill")
                Text(vm.isRunning ? "Running…" : "Run PoC")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(vm.isRunning ? Color.gray : Color.orange)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(vm.isRunning)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("File Descriptors").font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("\(vm.fdCount)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(vm.fdCount > vm.initialFD ? .red : .green)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("baseline: \(vm.initialFD)").font(.caption2)
                    Text("delta: +\(max(0, vm.fdCount - vm.initialFD))")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Log").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Clear") { vm.clearLogs() }
                    .font(.caption2)
            }
            LogView(entries: vm.logs)
                .frame(maxHeight: .infinity)
        }
    }
}
