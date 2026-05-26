#!/bin/sh
set -e

ALIAS_LINE="alias agy-yolo='agy --dangerously-skip-permissions'"

write_alias() {
    target="$1"
    if [ -f "$target" ]; then
        if ! grep -qxF "$ALIAS_LINE" "$target"; then
            printf '\n# Added by google-antigravity devcontainer feature\n%s\n' "$ALIAS_LINE" >> "$target"
        fi
    fi
}

need_command() {
    command -v "$1" >/dev/null 2>&1
}

install_packages() {
    if need_command apt-get; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends "$@"
        rm -rf /var/lib/apt/lists/*
        return
    fi

    if need_command apk; then
        apk add --no-cache "$@"
        return
    fi

    if need_command dnf; then
        dnf install -y "$@"
        return
    fi

    if need_command yum; then
        yum install -y "$@"
        return
    fi

    echo "Unable to install required packages automatically."
    echo "Please ensure 'curl' and 'bash' are available in the image before using this feature."
    exit 1
}

missing_packages=""

if ! need_command curl; then
    missing_packages="$missing_packages curl"
fi

if ! need_command bash; then
    missing_packages="$missing_packages bash"
fi

if [ -n "$missing_packages" ]; then
    # shellcheck disable=SC2086
    install_packages $missing_packages
fi

mkdir -p /usr/local/bin
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- -d /usr/local/bin

write_alias /etc/bash.bashrc
write_alias /etc/zsh/zshrc

mkdir -p /etc/profile.d
profile_file=/etc/profile.d/agy-yolo.sh
if [ ! -f "$profile_file" ] || ! grep -qxF "$ALIAS_LINE" "$profile_file"; then
    printf '%s\n' "$ALIAS_LINE" > "$profile_file"
    chmod 0644 "$profile_file"
fi

echo "google-antigravity installed."
