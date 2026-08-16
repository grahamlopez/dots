#!/bin/env bash

notes_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.class == "notesdown") | .workspace .name')

echo "notesdown currently on $notes_workspace"

current_ws=$(hyprctl activeworkspace -j | jq '.id')

if [ -z "$notes_workspace" ]; then

	echo "start"
	hyprctl dispatch -- exec "[float; size 1200 800]" kitty --class notesdown -e nvim ~/framework_minimal_notes.md
  sleep 0.1
  hyprctl dispatch centerwindow
  hyprctl dispatch moveactive "0 -80%"

elif [ "$notes_workspace" == "special:notesdown" ]; then

	echo "show"
	#hyprctl dispatch movetoworkspace "1,class:notesdown"
	hyprctl dispatch movetoworkspace "${current_ws},class:notesdown"

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent "special:notesdown,class:notesdown"

fi
