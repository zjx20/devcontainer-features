#!/bin/sh
set -e

CONFIG_DIR=/etc/cloudflare-tunnel
TOKEN_FILE="$CONFIG_DIR/token"
START_SCRIPT=/usr/local/bin/cloudflare-tunnel-start

need_command() {
    command -v "$1" >/dev/null 2>&1
}

install_cloudflared_debian() {
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl

    mkdir -p /usr/share/keyrings
    chmod 0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg > /usr/share/keyrings/cloudflare-public-v2.gpg
    chmod 0644 /usr/share/keyrings/cloudflare-public-v2.gpg

    printf '%s\n' 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' > /etc/apt/sources.list.d/cloudflared.list

    apt-get update
    apt-get install -y --no-install-recommends cloudflared
    rm -rf /var/lib/apt/lists/*
}

install_cloudflared_rpm() {
    manager="$1"

    mkdir -p /etc/yum.repos.d

    case "$manager" in
        dnf)
            dnf install -y ca-certificates curl
            curl -fsSL https://pkg.cloudflare.com/cloudflared.repo > /etc/yum.repos.d/cloudflared.repo
            dnf makecache -y
            dnf install -y cloudflared
            dnf clean all
            ;;
        microdnf)
            microdnf install -y ca-certificates curl
            curl -fsSL https://pkg.cloudflare.com/cloudflared.repo > /etc/yum.repos.d/cloudflared.repo
            microdnf makecache
            microdnf install -y cloudflared
            microdnf clean all
            ;;
        yum)
            yum install -y ca-certificates curl
            curl -fsSL https://pkg.cloudflare.com/cloudflared.repo > /etc/yum.repos.d/cloudflared.repo
            yum makecache -y
            yum install -y cloudflared
            yum clean all
            ;;
    esac
}

install_cloudflared() {
    if need_command cloudflared; then
        echo "cloudflared is already installed."
        return 0
    fi

    if need_command apt-get; then
        install_cloudflared_debian
        return 0
    fi

    if need_command dnf; then
        install_cloudflared_rpm dnf
        return 0
    fi

    if need_command microdnf; then
        install_cloudflared_rpm microdnf
        return 0
    fi

    if need_command yum; then
        install_cloudflared_rpm yum
        return 0
    fi

    echo "cloudflare-tunnel requires a Debian/Ubuntu or Red Hat compatible package manager."
    echo "Install cloudflared in the base image or use an image with apt-get, dnf, microdnf, or yum."
    exit 1
}

find_token_owner() {
    token_owner=""

    if [ -n "${_REMOTE_USER:-}" ] && id "$_REMOTE_USER" >/dev/null 2>&1; then
        token_owner="$_REMOTE_USER"
        return 0
    fi

    if [ -n "${_CONTAINER_USER:-}" ] && id "$_CONTAINER_USER" >/dev/null 2>&1; then
        token_owner="$_CONTAINER_USER"
        return 0
    fi

    if [ -n "${REMOTE_USER:-}" ] && id "$REMOTE_USER" >/dev/null 2>&1; then
        token_owner="$REMOTE_USER"
        return 0
    fi

    return 1
}

install_token_file() {
    mkdir -p "$CONFIG_DIR"
    chmod 0755 "$CONFIG_DIR"

    umask 077
    printf '%s\n' "${TOKEN:-}" > "$TOKEN_FILE"
    chmod 0600 "$TOKEN_FILE"

    if find_token_owner; then
        chown "$token_owner" "$TOKEN_FILE" 2>/dev/null || true
    else
        chmod 0644 "$TOKEN_FILE"
        echo "cloudflare-tunnel: unable to identify the remote user; token file is readable by container users."
    fi
}

install_start_script() {
    mkdir -p /usr/local/bin
    cat > "$START_SCRIPT" <<'EOF_START'
#!/bin/sh
set -e

CONFIG_DIR=${CLOUDFLARE_TUNNEL_CONFIG_DIR:-/etc/cloudflare-tunnel}
TOKEN_FILE=${CLOUDFLARE_TUNNEL_TOKEN_FILE:-$CONFIG_DIR/token}
RUN_DIR=${CLOUDFLARE_TUNNEL_RUN_DIR:-/tmp/cloudflare-tunnel}
LOG_DIR=${CLOUDFLARE_TUNNEL_LOG_DIR:-/tmp/cloudflare-tunnel}
PID_FILE="$RUN_DIR/cloudflared.pid"
LOG_FILE="$LOG_DIR/cloudflared.log"

token=""

read_token() {
    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        token="$CLOUDFLARE_TUNNEL_TOKEN"
        return 0
    fi

    if [ -f "$TOKEN_FILE" ]; then
        if [ ! -r "$TOKEN_FILE" ]; then
            echo "cloudflare-tunnel: token file exists but is not readable: $TOKEN_FILE" >&2
            return 1
        fi

        IFS= read -r token < "$TOKEN_FILE" || token=""
        return 0
    fi

    token=""
    return 0
}

stop_existing() {
    if [ ! -f "$PID_FILE" ]; then
        return 0
    fi

    pid=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
        kill "$pid" >/dev/null 2>&1 || true
        sleep 1
        if kill -0 "$pid" >/dev/null 2>&1; then
            kill -TERM "$pid" >/dev/null 2>&1 || true
        fi
    fi

    rm -f "$PID_FILE"
}

launch_cloudflared() {
    : > "$LOG_FILE"

    if command -v setsid >/dev/null 2>&1; then
        launcher=setsid
        setsid cloudflared tunnel --protocol http2 run --token "$token" >> "$LOG_FILE" 2>&1 < /dev/null &
    else
        launcher=nohup
        nohup cloudflared tunnel --protocol http2 run --token "$token" >> "$LOG_FILE" 2>&1 < /dev/null &
    fi

    pid=$!
    printf '%s\n' "$pid" > "$PID_FILE"
    echo "cloudflare-tunnel: launcher=$launcher pid=$pid protocol=http2" >> "$LOG_FILE"

    sleep 2
    if ! kill -0 "$pid" >/dev/null 2>&1; then
        echo "cloudflare-tunnel: cloudflared exited shortly after launch." >&2
        echo "cloudflare-tunnel: see $LOG_FILE for details." >&2
        return 1
    fi

    echo "cloudflare-tunnel: started cloudflared with protocol=http2; logs: $LOG_FILE"
}

main() {
    if ! command -v cloudflared >/dev/null 2>&1; then
        echo "cloudflare-tunnel requires cloudflared, but cloudflared is not installed." >&2
        exit 1
    fi

    mkdir -p "$RUN_DIR" "$LOG_DIR"
    stop_existing
    read_token

    if [ -z "$token" ]; then
        echo "cloudflare-tunnel: no token configured; set the 'token' feature option or CLOUDFLARE_TUNNEL_TOKEN." >&2
        exit 1
    fi

    launch_cloudflared
}

main "$@"
EOF_START
    chmod 0755 "$START_SCRIPT"
}

install_cloudflared
install_token_file
install_start_script

echo "cloudflare-tunnel installed."
if [ -n "${TOKEN:-}" ]; then
    echo "Cloudflare Tunnel token configured."
else
    echo "No Cloudflare Tunnel token configured. Set the 'token' option or CLOUDFLARE_TUNNEL_TOKEN before starting."
fi
