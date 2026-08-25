---
name: BrewPulse
description: Calm, explicit Homebrew maintenance for macOS.
colors:
  iris-light: "#5E54F6"
  iris-dark: "#9B8CFF"
  canvas-light: "#F5F6F4"
  canvas-dark: "#111315"
  surface-light: "#FFFFFF"
  surface-dark: "#1A1D21"
  text-light: "#111315"
  text-dark: "#F5F6F4"
  secondary-light: "#62686F"
  secondary-dark: "#A8ADB3"
  divider-light: "#D9DDDA"
  divider-dark: "#30343A"
  update-light: "#6B4300"
  update-dark: "#FFD166"
  update-surface-light: "#FFF2D2"
  update-surface-dark: "#332B13"
  update-strong-light: "#F2B84B"
  update-strong-dark: "#D99B2B"
  success-light: "#116B42"
  success-dark: "#4BD591"
  success-surface-light: "#E6F8EF"
  success-surface-dark: "#123324"
  danger-light: "#B4233B"
  danger-dark: "#FF7A8C"
  danger-surface-light: "#FDECEF"
  danger-surface-dark: "#3B171E"
typography:
  title:
    fontFamily: ".AppleSystemUIFont, sans-serif"
    fontSize: "17px"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: ".AppleSystemUIFont, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  body:
    fontFamily: ".AppleSystemUIFont, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.3
  callout:
    fontFamily: ".AppleSystemUIFont, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.3
  label:
    fontFamily: ".AppleSystemUIFont, sans-serif"
    fontSize: "10px"
    fontWeight: 500
    lineHeight: 1.25
rounded:
  focus: "6px"
  notice: "8px"
  status: "9px"
  recovery: "10px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  content: "14px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
components:
  update-summary-actionable-light:
    backgroundColor: "{colors.update-strong-light}"
    textColor: "{colors.text-light}"
    typography: "{typography.headline}"
    rounded: "{rounded.status}"
    padding: "13px 14px"
  update-summary-current-light:
    backgroundColor: "{colors.success-surface-light}"
    textColor: "{colors.success-light}"
    typography: "{typography.headline}"
    rounded: "{rounded.status}"
    padding: "13px 14px"
  route-selected-light:
    textColor: "{colors.text-light}"
    typography: "{typography.callout}"
    rounded: "{rounded.focus}"
    padding: "0 6px"
  button-primary-light:
    backgroundColor: "{colors.iris-light}"
    textColor: "{colors.surface-light}"
    typography: "{typography.callout}"
    rounded: "{rounded.focus}"
    padding: "5px 10px"
---

# BrewPulse design system

## Overview

**Creative North Star: "Civic Signal"**

BrewPulse treats package maintenance like calm public infrastructure. Neutral surroundings keep the interface quiet. A clear iris route shows location, and amber appears only when there is work to review.

The app answers a few concrete questions, makes the next action obvious, and shows the exact Homebrew command before anything runs. It should never feel like a Terminal wrapper, an inventory database, or a coffee-themed utility.

**Key Characteristics:**

- Native macOS controls and SF typography
- Flat mineral and graphite surfaces
- Iris navigation and an approved raster mug identity
- One decisive amber update field
- Explicit review before execution

## Colors

The palette is cool-neutral and restrained. Color marks identity, focus, and state instead of decorating containers.

### Primary

- **Iris Route:** selected navigation, keyboard focus, links, and primary actions.

### Secondary

- **Service Amber:** the strong field on an Overview with actionable updates.
- **Update Ink and Wash:** update icons, retained-snapshot warnings, and quiet update status treatments.
- **Clear Green and Wash:** current and successful states.
- **Stop Red and Wash:** failures and destructive actions.

### Neutral

- **Mineral Canvas and Graphite Canvas:** the light and dark app ground.
- **Paper Surface and Night Surface:** headers, footers, and contained notices.
- **Primary Ink:** the main text color in each appearance.
- **Secondary Ink:** supporting copy, timestamps, and version changes.
- **Route Divider:** one-pixel separation between structural regions and list rows.

**The signal rule.** Iris means identity or interaction. Amber means an update can be reviewed. Green means no work is needed. Red means failure or destruction. Do not swap these roles.

## Typography

**Display Font:** SF Pro through the macOS system font

**Body Font:** SF Pro through the macOS system font
**Label/Mono Font:** SF Mono only for commands and version data

**Character:** Compact, familiar, and direct. Hierarchy comes from native macOS size and weight steps, not oversized numbers or decorative casing.

### Hierarchy

- **Title:** bold native title styling for command-review and output-detail window titles.
- **Headline:** semibold native headline styling for the wordmark, update state, and operation state.
- **Body:** regular native body styling for explanations and controls.
- **Callout:** compact facts, navigation, package names, and supporting notices.
- **Label:** captions, timestamps, version changes, and supporting status.
- **Monospaced data:** SF Mono for exact commands; monospaced numerals for counts and versions.

**The native scale rule.** Use semantic SwiftUI text styles so accessibility sizes remain intact. Fixed sizing is reserved for the 19-point status icon and the 34-point initial-error symbol.

## Layout

The menu-bar popover is 400 by 520 points. Its fixed header, two-stop route selector, and footer frame one flexible content region. Most horizontal insets are 14 or 16 points. The layout uses compact 8-to-18-point spacing and one-pixel dividers rather than cards.

Overview is one large state field rather than a stack of rows or metric columns. The current state fills a green canvas; actionable updates use the same composition in amber. Status leads at the top, the installed total anchors the lower-left, and Homebrew version plus freshness finish the reading path along the lower edge. The shield promise stays directly below the field. At larger accessibility sizes, the content scrolls instead of clipping.

Updates shows only actionable packages. Its fixed list header pairs the update count with Review All, followed by rows for package name, installed-to-available version change, and individual Review. Installed Casks and Formulae are intentionally not browsable here.

**The two-stop rule.** The popover has exactly two destinations: Overview and Updates. New package-maintenance detail belongs in one of those destinations or in a focused review or output window.

## Elevation & Depth

The system is flat by default. Native window chrome owns the outer shadow. Inside the popover, tonal layers and one-pixel dividers establish depth. Do not add decorative shadows, glass effects, or bordered cards.

**The flat-inside rule.** A surface may change tone to communicate state, but it does not lift away from the popover.

## Shapes

Corners are restrained and contextual: 9 points for the update summary, 8 points for notices, 10 points for the Homebrew recovery panel, and 6 points for focus treatments. Pills are limited to compact status controls and the two-point route underline. The approved graphite mug is the identity mark at app-icon, status-header, Settings, and menu-bar scales.

## Components

### Buttons

- **Primary:** native bordered-prominent controls use Iris Route for Update All and confirmed, non-destructive actions.
- **Review controls:** labels end with an ellipsis because they open command review before execution.
- **Focus:** stays visible on the individual control. Never paint a focus state around an entire group.
- **Disabled:** preserves the label and explains why the action is unavailable to accessibility users.

### Update summary

- **Actionable:** Primary Ink on Service Amber, with an update icon, exact count, short explanation, and View Updates.
- **Current:** Clear Green on a large quiet field, with one compact status checkmark and no action button.
- **Copy:** use "1 update available" or "2 updates available." Avoid novelty language.

### Navigation

Overview and Updates form one horizontal route with equal-width stops. Updates includes the actionable count in parentheses. The selected destination uses semibold text and a two-point iris underline. Left and right arrow keys change destinations. Reduced Motion removes the 0.18-second underline transition.

### Update rows

Show the update icon, package name, installed-to-available version change, and Review. Middle-truncate long names and versions so the action remains visible. Do not show package type, uninstall controls, current packages, or inventory metadata.

### Trust and freshness

The shield promise and relative last-checked time stay in the same reading path. While refreshing retained data, the footer Refresh control becomes a compact spinner with “Refreshing…” instead of adding a progress bar above the content. A retained-snapshot failure replaces the normal freshness state with an amber notice, an absolute snapshot time, preserved command details, and disabled package actions.

### Command review

Open a focused native window before one or all updates. Name the included package or package set, show the exact Homebrew command in selectable monospaced text, state that nothing has run, and separate Cancel from the prominent confirmation action.

## Do's and Don'ts

### Do:

- **Do** derive Overview, Updates, and Update All from the same actionable update collection.
- **Do** keep "Nothing runs without confirmation" and the latest check time together near the bottom of Overview.
- **Do** disable package actions when the visible data is a retained snapshot after refresh failure.
- **Do** let Homebrew output stay technical and exact.

### Don't:

- **Don't** bring back installed Cask or Formula browsing in the popover.
- **Don't** redraw, approximate, or replace the approved mug with an SF Symbol or custom SwiftUI geometry.
- **Don't** split Overview into statistic cards, metric columns, or settings-style rows.
- **Don't** let Review All execute immediately.
- **Don't** count pinned, self-updating, disabled, unavailable, or metadata-blocked packages as actionable updates.
