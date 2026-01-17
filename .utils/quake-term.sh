#!/bin/env bash

drop_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.class == "dropdown") | .workspace .name')

echo "dropdown currently on $drop_workspace"

current_ws=$(hyprctl activeworkspace -j | jq '.id')

if [ -z "$drop_workspace" ]; then

	echo "start"
	hyprctl dispatch -- exec "[float; size 1200 600]" kitty --class dropdown
  sleep 0.1
  hyprctl dispatch centerwindow
  hyprctl dispatch moveactive "0 -80%"

elif [ "$drop_workspace" == "special:dropdown" ]; then

	echo "show"
	#hyprctl dispatch movetoworkspace "1,class:dropdown"
	hyprctl dispatch movetoworkspace "${current_ws},class:dropdown"

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent "special:dropdown,class:dropdown"

fi
