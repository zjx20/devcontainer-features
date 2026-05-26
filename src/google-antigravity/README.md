# Google Antigravity CLI Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that installs the Google Antigravity CLI with the official installer:

```sh
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

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

## State Sharing

This feature currently only installs the CLI. Host-to-container state sharing is not documented yet and can be added later once the CLI's state layout is confirmed.

## Options

This feature has no options.
