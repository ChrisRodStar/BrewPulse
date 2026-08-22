# BrewPulse Project Rules

These instructions apply to the entire repository. More specific `AGENTS.md`
files may add instructions for their own directories.

## Product Direction

- Treat `README.md` and `TODO.md` as this public repository's product and
  implementation sources of truth.
- Workspace-level notes outside this repository are planning context. Promote
  an approved decision into this repository before relying on it for public
  implementation or contributor guidance.
- Preserve BrewPulse's core principles: native, simple, transparent, safe, and
  lightweight.
- Complete and validate the free workflow before building accounts, payments,
  or Pro-only automation.
- Never install, remove, or update a user's software without an explicit user
  action and a clear description of what will run.

## How We Work

- Work on one coherent task at a time. Do not silently implement several TODO
  items or a whole milestone in one pass.
- Before changing code, explain the next small task, why it is next, and any
  meaningful tradeoff.
- During longer work, provide short progress updates. After each task, summarize
  what changed, how it was verified, and what the next sensible task is.
- Pause for user review at meaningful product, architecture, or UX decisions.
- Use the relevant project skill whenever one applies, and follow its
  instructions before acting.
- Keep `TODO.md` accurate as work is completed or requirements change.

## Architecture and File Layout

- Prefer small, focused files with one clear responsibility. Do not accumulate
  unrelated views, models, services, and parsing logic in one file.
- Organize code by feature or domain, using descriptive folders and names.
- Keep UI views focused on presentation and user interaction. Put business
  rules, command construction, parsing, persistence, and external integrations
  in dedicated types and layers.
- Depend on protocols at system boundaries so Homebrew commands and other side
  effects remain independently testable.
- Reuse existing components and abstractions when they fit, but do not add
  speculative layers that have no current use.
- Add tests beside the corresponding target and mirror the production feature
  structure where practical.
- Keep Commercial, Web, and Cloud implementation in their own repositories and
  follow each repository's instructions when working there.

## Verification

- Add or update focused tests with behavior changes, including failure and edge
  cases when relevant.
- Run the narrowest useful checks while iterating, then run the complete checks
  appropriate to the changed area before declaring the task complete.
- For macOS changes, verify tests and a build with the Xcode version pinned by
  `.github/workflows/macos-ci.yml` when it is available locally.
- Do not hide, discard, or rewrite Homebrew's original output in user-facing
  execution and troubleshooting flows.
- Never describe a change as complete when required checks are failing or have
  not been run; state the exact limitation instead.

## Git and Pull Requests

- Documentation-only and other clearly non-code documentation changes may be
  committed and pushed directly to `main` without creating a pull request.
  This fast path includes Markdown documentation, files under `docs/`,
  `AGENTS.md` instruction files, `TODO.md`, and repository legal/community text
  such as `LICENSE`, `NOTICE`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`,
  `CODE_OF_CONDUCT.md`, and `CHANGELOG.md`.
- A direct-to-`main` documentation push must contain only documentation-safe
  files. If the same change also touches application/source code, tests,
  scripts, GitHub Actions/workflows, build or Xcode project files, dependency
  manifests/lockfiles, runtime configuration, or other executable/behavioral
  configuration, use the normal feature-branch and pull-request workflow for
  the entire change.
- The versioned `.githooks/pre-push` safeguard through
  `core.hooksPath=.githooks` must enforce this distinction: allow docs-only
  pushes to `main`, but block mixed or code/configuration pushes to `main`.
- For changes that require a pull request, make changes on a `codex/` feature
  branch and keep commits scoped to one coherent piece of work.
- Create a concise Conventional Commit at a meaningful, verified checkpoint.
  Do not combine unrelated work merely to reduce the number of commits.
- Explain when a code/configuration checkpoint is substantial enough for a pull
  request. Do not merge a pull request without explicit user approval.
- Before merging a pull request that affects code, tests, scripts, build files,
  workflows, dependencies, or runtime behavior, confirm that `macOS Validation`
  passed for the pull request's current head commit. A pass from an older
  revision does not count.
- Until hosted branch protection is enabled for `main`, treat the local hook
  and these rules as mandatory. Do not bypass the safeguard for
  code/configuration changes merely to save time.
