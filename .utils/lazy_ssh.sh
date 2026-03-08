#!/bin/sh

SOCK="${HOME}/.ssh/agent.sock"

# If we already have a usable agent with keys, reuse it
if [ -S "$SOCK" ]; then
    SSH_AUTH_SOCK="$SOCK" ssh-add -l >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        export SSH_AUTH_SOCK="$SOCK"
        exec ssh "$@"
    fi
fi

# If a stale socket exists (no live agent), remove it
if [ -S "$SOCK" ]; then
    rm -f "$SOCK"
fi

# Start a new agent bound to the fixed socket, silencing its output
mkdir -p "${HOME}/.ssh"
eval "$(ssh-agent -a "$SOCK" -s 2>/dev/null)" >/dev/null 2>&1 || exit 1
export SSH_AUTH_SOCK="$SOCK"

# Add your key; stderr is fine, but keep stdout clean
ssh-add "${HOME}/.ssh/id_ed25519" </dev/tty >/dev/null 2>&1 || exit 1

# Now run the real ssh
exec ssh "$@"
