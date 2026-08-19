import AppKit
import SwiftUI

struct OpenSettingsButton: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(ApplicationPresentationController.self)
    private var presentation

    var body: some View {
        Button {
            presentation.showSettingsPresence()
            openSettings()
            presentation.activate()
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
        .help("Open BrewPulse settings")
    }
}
