import SwiftUI

struct PopoverView: View {
    @Bindable var viewModel: PopoverViewModel
    var onQuit: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            header
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal, 10)
            Divider()
            list
            Divider()
            footer
        }
        .padding(.vertical, 8)
        .frame(width: 360, height: 480)
        .background(VisualEffectBackground())
        .onAppear { viewModel.refresh() }
        .background(keyboardHandler)
    }

    private var header: some View {
        HStack {
            Text("Clipboard")
                .font(.headline)
            Spacer()
            Button(action: viewModel.clearAll) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Clear history")
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.filteredItems.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(viewModel.searchText.isEmpty ? "No items yet" : "No matches")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.filteredItems) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: viewModel.isSelected(item),
                                onCopy: {
                                    viewModel.copy(item)
                                    onClose()
                                },
                                onDelete: { viewModel.delete(item) }
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .onChange(of: viewModel.selectedIndex) { _, newIndex in
                    guard viewModel.filteredItems.indices.contains(newIndex) else { return }
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(viewModel.filteredItems[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(viewModel.filteredItems.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit", action: onQuit)
                .buttonStyle(.plain)
                .font(.caption)
        }
        .padding(.horizontal, 12)
    }

    private var keyboardHandler: some View {
        KeyEventHandling(
            onArrowDown: { viewModel.moveSelection(by: 1) },
            onArrowUp: { viewModel.moveSelection(by: -1) },
            onReturn: {
                viewModel.copySelected()
                onClose()
            },
            onDelete: { viewModel.deleteSelected() },
            onEscape: { onClose() }
        )
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct KeyEventHandling: NSViewRepresentable {
    let onArrowDown: () -> Void
    let onArrowUp: () -> Void
    let onReturn: () -> Void
    let onDelete: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.handlers = .init(
            arrowDown: onArrowDown,
            arrowUp: onArrowUp,
            returnKey: onReturn,
            deleteKey: onDelete,
            escape: onEscape
        )
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.handlers = .init(
            arrowDown: onArrowDown,
            arrowUp: onArrowUp,
            returnKey: onReturn,
            deleteKey: onDelete,
            escape: onEscape
        )
    }
}

final class KeyCaptureView: NSView {
    struct Handlers {
        let arrowDown: () -> Void
        let arrowUp: () -> Void
        let returnKey: () -> Void
        let deleteKey: () -> Void
        let escape: () -> Void
    }

    var handlers: Handlers?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: handlers?.arrowDown()
        case 126: handlers?.arrowUp()
        case 36, 76: handlers?.returnKey()
        case 51, 117: handlers?.deleteKey()
        case 53: handlers?.escape()
        default: super.keyDown(with: event)
        }
    }
}
