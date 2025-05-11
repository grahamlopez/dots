#!/bin/env bash

DROP_WORKSPACE=$(hyprctl clients -j | jq -rec '.[] | select(.class == "dropdown") | .workspace .name')

echo "dropdown currently on $DROP_WORKSPACE"

if [ -z "$DROP_WORKSPACE" ]; then

	echo "start"
	hyprctl dispatch -- exec "[float; size 1200 800; move 526 50]" kitty --class dropdown

elif [ "$DROP_WORKSPACE" == "special:dropdown" ]; then

	echo "show"
	hyprctl dispatch movetoworkspace "1,class:dropdown"

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent "special:dropdown,class:dropdown"

fi
