import SwiftUI

struct PopoverView: View {
    @Bindable var viewModel: PopoverViewModel
    var onQuit: () -> Void = {}
    var onOpenSettings: () -> Void = {}
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
        // Handled here rather than by a first-responder view so the keys work while the search
        // field keeps focus; unhandled keys (including ⌫) fall through to the field.
        .onKeyPress(.downArrow) {
            viewModel.moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            viewModel.moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.copySelected()
            onClose()
            return .handled
        }
        .onKeyPress(.escape) {
            if viewModel.handleEscape() {
                onClose()
            }
            return .handled
        }
        .background(deleteSelectedShortcut)
    }

    /// ⌘⌫ deletes the selected item even while the search field has focus.
    private var deleteSelectedShortcut: some View {
        Button("Delete Selected Item", action: viewModel.deleteSelected)
            .keyboardShortcut(.delete, modifiers: .command)
            .hidden()
            .accessibilityHidden(true)
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
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .font(.caption)
            .help("Settings")
            .accessibilityLabel("Settings")
            Button("Quit", action: onQuit)
                .buttonStyle(.plain)
                .font(.caption)
        }
        .padding(.horizontal, 12)
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
