#!/bin/env bash

perp_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.tags[] == "perp") | .workspace .name')

# convert the tag to a window address
perp_address=$(hyprctl clients -j | jq -rec '.[] | select(.tags[] == "perp" ) | .address')

echo "perp currently on $perp_workspace"

current_ws=$(hyprctl activeworkspace -j | jq '.id')

echo "current workspace is ${current_ws}"

if [ -z "$perp_workspace" ]; then

	echo "start"

  # open a new firefox window with perplexity
	hyprctl dispatch -- exec "firefox-bin --new-window 'ext+container:name=Personal&url=https://perplexity.ai'"

  sleep 0.2

  # Create and move window to special workspace
  hyprctl dispatch movetoworkspace special:perp

  # tag the window for later tracking
  hyprctl dispatch tagwindow +perp

  # convert the tag to a window address
  perp_address=$(hyprctl clients -j | jq -rec '.[] | select(.tags[] == "perp" ) | .address')

  # bring the window to our current workspace and float
	hyprctl dispatch movetoworkspace ${current_ws}, address:${perp_address}
	hyprctl dispatch setfloating address:${perp_address}
	hyprctl dispatch resizewindowpixel exact 1400 1300,address:${perp_address}
	hyprctl dispatch movewindowpixel exact 750 150,address:${perp_address}

elif [ "$perp_workspace" == "special:perp" ]; then

	echo "show"
	#hyprctl dispatch movetoworkspace "1,class:perp"
	hyprctl dispatch movetoworkspace ${current_ws}, address:${perp_address}

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent special:perp, address:${perp_address}

fi
