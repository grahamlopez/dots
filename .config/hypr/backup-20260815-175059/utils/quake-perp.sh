#!/bin/env bash

perp_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.class == "perpdown") | .workspace .name')
current_ws=$(hyprctl activeworkspace -j | jq '.id')

if [ -z "$perp_workspace" ]; then
  echo "start"

  # firefox-bin, with Wayland class set via --name
  hyprctl dispatch exec "[float; size 1400 1300] firefox-bin --no-remote -P perpdown --name perpdown --new-window 'https://perplexity.ai'"

  # wait for the window to show
  sleep 0.5

  perp_addr=$(hyprctl clients -j | jq -rec '.[] | select(.class == "perpdown") | .address')
  [ -z "$perp_addr" ] && exit 0

  # center horizontally, move near top
  hyprctl dispatch centerwindow
  hyprctl dispatch moveactive "0 -50%"

elif [ "$perp_workspace" = "special:perpdown" ]; then
  echo "show"
  perp_addr=$(hyprctl clients -j | jq -rec '.[] | select(.class == "perpdown") | .address')
  hyprctl dispatch movetoworkspace "${current_ws},address:${perp_addr}"
else
  echo "hide"
  perp_addr=$(hyprctl clients -j | jq -rec '.[] | select(.class == "perpdown") | .address')
  hyprctl dispatch movetoworkspacesilent "special:perpdown,address:${perp_addr}"
fi
