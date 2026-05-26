#!/bin/sh
set -e

ALIAS_LINE="alias codex-yolo='codex --dangerously-bypass-approvals-and-sandbox'"

write_alias() {
    target="$1"
    if [ -f "$target" ]; then
        if ! grep -qxF "$ALIAS_LINE" "$target"; then
            printf '\n# Added by codex-yolo devcontainer feature\n%s\n' "$ALIAS_LINE" >> "$target"
        fi
    fi
}

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "codex-yolo requires a Node.js environment with npm available."
    echo "Add the Node feature before this one in your devcontainer configuration:"
    echo '"ghcr.io/devcontainers/features/node:2": {}'
    exit 1
fi

npm install -g @openai/codex

write_alias /etc/bash.bashrc
write_alias /etc/zsh/zshrc

mkdir -p /etc/profile.d
profile_file=/etc/profile.d/codex-yolo.sh
if [ ! -f "$profile_file" ] || ! grep -qxF "$ALIAS_LINE" "$profile_file"; then
    printf '%s\n' "$ALIAS_LINE" > "$profile_file"
    chmod 0644 "$profile_file"
fi

echo "codex-yolo installed."
