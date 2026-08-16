#!/bin/env bash
# Dropdown terminal (CTRL + 9). Geometry lives in the window rules for
# class "dropdown" in ~/.config/hypr/hyprland.lua.

source "$(dirname "$(readlink -f "$0")")/hypr-lib.sh"

hypr_dropdown dropdown kitty --class dropdown
