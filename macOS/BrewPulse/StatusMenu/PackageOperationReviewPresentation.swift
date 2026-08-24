import AppKit
import Observation
import SwiftUI

@Observable
@MainActor
final class PackageOperationReviewPresentation {
    static let windowID = "package-operation-review"

    private(set) var plan: HomebrewOperationPlan?

    func present(_ plan: HomebrewPackageOperationPlan) {
        self.plan = .package(plan)
    }

    func present(_ plan: HomebrewOperationPlan) {
        self.plan = plan
    }

    func clear(_ plan: HomebrewOperationPlan) {
        guard self.plan == plan else { return }
        self.plan = nil
    }
}

struct PackageOperationReviewWindow: View {
    @Environment(\.dismissWindow) private var dismissWindow
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
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
        .background {
            PackageOperationReviewWindowConfigurator(plan: presentation.plan)
                .frame(width: 0, height: 0)
        }
        .onChange(of: presentation.plan, initial: true) { _, plan in
            guard plan == nil else { return }
            dismissWindow(id: PackageOperationReviewPresentation.windowID)
        }
    }
}

private struct PackageOperationReviewWindowConfigurator: NSViewRepresentable {
    let plan: HomebrewOperationPlan?

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
