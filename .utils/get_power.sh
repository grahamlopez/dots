#!/bin/bash

if [ -e "/sys/class/power_supply/BAT0" ]; then
  BAT=0
elif [ -e "/sys/class/power_supply/BAT1" ]; then
  BAT=1
else
  echo "/sys/... battery not found"
  exit 1
fi

get_power()
{
    local power_uW
    local voltage_uV
    local current_uA

    if [ -f "/sys/class/power_supply/BAT0/power_now" ]; then
        power_uW=$(cat /sys/class/power_supply/BAT0/power_now)
    else
        voltage_uV=$(cat /sys/class/power_supply/BAT${BAT}/voltage_now)
        current_uA=$(cat /sys/class/power_supply/BAT${BAT}/current_now)
        power_uW=$(echo "scale=2; $current_uA * $voltage_uV / 1000000.0" | bc)
    fi

    echo "scale=2; $power_uW / 1000000.0" | bc
}

get_power
