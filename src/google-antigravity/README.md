# Google Antigravity CLI Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that installs the Google Antigravity CLI with the official installer and adds a shell alias:

```sh
alias agy-yolo='agy --dangerously-skip-permissions'
```

The CLI is installed with:

```sh
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- -d /usr/local/bin
```

Installing to `/usr/local/bin` makes `agy` available to all users in the container instead of only the user that ran the installer.

## Dependency Handling

The installer requires both `curl` and `bash`.

This feature checks for those commands first. If either one is missing, it attempts to install the dependency automatically by using one of the common package managers available in the container image:

- `apt-get`
- `apk`
- `dnf`
- `yum`

If the base image does not provide any of those package managers, the feature exits with a clear error and asks for `curl` and `bash` to be present ahead of time.

## Usage

Add the feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/google-antigravity:1": {}
  }
}
```

Then inside the container:

```sh
agy-yolo
```

This is equivalent to:

```sh
agy --dangerously-skip-permissions
```

## Shared State

If you want to share Google Antigravity state from the host, do not mount directly to a user-specific home path because the container username may vary.

Instead, mount the host directory to a fixed location and create a symlink into the active user's home directory from a Dev Container lifecycle command:

```jsonc
{
  "mounts": [
    "source=${localEnv:HOME}/.gemini/,target=/gemini-home/,type=bind"
  ],
  "postStartCommand": "ln -snf /gemini-home \"$HOME/.gemini\""
}
```

This keeps the mount target stable while still making `~/.gemini` available to whichever user starts the container.

## Options

This feature has no options.
