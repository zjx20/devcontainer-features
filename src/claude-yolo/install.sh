#!/bin/sh
set -e

ALIAS_LINE="alias claude-yolo='claude --dangerously-skip-permissions'"

write_alias() {
    target="$1"
    if [ -f "$target" ]; then
        if ! grep -qxF "$ALIAS_LINE" "$target"; then
            printf '\n# Added by claude-yolo devcontainer feature\n%s\n' "$ALIAS_LINE" >> "$target"
        fi
    fi
}

write_alias /etc/bash.bashrc
write_alias /etc/zsh/zshrc

mkdir -p /etc/profile.d
profile_file=/etc/profile.d/claude-yolo.sh
if [ ! -f "$profile_file" ] || ! grep -qxF "$ALIAS_LINE" "$profile_file"; then
    printf '%s\n' "$ALIAS_LINE" > "$profile_file"
    chmod 0644 "$profile_file"
fi

echo "claude-yolo alias installed."
