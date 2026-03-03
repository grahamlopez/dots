#!/usr/bin/env bash

# always kill the quake term as its positioning gets confused
quake_pid = $(ps -eaf | grep 'class dropdown' | grep -v grep | awk '{print $2}')
kill ${quake_pid}

# Check if external monitor is connected
if [[ "$(hyprctl monitors)" =~ DP-[0-9][0-9]* ]]; then
  # Handle lid events when external monitor is present
  if [[ $1 == "open" ]]; then                             # monitor connected, lid open
    hyprctl keyword monitor "eDP-1, preferred, auto-down, 1"
  else                                                    # monitor connected, lid closed
    hyprctl keyword monitor "eDP-1, disable"
  fi
else # monitor is not connected
  # Get current lid state
  lid_state=$(grep -oE 'open|closed' /proc/acpi/button/lid/LID0/state)
  if [[ "$lid_state" == "closed" ]]; then                 # no monitor, lid closed
    systemctl suspend
  else                                                    # no monitor, lid open
    hyprctl keyword monitor "eDP-1, preferred, 0x0, 1"
  fi
fi
