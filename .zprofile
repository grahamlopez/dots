# Only on tty1: start ssh-agent and Hyprland
if [[ "$(tty)" = "/dev/tty1" ]]; then
  start-hyprland
fi
