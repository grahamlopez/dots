#!/bin/env bash
# Dropdown Perplexity window (CTRL + 7). Geometry lives in the window rules for
# class "perpdown" in ~/.config/hypr/hyprland.lua.
#
# firefox-bin, with the Wayland app id set via --name so the rules can match it.

source "$(dirname "$(readlink -f "$0")")/hypr-lib.sh"

hypr_dropdown perpdown \
    firefox-bin --no-remote -P perpdown --name perpdown --new-window 'https://perplexity.ai'
