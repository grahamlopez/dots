#!/usr/bin/env bash
set -euo pipefail

if selection="$(cliphist list | fzf --no-sort)"; then
  printf '%s\n' "$selection" | cliphist decode | wl-copy
fi

# Ask kitty to close this window
kitty @ close-window --self

exit 0
