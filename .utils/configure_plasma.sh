#!/bin/bash

# to capture settings
# inotifywait -m -r ./config
# kwriteconfig5 --file kxkbrc --group Layout --key Options ctrl:swap_lwin_lctl

# set up keyboard and keybindings
# capslock as control
kwriteconfig5 --file kxkbrc --group Layout --key Options ctrl:nocaps
kwriteconfig5 --file kxkbrc --group Layout --type bool --key ResetOldOptions true

# set up trackpad
kwriteconfig5 --file kcminputrc --group Libinput --key PointerAcceleration '0.400'
kwriteconfig5 --file kcminputrc --group Libinput --key PointerAccelerationProfile '2'
kwriteconfig5 --file kcminputrc --group Libinput --type bool --key TapToClick true

# hjkl for window tiling
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Bottom' 'Meta+Down	Meta+J,Meta+Down,Quick Tile Window to the Bottom'
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Top' 'Meta+Up	Meta+K,Meta+Up,Quick Tile Window to the Top'
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Left' 'Meta+Left	Meta+H,Meta+Left,Quick Tile Window to the Left'
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Right' 'Meta+Right	Meta+L,Meta+Right,Quick Tile Window to the Right'

# maximize and minimize
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Maximize' 'Meta+PgUp	Meta+M,Meta+PgUp,Maximize Window'
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key 'Window Minimize' 'Meta+PgDn	Meta+N,Meta+PgDn,Minimize Window'

# ctrl-9 for opening yakuake
kwriteconfig5 --file kglobalshortcutsrc --group yakuake --key 'toggle-window-state' 'Ctrl+9	F12,F12,Open/Retract Yakuake'

# ctrl-x for screenlock
kwriteconfig5 --file kglobalshortcutsrc --group ksmserver --key 'Lock Session' 'Meta+X	Screensaver,Meta+L	Screensaver,Lock Session'

# set up panel
kwriteconfig5 --file plasmashellrc --group PlasmaViews --group 'Panel 2' --group Defaults --key thickness 32
# panel to top position
# activity pager to the right position
# desktop pager to the right position
# battery monitor "command output" widget
# clipboard widget


# FIXME set up automatic nightcolor based on location
# kwriteconfig5 --file kwinrc --group NightColor --type bool --key Active true
# kwriteconfig5 --file kwinrc --group NightColor --key LatitudeFixed '38.47'
# kwriteconfig5 --file kwinrc --group NightColor --key LongitudeFixed '-83.91'
# kwriteconfig5 --file kwinrc --group NightColor --key Mode Location


# set up activities
# create gentoo and nvidia activities
# set wallpapers for each activity
#   gentoo: ~/Pictures/wallpapers/tech
#   nvidia: ~/Pictures/wallpapers/nvidia
# set up default browser switcher
# set up different default favorites
#   gentoo: firefox, konsole
#   nvidia: edge, konsole
# ping to taskmanager
#   gentoo: settings, firefox, konsole
#   nvidia: slack, edge, logseq

# set up konsole

# set up yakuake
# remove tab bar
# close when window loses focus
# 60% width

# set up autostart
# yakuake
# syncthing
