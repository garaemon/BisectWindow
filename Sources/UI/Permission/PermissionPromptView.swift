import SwiftUI

struct PermissionPromptView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "BisectWindow needs Accessibility access",
                systemImage: "lock.shield"
            )
            .font(.headline)

            Text("BisectWindow moves and resizes windows of other apps, and macOS allows that only for apps with Accessibility access.")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("1. Click Open System Settings.")
                Text("2. Turn on BisectWindow in the Accessibility list.")
                Text("3. Come back. BisectWindow starts on its own.")
            }
            .foregroundStyle(.secondary)

            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for permission…")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Open System Settings", action: onOpenSettings)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
