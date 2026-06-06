# Cloudflare Tunnel Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that installs `cloudflared` and starts a Cloudflare Tunnel when the dev container starts.

The startup command uses the HTTP/2 protocol:

```sh
cloudflared tunnel --protocol http2 run --token <token>
```

## Usage

Add the feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/cloudflare-tunnel:1": {
      "token": "${localEnv:CLOUDFLARE_TUNNEL_TOKEN}"
    }
  }
}
```

Then set the token on the host before rebuilding the dev container:

```sh
export CLOUDFLARE_TUNNEL_TOKEN='eyJhIjxxx'
```

Using `${localEnv:CLOUDFLARE_TUNNEL_TOKEN}` avoids committing the tunnel token directly to the repository.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `token` | string | `""` | Cloudflare Tunnel token used by `cloudflared tunnel --protocol http2 run --token ...`. |

## Runtime Behavior

The feature installs `cloudflared` from Cloudflare's package repository on Debian/Ubuntu and Red Hat compatible images.

It also installs:

```text
/usr/local/bin/cloudflare-tunnel-start
```

The feature uses `postStartCommand` to run `cloudflare-tunnel-start` every time the dev container starts. The script stops any previously managed `cloudflared` process before starting a new one, so repeated starts do not duplicate tunnel processes.

When available, the script launches `cloudflared` with `setsid` so the tunnel process is detached from the lifecycle command's process group. If `setsid` is not available, it falls back to `nohup`.

Logs and PID files are written under:

```text
/tmp/cloudflare-tunnel
```

## Token Handling

The feature option is available during feature installation, but `postStartCommand` runs later. To make the token available at startup, the installer writes it to:

```text
/etc/cloudflare-tunnel/token
```

When the Dev Container runtime exposes the remote user during installation, the token file is owned by that user and set to mode `0600`. If the remote user cannot be identified, the file is made readable by container users so the lifecycle command can still start the tunnel.

At runtime, `CLOUDFLARE_TUNNEL_TOKEN` overrides the token file. This is useful if you prefer injecting the token through the container environment.

The feature does not print the token during installation or startup. The `cloudflared` process is started with `--token`, so users with permission to inspect process arguments inside the container may be able to see the token.

## Supported Images

This feature supports images with one of these package managers:

- `apt-get`
- `dnf`
- `microdnf`
- `yum`

Other images can still use the startup script if `cloudflared` is installed by the base image before this feature runs.
