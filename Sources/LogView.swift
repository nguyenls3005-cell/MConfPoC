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
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            Text(Self.fmt.string(from: entry.timestamp))
                                .font(.system(.caption2, design: .rounded).monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(entry.message)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(entry.message.contains("❌") ? .red : entry.message.contains("⚠️") ? .orange : .primary)
                                .lineLimit(nil)
                        }
                        .id(entry.id)
                    }
                }
                .padding(16)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onChange(of: entries.count) { _, _ in
                if let last = entries.last {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
}