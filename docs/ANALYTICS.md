# Product analytics

BrewPulse measures the acquisition, activation, engagement, retention, and reliability signals needed to understand whether the product is growing and delivering value. The app uses TelemetryDeck for anonymous macOS analytics. The website uses Vercel Web Analytics and Speed Insights, while GitHub provides release-asset download counts.

Analytics are enabled by default in configured release builds. A user can turn app analytics off under **Settings → Privacy → Share anonymous usage statistics**. Local and unconfigured source builds do not send TelemetryDeck events because they do not contain a TelemetryDeck app identifier.

## Investor metrics

| Metric | Definition | Source |
| --- | --- | --- |
| Website reach | Unique visitors to the public website | Vercel Web Analytics |
| Download intent | Clicks that open a specific Apple Silicon or Intel installer | Vercel custom event `Installer Download Started` |
| Release downloads | Downloads of architecture-specific DMG assets | GitHub Releases API |
| First-observed installations | Unique anonymous installations that first run an instrumented build | `BrewPulse.Installation.firstObserved` |
| Activated installations | Unique installations that complete a successful Homebrew refresh | `BrewPulse.Activation.completed` |
| Weekly/monthly active installations | Unique installations with a session, menu open, or refresh in 7/30 days | TelemetryDeck sessions and engagement events |
| 7-day/30-day retention | Activated installations observed again after 7/30 days | TelemetryDeck cohorts |
| Core-action conversion | Unique installations confirming a package action compared with successful completions | `BrewPulse.PackageOperation.confirmed` and `.completed` |
| Refresh reliability | Successful refreshes divided by completed refresh attempts | `BrewPulse.HomebrewRefresh.completed` |
| Package-action reliability | Successful package actions divided by completed package actions | `BrewPulse.PackageOperation.completed` |
| Version adoption | Active installations grouped by BrewPulse version | TelemetryDeck automatic app metadata |

These numbers represent anonymous app installations, not verified individual people. Reinstalling the app, clearing its local data, or using BrewPulse on multiple Macs can create more than one installation identifier. Existing users first appear when they run an instrumented release.

## App event contract

| Event | Parameters | Purpose |
| --- | --- | --- |
| `BrewPulse.Installation.firstObserved` | Automatic app/system metadata | Establish the first-observed installation cohort |
| `BrewPulse.App.launched` | Automatic app/system metadata | Measure launches and returning installations |
| `BrewPulse.Activation.completed` | Automatic app/system metadata | Mark the first successful Homebrew refresh |
| `BrewPulse.Engagement.menuOpened` | Automatic app/system metadata | Measure meaningful menu-bar engagement |
| `BrewPulse.HomebrewRefresh.completed` | `trigger`, `outcome`, optional `failure_kind` | Measure engagement and refresh reliability |
| `BrewPulse.PackageOperation.confirmed` | `operation_kind`, `scope`, optional `package_kind` | Measure intent to perform a core action |
| `BrewPulse.PackageOperation.completed` | Confirmation parameters plus `outcome` | Measure delivered value and reliability |

Allowed parameter values are fixed categories defined in source. Never add package names, package counts, commands, command output, file paths, raw errors, or arbitrary user-provided text to an analytics event.

## Website event contract

`Installer Download Started` records the selected architecture, BrewPulse version, and whether the architecture was detected or manually selected. `Latest Release Opened` records fallback visits to GitHub when the website cannot resolve a direct installer.

## Release configuration

The public TelemetryDeck application identifier is checked into the BrewPulse target as the `BREWPULSE_TELEMETRY_APP_ID` Xcode build setting. It is substituted into `BrewPulseTelemetryAppID` in the processed app `Info.plist`, and the release script verifies the packaged value. An explicit environment value can override it for diagnostic builds. If the setting is absent, the analytics client remains disabled.
