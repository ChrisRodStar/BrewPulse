import SwiftUI

struct StatusMenuHeader: View {
    var body: some View {
        Label("BrewPulse", systemImage: "mug.fill")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
    }
}
