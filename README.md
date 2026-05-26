# Dev Container Features

This repository is a collection of reusable [Dev Container Features](https://containers.dev/implementors/features/) used across multiple projects. Features in `src/` are published to GitHub Container Registry by GitHub Actions so other repositories can consume them through `devcontainer.json`.

## Features

| Feature | Purpose | Docs |
| --- | --- | --- |
| `claude-yolo` | Adds a `claude-yolo` shell alias that runs `claude --dangerously-skip-permissions`. | [src/claude-yolo/README.md](src/claude-yolo/README.md) |
| `codex-yolo` | Installs the Codex CLI and adds a `codex-yolo` shell alias for bypass mode. | [src/codex-yolo/README.md](src/codex-yolo/README.md) |
| `google-antigravity` | Installs the Google Antigravity CLI and adds an `agy-yolo` alias. | [src/google-antigravity/README.md](src/google-antigravity/README.md) |

## Repository Layout

- `src/`: all publishable features
- `src/<feature-id>/README.md`: feature-specific usage and options
- `.github/workflows/release.yml`: publishes all features under `src/`

## Publishing

Pushes to `main` can publish features with [`devcontainers/action`](https://github.com/devcontainers/action). Published feature references follow the standard GHCR pattern:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/<feature-id>:<major>": {}
  }
}
```
