#!/bin/sh
set -e

CONFIG_DIR=/etc/localhost-proxy
CONFIG_FILE="$CONFIG_DIR/mappings"
START_SCRIPT=/usr/local/bin/localhost-proxy-start

install_socat() {
    if command -v socat >/dev/null 2>&1; then
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends socat ca-certificates
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache socat ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y socat ca-certificates
        dnf clean all
    elif command -v microdnf >/dev/null 2>&1; then
        microdnf install -y socat ca-certificates
        microdnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y socat ca-certificates
        yum clean all
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm --needed socat ca-certificates
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install socat ca-certificates
        zypper clean --all
    else
        echo "localhost-proxy requires socat, but no supported package manager was found."
        echo "Install socat in the base image or use a Debian, Alpine, Fedora, RHEL, Arch, or openSUSE based image."
        exit 1
    fi
}

install_start_script() {
    cat > "$START_SCRIPT" <<'EOF'
#!/bin/sh
set -e

CONFIG_FILE=${LOCALHOST_PROXY_CONFIG:-/etc/localhost-proxy/mappings}
RUN_DIR=${LOCALHOST_PROXY_RUN_DIR:-/tmp/localhost-proxy}
LOG_DIR=${LOCALHOST_PROXY_LOG_DIR:-/tmp/localhost-proxy}

trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

safe_name() {
    printf '%s' "$1" | sed 's/[^A-Za-z0-9_.-]/_/g'
}

stop_existing() {
    if [ ! -d "$RUN_DIR" ]; then
        return 0
    fi

    for pid_file in "$RUN_DIR"/*.pid; do
        [ -f "$pid_file" ] || continue
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
            kill "$pid" >/dev/null 2>&1 || true
        fi
        rm -f "$pid_file"
    done
}

parse_mapping() {
    mapping=$(trim "$1")
    [ -n "$mapping" ] || return 1

    case "$mapping" in
        \#*) return 1 ;;
    esac

    case "$mapping" in
        *=*)
            source_part=$(trim "${mapping%%=*}")
            target_part=$(trim "${mapping#*=}")
            ;;
        *)
            source_part="$mapping"
            target_part="host.docker.internal:$mapping"
            ;;
    esac

    if [ -z "$source_part" ] || [ -z "$target_part" ]; then
        echo "Invalid localhost-proxy mapping '$mapping': source and target are required." >&2
        return 2
    fi

    case "$source_part" in
        *:*)
            listen_host=${source_part%:*}
            listen_port=${source_part##*:}
            ;;
        *)
            listen_host=127.0.0.1
            listen_port=$source_part
            ;;
    esac

    case "$target_part" in
        *:*)
            target_host=${target_part%:*}
            target_port=${target_part##*:}
            ;;
        *)
            echo "Invalid localhost-proxy mapping '$mapping': target must be HOST:PORT." >&2
            return 2
            ;;
    esac

    case "$listen_port:$target_port" in
        *[!0-9:]* | :* | *:)
            echo "Invalid localhost-proxy mapping '$mapping': ports must be numeric." >&2
            return 2
            ;;
    esac

    if [ -z "$listen_host" ] || [ -z "$target_host" ]; then
        echo "Invalid localhost-proxy mapping '$mapping': hosts cannot be empty." >&2
        return 2
    fi

    return 0
}

start_mapping() {
    mapping="$1"

    if parse_mapping "$mapping"; then
        :
    else
        status=$?
        [ "$status" -eq 1 ] && return 0
        return "$status"
    fi

    name=$(safe_name "$listen_host-$listen_port-to-$target_host-$target_port")
    log_file="$LOG_DIR/$name.log"
    pid_file="$RUN_DIR/$name.pid"

    nohup socat "TCP-LISTEN:$listen_port,bind=$listen_host,fork,reuseaddr" "TCP:$target_host:$target_port" > "$log_file" 2>&1 &
    printf '%s\n' "$!" > "$pid_file"
    echo "localhost-proxy: forwarding $listen_host:$listen_port -> $target_host:$target_port"
}

main() {
    if ! command -v socat >/dev/null 2>&1; then
        echo "localhost-proxy requires socat, but socat is not installed." >&2
        exit 1
    fi

    mkdir -p "$RUN_DIR" "$LOG_DIR"
    stop_existing

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "localhost-proxy: no config file found at $CONFIG_FILE; nothing to start."
        return 0
    fi

    mappings=$(tr ',;' '\n\n' < "$CONFIG_FILE")
    if [ -z "$(trim "$mappings")" ]; then
        echo "localhost-proxy: no mappings configured; nothing to start."
        return 0
    fi

    printf '%s\n' "$mappings" | while IFS= read -r mapping; do
        start_mapping "$mapping"
    done
}

main "$@"
EOF
    chmod 0755 "$START_SCRIPT"
}

mkdir -p "$CONFIG_DIR"
install_socat
install_start_script

printf '%s\n' "${MAPPINGS:-}" > "$CONFIG_FILE"
chmod 0644 "$CONFIG_FILE"

echo "localhost-proxy installed."
if [ -n "${MAPPINGS:-}" ]; then
    echo "Configured mappings:"
    printf '%s\n' "$MAPPINGS"
else
    echo "No mappings configured. Set the 'mappings' option to enable proxies."
fi
