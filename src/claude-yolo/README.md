# Claude YOLO Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that injects a single shell alias into the container:

```sh
alias claude-yolo='claude --dangerously-skip-permissions'
```

The alias is written to `/etc/bash.bashrc`, `/etc/zsh/zshrc`, and `/etc/profile.d/claude-yolo.sh`, so it works in both `bash` and `zsh`, including login shells.

> Note: This feature only installs the alias. It does not install the `claude` CLI itself.

## Usage

Add the feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/claude-yolo:1": {}
  }
}
```

Then inside the container:

```sh
claude-yolo
```

This is equivalent to:

```sh
claude --dangerously-skip-permissions
```

## Setup Tips

`claude-yolo` only installs the alias. A practical setup is to use Anthropic's official feature to install Claude Code, and add the official Node feature first when the base image does not already include a working Node.js environment:

```jsonc
{
  "features": {
    "ghcr.io/devcontainers/features/node:2": {},
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {},
    "ghcr.io/zjx20/devcontainer-features/claude-yolo:1": {}
  }
}
```

## Shared State

If you want to share Claude state from the host, mount both `~/.claude` and `~/.claude.json` to fixed container paths.

`~/.claude.json` is required if you want to reuse the host login state, but the container username may vary, so do not mount it directly to a user-specific home path.

Use fixed mount targets, point `CLAUDE_CONFIG_DIR` at the mounted directory, and create a symlink for `~/.claude.json` from a Dev Container lifecycle command:

```jsonc
{
  "mounts": [
    "source=${localEnv:HOME}/.claude,target=/claude-config,type=bind",
    "source=${localEnv:HOME}/.claude.json,target=/claude-config.json,type=bind"
  ],
  "containerEnv": {
    "CLAUDE_CONFIG_DIR": "/claude-config"
  },
  "postStartCommand": "ln -snf /claude-config.json \"$HOME/.claude.json\""
}
```

## Options

This feature has no options.
