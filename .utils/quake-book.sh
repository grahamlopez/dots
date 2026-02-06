#!/bin/env bash

books_workspace=$(hyprctl clients -j | jq -rec '.[] | select(.class == "booksdown") | .workspace .name')

echo "booksdown currently on $books_workspace"

current_ws=$(hyprctl activeworkspace -j | jq '.id')

if [ -z "$books_workspace" ]; then

	echo "start"
	hyprctl dispatch -- exec "[float; size 1200 800]" kitty --class booksdown -e /home/graham/local/bin/nvim ~/Synct/notes/bookmarks.md
  sleep 0.1
  hyprctl dispatch centerwindow
  hyprctl dispatch moveactive "0 -80%"

elif [ "$books_workspace" == "special:booksdown" ]; then

	echo "show"
	#hyprctl dispatch movetoworkspace "1,class:booksdown"
	hyprctl dispatch movetoworkspace "${current_ws},class:booksdown"

else

	echo "hide"
	hyprctl dispatch movetoworkspacesilent "special:booksdown,class:booksdown"

fi
