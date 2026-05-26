# Codex YOLO Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that installs the Codex CLI and injects a shell alias into the container:

```sh
alias codex-yolo='codex --dangerously-bypass-approvals-and-sandbox'
```

The alias is written to `/etc/bash.bashrc`, `/etc/zsh/zshrc`, and `/etc/profile.d/codex-yolo.sh`, so it works in both `bash` and `zsh`, including login shells.

## Requirements

This feature installs the CLI with:

```sh
npm install -g @openai/codex
```

That means the container must already have a working Node.js environment with `npm` available. If it does not, add the official Node feature before this one:

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {},
    "ghcr.io/zjx20/devcontainer-features/codex-yolo:1": {}
  }
}
```

## Usage

Add the feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {},
    "ghcr.io/zjx20/devcontainer-features/codex-yolo:1": {}
  }
}
```

Then inside the container:

```sh
codex-yolo
```

This is equivalent to:

```sh
codex --dangerously-bypass-approvals-and-sandbox
```

## Recommended Mount

If you want to share Codex authentication state and memories between the host and the container, prefer binding it to a fixed container path and pointing `CODEX_HOME` there:

```jsonc
{
  "mounts": [
    "source=${localEnv:HOME}/.codex/,target=/codex-home/,type=bind"
  ],
  "containerEnv": {
    "CODEX_HOME": "/codex-home",
    "CODEX_SQLITE_HOME": "/tmp/codex-sqlite"
  }
}
```

This avoids hard-coding a specific container username such as `node`.

If you prefer mounting into the user's home directory instead, use the actual username inside the container in the target path.

Set `CODEX_SQLITE_HOME` to a container-local path such as `/tmp/codex-sqlite` to avoid SQLite file conflicts when the host and container are active at the same time.

## Options

This feature has no options.
