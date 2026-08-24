import SwiftUI

struct BrewPulseSettingsView: View {
    @Environment(ApplicationPresentationController.self)
    private var presentation

    var body: some View {
        VStack(spacing: 0) {
            SettingsIdentityHeader()
            Divider()
            GeneralSettingsView()
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 320)
        .background {
            SettingsWindowLifecycleObserver(
                windowDidOpen: presentation.showSettingsPresence,
                windowDidClose: presentation.hideSettingsPresence
            )
            .frame(width: 0, height: 0)
        }
    }
}

private struct SettingsIdentityHeader: View {
    var body: some View {
        HStack(spacing: 14) {
            Image("BrewPulseAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("BrewPulse")
                    .font(.title2.bold())
                Text("Homebrew updates at a glance.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("BrewPulse settings") {
    BrewPulseSettingsView()
        .environment(AppSettings())
        .environment(ApplicationPresentationController())
        .environmentObject(AppUpdater(startingUpdater: false))
}
#endif
