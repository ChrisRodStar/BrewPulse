import Testing
@testable import BrewPulse

@Suite("BrewPulse menu-bar label")
struct BrewPulseMenuBarLabelTests {
    @Test("Describes pending and zero-update states")
    func pendingAndCurrentStates() {
        #expect(
            BrewPulseMenuBarLabelPresentation(updateCount: nil).accessibilityLabel
                == "BrewPulse"
        )
        #expect(
            BrewPulseMenuBarLabelPresentation(updateCount: 0).accessibilityLabel
                == "BrewPulse, no updates available"
        )
    }

    @Test("Uses singular and plural update descriptions")
    func updateDescriptions() {
        #expect(
            BrewPulseMenuBarLabelPresentation(updateCount: 1).accessibilityLabel
                == "BrewPulse, 1 update available"
        )
        #expect(
            BrewPulseMenuBarLabelPresentation(updateCount: 3).accessibilityLabel
                == "BrewPulse, 3 updates available"
        )
    }
}
