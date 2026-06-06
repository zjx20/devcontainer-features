# Repository Guidelines

This repository stores reusable Dev Container Features that are published to GitHub Container Registry through GitHub Actions.

## Scope

- Keep each feature self-contained under `src/<feature-id>/`.
- Treat the repository root `README.md` as an index only.
- Put feature-specific usage, options, caveats, and examples in `src/<feature-id>/README.md`.

## Structure

- `src/<feature-id>/devcontainer-feature.json`: Feature metadata.
- `src/<feature-id>/install.sh`: Installation logic executed by the feature.
- `src/<feature-id>/README.md`: Human-facing documentation for that feature.
- `.github/workflows/release.yml`: Publishing workflow for all features in `src/`.

## Authoring Rules

- Write code comments and documentation in English.
- Prefer small, composable features with a single clear responsibility.
- Keep shell scripts POSIX `sh` unless a stronger shell requirement is necessary.
- Make feature installs idempotent so reruns do not duplicate configuration.
- For long-running processes started from lifecycle commands such as `postStartCommand`, prefer launching them with `setsid` and fall back to `nohup` when `setsid` is unavailable. This helps detach the background process from the lifecycle command's process group.
- Avoid bundling tools that are better provided by a base image or a separate feature unless the feature's purpose is installation itself.

## Release Expectations

- Publishing is handled centrally by GitHub Actions with `devcontainers/action`.
- Bump the `version` in a feature's `devcontainer-feature.json` when releasing changes to that feature.
- If a feature has a substantive change, bump its `version` in `devcontainer-feature.json` as part of the same update.
- Preserve stable feature IDs once published, because downstream `devcontainer.json` files depend on them.
