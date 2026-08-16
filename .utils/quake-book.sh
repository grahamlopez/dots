#!/bin/env bash
# Dropdown bookmarks buffer (CTRL + 8). Geometry lives in the window rules for
# class "booksdown" in ~/.config/hypr/hyprland.lua.

source "$(dirname "$(readlink -f "$0")")/hypr-lib.sh"

hypr_dropdown booksdown \
    kitty --class booksdown -e /home/graham/local/bin/nvim "$HOME/Synct/notes/bookmarks.md"
