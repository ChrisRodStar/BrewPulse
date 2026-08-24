---
version: 1
slug: "brewpulse-macos-brewpulse-brewpulseapp-swift"
primary_target: "brewpulse/macOS/BrewPulse/BrewPulseApp.swift"
related_targets: ["brewpulse/macOS/BrewPulse/StatusMenu/StatusMenuView.swift","brewpulse/macOS/BrewPulse/StatusMenu/HomebrewStatusView.swift"]
---

Scope: BrewPulse's 400 by 520 macOS menu-bar status popover.
Mode: Operate.
Audience: Mac users who install applications and command-line tools through Homebrew and want a fast, understandable check for updates.
Primary job: Answer how many packages are installed, which actionable updates exist, and what BrewPulse will run before the user approves one update or all updates.
Primary action: Review one update or Review All.
Supporting actions: Switch between Overview and Updates; refresh package information; open Settings; quit BrewPulse.
Required proof: Exact command review remains explicit. Total installed, Homebrew version, actionable update count, retained refresh failures, operation progress and output, and last-checked time remain visible.
Constraints: Preserve MenuBarExtra window behavior, keyboard shortcuts, VoiceOver labels, Dynamic Type, reduced motion, localization-ready strings, and the existing PackageStore state model.
Approved direction: Civic Signal, Line Platform, with the approved raster mug identity. Use the approved comp at /Users/chris/Desktop/projects/Apps/BrewPulse/.impeccable/mocks/civic-signal-line-platform.png for layout and the approved mug assets for identity.
Visual world: Mineral white and graphite, the graphite mug with an iris interior, iris navigation, amber for updates, green for successful/current states, thin separators, flat native surfaces, and restrained corner radii.
Memorable moment: The compact mug stays recognizable from the menu bar through the app header and Settings. The amber update field gives the first useful answer and opens the focused action list without turning the popover into a dashboard.
Deliberate adaptation: Remove installed Cask and Formula browsing at the user's direction. Omit the comp's duplicate top-right refresh control because the footer already exposes Refresh with Command-R. Omit chevrons where no destination exists. Preserve every real state and action.
Unresolved: The website direction will reuse this system in a later pass.
