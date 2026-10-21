import SwiftUI

struct SettingsView: View {
    private static let width: CGFloat = 460

    let viewModel: SettingsViewModel

    var body: some View {
        // New tabs (e.g. Privacy) go next to General.
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: Self.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Launch CopyIT at login", isOn: Binding(
                    get: { viewModel.isLaunchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
                if viewModel.launchAtLoginRequiresApproval {
                    HStack {
                        Text("Approve CopyIT in System Settings → General → Login Items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Login Items") { viewModel.openLoginItemsSettings() }
                    }
                }
            }

            Section {
                Picker("History size", selection: $viewModel.historyLimit) {
                    ForEach(viewModel.historyLimitOptions, id: \.self) { limit in
                        Text("\(limit) items").tag(limit)
                    }
                }
                LabeledContent("Shortcut", value: viewModel.shortcutDescription)
            }

            Section {
                HStack {
                    Text("CopyIT \(viewModel.appVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let url = viewModel.repositoryURL {
                        Link("GitHub", destination: url)
                    }
                }
                .font(.caption)
            }
        }
        .formStyle(.grouped)
    }
}
