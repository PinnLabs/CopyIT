import AppKit
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 10) {
                itemPreview
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.content)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isHovering || isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    @ViewBuilder
    private var itemPreview: some View {
        if item.type == .image,
           let data = item.imageData,
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 16)
        }
    }

    private var backgroundColor: Color {
        if isSelected { return Color.accentColor.opacity(0.22) }
        if isHovering { return Color.accentColor.opacity(0.12) }
        return .clear
    }

    private var iconName: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        case .unknown: return "questionmark.square"
        }
    }
}
