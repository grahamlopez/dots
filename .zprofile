host=$(hostname)
printf '[user]\n    name = graham (@%s)\n    email = m477@duck.com\n' "$host" > ~/.gitconfig-local

if [ "$(tty)" = "/dev/tty1" ]; then
    sleep 1
    start-hyprland
fi
