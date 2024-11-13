#!/bin/bash
#
# This script monitors KDE "activity" changing and changes the default browser
# It's incomplete

host=$(hostname)
output_log_file="/tmp/activity_browser_switcher_${host}.log"

# Plasma 5
#monitor() {
#  dbus-monitor --session \
#    "destination=org.kde.ActivityManager,member=SetCurrentActivity"
#}

# Plasma 6
monitor() {
  dbus-monitor --session \
    "type='signal',interface='org.kde.ActivityManager.Activities',member='CurrentActivityChanged'"

}

# helper function to turn a hash returned from dbus into an activity name
get_activity_name() {
  _dbus_output="$(dbus-send --session --dest=org.kde.ActivityManager \
                            --type=method_call --print-reply \
                            /ActivityManager/Activities \
                            org.kde.ActivityManager.Activities.ActivityName \
                            string:${1})"
  _activity_name=$(echo ${_dbus_output} | cut -d '"' -f 2)
  echo ${_activity_name}
}


keypress_to_lock=false # initial value

# populate the active activity when this script starts logging
initial_activity=$(echo $(dbus-send --session --dest=org.kde.ActivityManager \
                                    --type=method_call --print-reply \
                                    /ActivityManager/Activities \
                                    org.kde.ActivityManager.Activities.CurrentActivity) \
                                    | cut -d '"' -f 2)
current_activity_name=$(get_activity_name ${initial_activity})

printf "$(date +%s), ${current_activity_name}, startup\n" >> ${output_log_file}
printf "$(date +%s), ${current_activity_name}, switch_to\n" >> ${output_log_file}

while read line
do
  echo "got $line"
  echo ""
  case $line in

    *"string"*)
      activity_string=$(echo ${line} | cut -d '"' -f 2)
      current_activity_name=$(get_activity_name ${activity_string})
      printf "$(date +%s), ${current_activity_name}, switch_to\n" >> ${output_log_file}
      if [[ "$current_activity_name" == "gentoo" ]]
      then
        xdg-settings set default-web-browser firefox-bin.desktop
      elif [[ "$current_activity_name" == "nvidia" ]]
      then
        xdg-settings set default-web-browser microsoft-edge.desktop
      else
        printf "bad state: unreachable branch\n"
      fi
      ;;

    #*"member=SetCurrentActivity"*)
    #  read nextline
    #  activity_string=$(echo ${nextline} | cut -d '"' -f 2)
    #  current_activity_name=$(get_activity_name ${activity_string})
    #  printf "$(date +%s), ${current_activity_name}, switch_to\n" >> ${output_log_file}
    #  if [[ "$current_activity_name" == "gentoo" ]]
    #  then
    #    xdg-settings set default-web-browser firefox-bin.desktop
    #  elif [[ "$current_activity_name" == "nvidia" ]]
    #  then
    #    xdg-settings set default-web-browser microsoft-edge.desktop
    #  else
    #    printf "bad state: unreachable branch\n"
    #  fi
    #  ;;

  esac
done < <(monitor)
