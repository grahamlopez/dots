#!/bin/env bash
# Clipboard history picker (CTRL + 0). One-shot: it exits once you choose, so it
# has no special workspace of its own -- it just opens on the current one.
# Geometry lives in the window rules for class "clipdown" in
# ~/.config/hypr/hyprland.lua.

source "$(dirname "$(readlink -f "$0")")/hypr-lib.sh"

hypr_exec kitty --class clipdown sh -c /home/graham/.utils/quake-clip-picker.sh
