import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PrivacySettingsView: View {
    private static let listHeight: CGFloat = 140
    private static let iconSize: CGFloat = 16

    @Bindable var viewModel: PrivacySettingsViewModel
    @State private var isConfirmingRestore = false

    var body: some View {
        Form {
            Section("Ignored apps") {
                Text("Items copied while these apps are frontmost aren't saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ignoredAppsList
            }

            Section("History") {
                Picker("Delete items older than", selection: $viewModel.retention) {
                    ForEach(viewModel.retentionOptions, id: \.self) { retention in
                        Text(retention.title).tag(retention)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Clear history when quitting CopyIT", isOn: $viewModel.clearsHistoryOnQuit)
                    Text("If CopyIT is force-quit or crashes, the history is cleared the next time it opens.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Items that password managers mark as sensitive are never saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Restore the default ignored apps?", isPresented: $isConfirmingRestore) {
            Button("Restore Defaults", role: .destructive) { viewModel.restoreDefaultIgnoredApps() }
        } message: {
            Text("Your current list will be replaced.")
        }
    }

    private var ignoredAppsList: some View {
        VStack(spacing: 0) {
            List(selection: $viewModel.selectedAppID) {
                ForEach(viewModel.ignoredApps) { app in
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: Self.iconSize, height: Self.iconSize)
                        } else {
                            Image(systemName: "app.dashed")
                                .frame(width: Self.iconSize, height: Self.iconSize)
                        }
                        Text(app.name)
                    }
                    .help(app.id)
                    .tag(app.id)
                }
            }
            .frame(height: Self.listHeight)

            Divider()

            HStack(spacing: 0) {
                Button(action: chooseApp) {
                    Image(systemName: "plus").frame(width: 24, height: 20)
                }
                .accessibilityLabel("Add app")
                Divider().frame(height: 16)
                Button(action: viewModel.removeSelectedApp) {
                    Image(systemName: "minus").frame(width: 24, height: 20)
                }
                .accessibilityLabel("Remove app")
                .disabled(viewModel.selectedAppID == nil)
                Spacer()
                Button("Restore Defaults") { isConfirmingRestore = true }
            }
            .buttonStyle(.borderless)
            .padding(4)
        }
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else { return }
        viewModel.addApp(bundleIdentifier: bundleIdentifier)
    }
}

private extension HistoryRetention {
    var title: String {
        switch self {
        case .forever: return "Never"
        case .oneDay: return "1 day"
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .ninetyDays: return "90 days"
        }
    }
}
