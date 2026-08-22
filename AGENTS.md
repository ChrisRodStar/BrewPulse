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

- Maintainer-owned work may go directly to `main` when the user explicitly
  authorizes the push. Do not create a pull request by default for routine
  documentation, release administration, or a coherent change the maintainer
  has already reviewed in this workspace.
- Use a feature branch and pull request for outside contributions, changes that
  need a separate review checkpoint, or when the user explicitly requests one.
  Batch related work into one reviewable pull request instead of opening a pull
  request for each TODO item.
- The versioned `.githooks/pre-push` safeguard through
  `core.hooksPath=.githooks` must check direct pushes to `main`. It runs a diff
  check for documentation-only pushes and the full local validation for all
  other changes.
- For changes that need a pull request, use a `codex/` feature branch and keep
  commits scoped to one coherent piece of work.
- Create a concise Conventional Commit at a meaningful, verified checkpoint.
  Do not combine unrelated work merely to reduce the number of commits.
- Explain when a code/configuration checkpoint is substantial enough for a pull
  request. Do not merge a pull request without explicit user approval.
- Before merging a pull request that affects code, tests, scripts, build files,
  workflows, dependencies, or runtime behavior, confirm that `macOS Validation`
  passed for the pull request's current head commit. A pass from an older
  revision does not count. For a direct maintainer push, the local hook must
  pass before GitHub runs the same validation on `main`.
- Keep force-push and branch-deletion protection enabled for `main`. Hosted
  rules should let the maintainer bypass the pull-request requirement while
  preserving it for other contributors.
