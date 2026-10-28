import SwiftUI

struct LogView: View {
    let entries: [PoCViewModel.LogEntry]

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Text(Self.fmt.string(from: entry.timestamp))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(entry.message)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        .id(entry.id)
                    }
                }
                .padding(8)
            }
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onChange(of: entries.count) { _, _ in
                if let last = entries.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
}
