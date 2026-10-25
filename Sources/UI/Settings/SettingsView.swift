import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            keyBindingsTab
                .tabItem { Label("Key Bindings", systemImage: "keyboard") }
        }
        .frame(minWidth: 460, minHeight: 220)
        .padding(20)
    }

    private var generalTab: some View {
        Form {
            Toggle(
                "Show overlay indicator while prefix key is held",
                isOn: $viewModel.isOverlayEnabled
            )
            Text("The indicator appears in the bottom-right corner of the main screen as a small app icon to confirm BisectWindow is listening for follow-up keys.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }

    private var keyBindingsTab: some View {
        Form {
            Picker("Prefix Key", selection: $viewModel.selectedPrefix) {
                ForEach(PrefixOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            Text("Hold the prefix combination, then press Left/Right/Up/Down to tile, or F to maximize.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}
