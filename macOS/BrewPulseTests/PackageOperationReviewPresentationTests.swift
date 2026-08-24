import Foundation
import Testing
@testable import BrewPulse

@MainActor
@Suite("Package operation review presentation")
struct PackageOperationReviewPresentationTests {
    @Test("Tracks and clears only the matching operation plan")
    func planLifecycle() {
        let presentation = PackageOperationReviewPresentation()
        let firstPlan = plan(named: "first-app", kind: .update)
        let secondPlan = plan(named: "first-app", kind: .uninstall)

        #expect(presentation.plan == nil)

        presentation.present(firstPlan)
        #expect(presentation.plan == .package(firstPlan))

        presentation.clear(.package(secondPlan))
        #expect(presentation.plan == .package(firstPlan))

        presentation.clear(.package(firstPlan))
        #expect(presentation.plan == nil)
    }

    private func plan(
        named name: String,
        kind: HomebrewPackageOperationKind
    ) -> HomebrewPackageOperationPlan {
        let package = HomebrewPackage(
            name: name,
            versions: HomebrewPackageVersions(
                installed: ["1.0"],
                available: "2.0"
            ),
            kind: .cask,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )

        return HomebrewPackageOperationPlan(
            kind: kind,
            package: package,
            command: CommandRequest(
                executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
                arguments: [
                    kind == .update ? "upgrade" : "uninstall",
                    "--cask",
                    "--",
                    name
                ]
            )
        )
    }
}
