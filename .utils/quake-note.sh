#!/bin/env bash
# Dropdown notes buffer. Geometry lives in the window rules for class
# "notesdown" in ~/.config/hypr/hyprland.lua.

source "$(dirname "$(readlink -f "$0")")/hypr-lib.sh"

hypr_dropdown notesdown kitty --class notesdown -e nvim "$HOME/framework_minimal_notes.md"
