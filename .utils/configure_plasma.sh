#!/bin/bash

# to capture settings
# inotifywait -m -r ./config
# kwriteconfig6 --file kxkbrc --group Layout --key Options ctrl:swap_lwin_lctl

function confirm() {
  while true; do
    read -p "Do you want to proceed? ([Y]es/[N]o/[A]bort) " yn
    case $yn in
      [Yy]* ) return 0;;  # Proceed with the operation
      [Nn]* ) return 1;;  # Abort the operation
      [Aa]* ) exit;;      # Abort script
      * ) echo "Please answer Yes, No, or Abort.";;
    esac
  done
}

echo "set up keyboard and keybindings"
if confirm; then
  echo "setting up keyboard/bindings"
  # capslock as control
  kwriteconfig6 --file kxkbrc --group Layout --key Options ctrl:nocaps
  kwriteconfig6 --file kxkbrc --group Layout --type bool --key ResetOldOptions true

  # FIXME the groups take hardware specifics into account
  # set up trackpad FIXME only if a trackpad is present
  # kwriteconfig6 --file kcminputrc --group Libinput --key PointerAcceleration '0.400'
  # kwriteconfig6 --file kcminputrc --group Libinput --key PointerAccelerationProfile '2'
  # kwriteconfig6 --file kcminputrc --group Libinput --type bool --key TapToClick true

  # hjkl for window tiling
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Bottom' 'Meta+Down	Meta+J,Meta+Down,Quick Tile Window to the Bottom'
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Top' 'Meta+Up	Meta+K,Meta+Up,Quick Tile Window to the Top'
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Left' 'Meta+Left	Meta+H,Meta+Left,Quick Tile Window to the Left'
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Quick Tile Right' 'Meta+Right	Meta+L,Meta+Right,Quick Tile Window to the Right'

  # maximize and minimize
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Maximize' 'Meta+PgUp	Meta+M,Meta+PgUp,Maximize Window'
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key 'Window Minimize' 'Meta+PgDn	Meta+N,Meta+PgDn,Minimize Window'

  # ctrl-9 for opening yakuake
  kwriteconfig6 --file kglobalshortcutsrc --group yakuake --key 'toggle-window-state' 'Ctrl+9	F12,F12,Open/Retract Yakuake'

  # ctrl-x for screenlock
  kwriteconfig6 --file kglobalshortcutsrc --group ksmserver --key 'Lock Session' 'Meta+X	Screensaver,Meta+L	Screensaver,Lock Session'
else
  echo "skipping keyboard/bindings"
fi

echo "set up panel"
if confirm; then
  echo "setting up panel"
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group 'Panel 2' --group Defaults --key thickness 32
  # panel to top position
  # qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var panels = panels(); for (var i = 0; i < panels.length; i++) { panels[i].location = "top"; }'
  # TODO panel to top doesn't work
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group 'Panel 2' --key floating 1
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group 'Panel 2' --group Defaults --key position top
  # check out kwriteconfig6 and file 'plasma-org.kde.plasma.desktop-appletsrc' for these
  # need to change location=0 to location=3 for the 2nd and 3rd instances
  # activity pager to the right position
  # desktop pager to the right position
  # battery monitor "command output" widget
  # clipboard widget
else
  echo "skipping panel setup"
fi

echo "set up yakuake"
if confirm; then
  echo "setting up yakuake"
  kwriteconfig6 --file yakuakerc --group Window --type bool --key KeepOpen false
  kwriteconfig6 --file yakuakerc --group Window --type bool --key ShowTabBar false
  # hide title bar (get to menu with ctrl+shift+,
  kwriteconfig6 --file yakuakerc --group Window --type bool --key ShowTitleBar false
  kwriteconfig6 --file yakuakerc --group Window --key Width 60
else
  echo "skipping yakuake setup"
fi

# set up autostart
mkdir -p ${HOME}/.config/autostart

echo "add yakuake to autostart"
if confirm; then
  echo "adding yakuake to autostart"
cat << EOF > ${HOME}/.config/autostart/org.kde.yakuake.desktop
[Desktop Entry]
Categories=Qt;KDE;System;TerminalEmulator;
Comment=A drop-down terminal emulator based on KDE Konsole technology.
DBusActivatable=true
Exec=yakuake
GenericName=Drop-down Terminal
Icon=yakuake
Name=Yakuake
Terminal=false
Type=Application
X-DBUS-ServiceName=org.kde.yakuake
X-DBUS-StartupType=Unique
X-KDE-StartupNotify=false
EOF
else
  echo "not adding yakuake to autostart"
fi

#echo "add syncthing to autostart"
#if confirm; then
#  echo "adding syncthing to autostart"
#cat << EOF > ${HOME}/.config/autostart/syncthing-start.desktop
#i[Desktop Entry]
#Categories=Network;FileTransfer;P2P
#Comment=Starts the main syncthing process in the background.
#Exec=/usr/bin/syncthing serve --no-browser --logfile=default
#GenericName=File synchronization
#Icon=syncthing
#Keywords=synchronization;daemon;
#Name=Start Syncthing
#Terminal=false
#Type=Application
#EOF
#else
#  echo "not adding syncthing to autostart"
#fi
#
#echo "add activity_browswer_switcher.sh to autostart"
#if confirm; then
#  echo "adding activity_browswer_switcher.sh to autostart"
#cat << EOF > ${HOME}/.config/autostart/activity_browser_switcher.sh.desktop
#[Desktop Entry]
#Exec=/home/graham/.utils/activity_browser_switcher.sh
#Icon=
#Name=activity_browser_switcher.sh
#Path=
#Terminal=False
#Type=Application
#EOF
#else
#  echo "not adding activity_browswer_switcher.sh to autostart"
#fi
#
#echo "add kmonad to autostart"
#if confirm; then
#  echo "adding kmonad to autostart"
#cat << EOF > ${HOME}/.config/autostart/kmonad.desktop
#[Desktop Entry]
#Comment=
#Comment=
#Exec=/home/graham/.local/bin/kmonad /home/graham/.config/kmonad_config.kbd
#GenericName=
#GenericName=
#Icon=
#MimeType=
#Name=kmonad
#Name=kmonad
#Path=
#StartupNotify=true
#Terminal=false
#TerminalOptions=
#Type=Application
#X-KDE-SubstituteUID=false
#X-KDE-Username=
#EOF
#else
#  echo "not adding kmonad to autostart"
#fi

# set up konsole
echo "install mgl profile for Konsole"
if confirm; then
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile mgl.profile
  # TODO hiding toolbars doesn't work
  # the changes happen to a binary entry in .local/state/konsolestaterc
  # kwriteconfig6 --file konsolerc --group "KonsoleWindow" --key ShowMenuBarByDefault false
  # kwriteconfig6 --file konsolerc --group "MainWindow" --key MenuBar Disabled
  # kwriteconfig6 --file konsolerc --group "MainWindow" --key StatusBar Disabled
  # TODO test for Hack Nerd Font, install it automatically, or use a sensible alternative
  echo "installing mgl profile"
cat << EOF > ${HOME}/.local/share/konsole/mgl.profile
[Appearance]
ColorScheme=transparent
#Font=Hack Nerd Font,14,-1,5,50,0,0,0,0,0

[General]
Name=mgl
Parent=FALLBACK/

[Scrolling]
ScrollBarPosition=2
EOF
cat << EOF > ${HOME}/.local/share/konsole/transparent.colorscheme
[Background]
Color=0,0,0

[BackgroundFaint]
Color=0,0,0

[BackgroundIntense]
Color=0,0,0

[Color0]
Color=0,0,0

[Color0Faint]
Color=24,24,24

[Color0Intense]
Color=104,104,104

[Color1]
Color=178,24,24

[Color1Faint]
Color=101,0,0

[Color1Intense]
Color=255,84,84

[Color2]
Color=24,178,24

[Color2Faint]
Color=0,101,0

[Color2Intense]
Color=84,255,84

[Color3]
Color=178,104,24

[Color3Faint]
Color=101,74,0

[Color3Intense]
Color=255,255,84

[Color4]
Color=24,24,178

[Color4Faint]
Color=0,0,101

[Color4Intense]
Color=84,84,255

[Color5]
Color=178,24,178

[Color5Faint]
Color=95,5,95

[Color5Intense]
Color=255,84,255

[Color6]
Color=24,178,178

[Color6Faint]
Color=24,178,178

[Color6Intense]
Color=84,255,255

[Color7]
Color=178,178,178

[Color7Faint]
Color=101,101,101

[Color7Intense]
Color=255,255,255

[Foreground]
Color=255,255,255

[ForegroundFaint]
Color=255,255,255

[ForegroundIntense]
Color=255,255,255

[General]
Anchor=0.5,0.5
Blur=false
ColorRandomization=false
Description=transparent
FillStyle=Tile
Opacity=0.8
Wallpaper=
WallpaperFlipType=NoFlip
WallpaperOpacity=1
EOF
else
  echo "not installing mgl profile"
fi


# FIXME set up automatic nightcolor based on location
# kwriteconfig6 --file kwinrc --group NightColor --type bool --key Active true
# kwriteconfig6 --file kwinrc --group NightColor --key LatitudeFixed '38.47'
# kwriteconfig6 --file kwinrc --group NightColor --key LongitudeFixed '-83.91'
# kwriteconfig6 --file kwinrc --group NightColor --key Mode Location

# set up activities
# create gentoo and nvidia activities
# set wallpapers for each activity
#   gentoo: ~/Pictures/wallpapers/tech
#   nvidia: ~/Pictures/wallpapers/nvidia
# set up default browser switcher
#   add .utils/activity_browser_switcher.sh to startup apps
# set up different default favorites
#   gentoo: firefox, konsole
#   nvidia: edge, konsole
# pin to taskmanager
#   gentoo: settings, firefox, konsole
#   nvidia: slack, edge, logseq
