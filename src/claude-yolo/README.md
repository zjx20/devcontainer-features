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

## Options

This feature has no options.
