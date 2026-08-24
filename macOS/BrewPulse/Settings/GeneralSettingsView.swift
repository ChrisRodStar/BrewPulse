import SwiftUI

struct GeneralSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var settings
    @EnvironmentObject private var updater: AppUpdater

    var body: some View {
        Form {
            Section("General") {
                Toggle(isOn: launchAtLoginBinding) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Launch BrewPulse at login")
                        Text("Keep update status available from the menu bar after you sign in.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .disabled(settings.launchAtLoginStatus == .unavailable)
                .accessibilityHint(launchAtLoginAccessibilityHint)

                if settings.launchAtLoginStatus == .requiresApproval {
                    LaunchAtLoginApprovalNotice(
                        openSystemSettings: settings.openLoginItemSettings
                    )
                }
            }

            Section("Updates") {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BrewPulse updates")
                        Text(updateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Check for Updates…", action: updater.checkForUpdates)
                        .disabled(!updater.canCheckForUpdates)
                        .help("Check whether a newer version of BrewPulse is available")
                }
                .accessibilityElement(children: .contain)
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .task {
            settings.refreshLaunchAtLoginStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                settings.refreshLaunchAtLoginStatus()
            }
        }
        .alert(
            "Unable to Change Login Setting",
            isPresented: launchAtLoginErrorBinding
        ) {
            Button("OK", role: .cancel) {
                settings.dismissLaunchAtLoginError()
            }
        } message: {
            Text(settings.launchAtLoginErrorMessage ?? "Please try again.")
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchesAtLogin },
            set: settings.setLaunchesAtLogin
        )
    }

    private var launchAtLoginErrorBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    settings.dismissLaunchAtLoginError()
                }
            }
        )
    }

    private var launchAtLoginAccessibilityHint: String {
        switch settings.launchAtLoginStatus {
        case .requiresApproval:
            "Enabled, but approval is required in System Settings."
        case .unavailable:
            "This setting is unavailable for the current app installation."
        case .disabled, .enabled:
            "Controls whether BrewPulse opens automatically when you sign in."
        }
    }

    private var updateDescription: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "Unknown"
        return "Version \(version). BrewPulse checks automatically and asks before installing."
    }
}

private struct LaunchAtLoginApprovalNotice: View {
    let openSystemSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Approval required")
                    .font(.headline)
                Text("Allow BrewPulse in System Settings to finish enabling launch at login.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Open Login Items", action: openSystemSettings)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
    }
}
