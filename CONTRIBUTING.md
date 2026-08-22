# Contributing to BrewPulse

Thanks for your interest in improving BrewPulse.

BrewPulse is building a native, transparent, and safe macOS experience around Homebrew. Contributions to the open-source core are welcome when they preserve those principles.

## Before You Start

Please review:

- [`README.md`](README.md) for the project overview.
- [`TODO.md`](TODO.md) for the current roadmap and implementation status.
- [`AGENTS.md`](AGENTS.md) for repository-specific development and contribution rules.

For substantial product, architecture, or UX changes, open an issue or discussion before investing significant implementation work so the direction can be aligned first.

## Development Principles

Changes should keep BrewPulse:

- **Native** — prefer macOS-native Swift and SwiftUI experiences.
- **Simple** — avoid unnecessary configuration and complexity.
- **Transparent** — show what Homebrew will do and preserve its original output.
- **Safe** — never change installed software without clear user intent.
- **Lightweight** — avoid unnecessary background work and resource use.

## Pull Requests

Outside contributions should use a feature branch and pull request. The maintainer may use the repository's direct-push path after the same checks pass locally.

Keep pull requests focused on one coherent change. Include tests for behavior changes where practical, and describe what you verified.

Documentation-only changes may follow the lighter workflow described in [`AGENTS.md`](AGENTS.md).

## Testing

Before requesting review, run the narrowest useful tests while iterating and the complete checks appropriate to the changed area.

For macOS changes, the current GitHub workflow validates:

- the Xcode project,
- the test suite,
- a Release build,
- and the static analyzer.

A code pull request should not be considered ready to merge until the current revision passes the required validation. Maintainer pushes to `main` run the same validation locally before the push and again on GitHub after the push.

Run the complete validation locally with:

```text
./scripts/validate.sh
```

To build from the command line without an Apple Developer account or the maintainer's signing identity:

```text
./scripts/build-local.sh
```

Pass `Release` as the first argument to build the Release configuration. The app is left unsigned and is intended for local development only.

The script uses the Xcode selected for command-line tools. If Xcode is installed somewhere other than the standard path, set `DEVELOPER_DIR` for the command, such as `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer ./scripts/build-local.sh`.

## Security Issues

Do not disclose suspected security vulnerabilities in a public issue.

Please follow [`SECURITY.md`](SECURITY.md) for security reporting guidance.

## Licensing Contributions

By submitting a contribution to this repository, you agree that your contribution may be distributed under the repository's Mozilla Public License 2.0 terms.

This repository may adopt an additional contributor-signoff or contributor agreement process in the future. Any such process will be documented before it becomes required.
