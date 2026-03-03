#!/bin/env bash

hyprctl dispatch -- exec "[float; size 1200 600]" kitty --class clipdown sh -c '/home/graham/.utils/quake-clip-picker.sh'
sleep 0.2
hyprctl dispatch centerwindow
hyprctl dispatch moveactive "0 -80%"
