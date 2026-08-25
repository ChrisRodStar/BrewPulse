# Privacy

BrewPulse Free does not require an account. Homebrew package inventory and command output stay on the Mac unless the user chooses to copy and share them.

BrewPulse can send anonymous usage statistics through TelemetryDeck. Collection is enabled by default and can be turned off in BrewPulse Settings. These statistics measure first-observed installations, app sessions, menu activity, successful activation, Homebrew refresh outcomes, package-action outcomes, app version, macOS version, and Mac architecture.

TelemetryDeck receives an anonymized identifier for the app installation, event names, timestamps rounded by the service, and the system and app metadata listed above. BrewPulse analytics do not include package names, the installed package inventory, Homebrew commands or output, file paths, account details, or user-entered text.

BrewPulse runs Homebrew commands on the Mac. Homebrew may access its own servers and third-party package sources while checking, updating, or uninstalling packages. Homebrew's behavior and data practices are separate from BrewPulse.

BrewPulse contacts GitHub when it checks for app updates and downloads an update you approve. These requests carry ordinary network information such as the IP address and user agent, but they do not include the Homebrew package inventory or command output.

Command output stays on the Mac unless the user copies and shares it. That output can contain package names, local paths, or messages from third-party installers, so review it before posting it publicly.

Launch-at-login status is managed through Apple's `ServiceManagement` framework. BrewPulse does not store credentials or install a privileged helper.

Questions about this policy can be opened through the support path in [SUPPORT.md](SUPPORT.md). Report security issues privately as described in [SECURITY.md](../SECURITY.md).
