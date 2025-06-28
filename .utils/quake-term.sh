#!/bin/env bash

drop_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.class == "dropdown") | .workspace .name')

echo "dropdown currently on $drop_workspace"

current_ws=$(hyprctl activeworkspace -j | jq '.id')

if [ -z "$drop_workspace" ]; then

	echo "start"
  # FIXME: would be nice if this automatically handled differently-sized screens
	hyprctl dispatch -- exec "[float; size 1200 800; move 526 50]" kitty --class dropdown

elif [ "$drop_workspace" == "special:dropdown" ]; then

	echo "show"
	#hyprctl dispatch movetoworkspace "1,class:dropdown"
	hyprctl dispatch movetoworkspace "${current_ws},class:dropdown"

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent "special:dropdown,class:dropdown"

fi
