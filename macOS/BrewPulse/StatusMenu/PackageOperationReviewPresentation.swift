import AppKit
import Observation
import SwiftUI

@Observable
@MainActor
final class PackageOperationReviewPresentation {
    static let windowID = "package-operation-review"

    private(set) var plan: HomebrewPackageOperationPlan?

    func present(_ plan: HomebrewPackageOperationPlan) {
        self.plan = plan
    }

    func clear(_ plan: HomebrewPackageOperationPlan) {
        guard self.plan == plan else { return }
        self.plan = nil
    }
}

struct PackageOperationReviewWindow: View {
    @Environment(PackageOperationReviewPresentation.self)
    private var presentation

    var body: some View {
        Group {
            if let plan = presentation.plan {
                PackageOperationCommandPreview(plan: plan)
                    .onDisappear {
                        presentation.clear(plan)
                    }
            } else {
                ContentUnavailableView(
                    "No Package Action Selected",
                    systemImage: "shippingbox",
                    description: Text("Choose an action from BrewPulse.")
                )
                .frame(width: 560, height: 300)
            }
        }
        .background {
            PackageOperationReviewWindowConfigurator(plan: presentation.plan)
                .frame(width: 0, height: 0)
        }
    }
}

private struct PackageOperationReviewWindowConfigurator: NSViewRepresentable {
    let plan: HomebrewPackageOperationPlan?

    func makeNSView(context: Context) -> WindowAttachmentView {
        WindowAttachmentView()
    }

    func updateNSView(_ nsView: WindowAttachmentView, context: Context) {
        nsView.configureWindow()
    }
}

private extension PackageOperationReviewWindowConfigurator {
    final class WindowAttachmentView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
        }

        func configureWindow() {
            guard let window else { return }

            Task { @MainActor [weak window] in
                await Task.yield()
                guard let window else { return }

                window.level = .floating
                window.center()
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
