import SwiftUI

struct ContentView: View {
    @StateObject private var vm = PoCViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft, adaptive background
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    header
                    statusCard
                    triggerButton
                    logSection
                }
                .padding(20)
            }
            .navigationTitle("MConfPoC")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark) // Keeping dark mode, but softer
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CVE-2026-112706")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text("CoreMedia File-Descriptor Leak")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current File Descriptors")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(vm.fdCount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(vm.fdCount > vm.initialFD ? Color.red : Color.primary)
                    .contentTransition(.numericText())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Baseline: \(vm.initialFD)")
                    Text("Delta: +\(max(0, vm.fdCount - vm.initialFD))")
                        .foregroundStyle(vm.fdCount > vm.initialFD ? Color.red : Color.green)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var triggerButton: some View {
        Button(action: { vm.run() }) {
            HStack {
                Image(systemName: vm.isRunning ? "hourglass" : "play.fill")
                Text(vm.isRunning ? "Running…" : "Run PoC")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(vm.isRunning ? Color.gray.opacity(0.3) : Color.orange)
            .foregroundStyle(vm.isRunning ? Color.secondary : Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(vm.isRunning)
        .animation(.easeInOut, value: vm.isRunning)
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity Log")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") { vm.clearLogs() }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.red)
            }
            
            LogView(entries: vm.logs)
                .frame(maxHeight: .infinity)
        }
    }
}