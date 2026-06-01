# Localhost Proxy Feature

A [Dev Container Feature](https://containers.dev/implementors/features/) that starts `socat` TCP proxies inside the dev container, so tools can keep connecting to `localhost` while the actual service runs on the host or another reachable target.

This is useful when local configuration points to `localhost:<port>`, but inside a dev container the host service is reachable as `host.docker.internal:<port>`.

## Usage

Add the feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/localhost-proxy:1": {
      "mappings": "5432, 6379"
    }
  }
}
```

This starts these proxies after the container starts:

```text
127.0.0.1:5432 -> host.docker.internal:5432
127.0.0.1:6379 -> host.docker.internal:6379
```

Then applications inside the dev container can keep using `localhost:5432` and `localhost:6379`.

## Mapping Syntax

The `mappings` option is a comma- or newline-separated string.

Use a bare port as the common shortcut:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/localhost-proxy:1": {
      "mappings": "5432"
    }
  }
}
```

This means:

```text
127.0.0.1:5432 -> host.docker.internal:5432
```

Use `SOURCE=TARGET` for explicit mappings:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/localhost-proxy:1": {
      "mappings": "5432=host.docker.internal:15432, 9200=search.internal:9200"
    }
  }
}
```

`SOURCE` can be either a port or `HOST:PORT`:

```jsonc
{
  "features": {
    "ghcr.io/zjx20/devcontainer-features/localhost-proxy:1": {
      "mappings": "127.0.0.1:5432=host.docker.internal:5432, 0.0.0.0:8080=host.docker.internal:3000"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `mappings` | string | `""` | Comma- or newline-separated mappings. Use `PORT` as shorthand for `PORT=host.docker.internal:PORT`, or `SOURCE=TARGET` where `SOURCE` is `PORT` or `HOST:PORT` and `TARGET` is `HOST:PORT`. |

## Runtime Behavior

The feature installs `socat` and writes the configured mappings to:

```text
/etc/localhost-proxy/mappings
```

It also installs:

```text
/usr/local/bin/localhost-proxy-start
```

The feature uses `postStartCommand` to run `localhost-proxy-start` every time the dev container starts. The script stops previously managed proxy processes before starting the configured mappings again, so repeated starts do not duplicate listeners.

When available, the script launches `socat` with `setsid` so the proxy process is detached from the lifecycle command's process group. This makes it less likely that the dev container lifecycle runner cleans up the proxy immediately after `postStartCommand` exits.

Logs and PID files are written under:

```text
/tmp/localhost-proxy
```

## Notes

- Binding privileged ports below `1024` may require the command to run as root.
- If a source port is already in use inside the container, that proxy will fail to start. Check `/tmp/localhost-proxy/*.log` for details.
- `host.docker.internal` is provided by Docker Desktop and many modern dev container environments. If your environment does not provide it, use an explicit reachable target host in the mapping.
