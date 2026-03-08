# Only on tty1: start ssh-agent and Hyprland
if [[ "$(tty)" = "/dev/tty1" ]]; then
  # Start agent if not already running
  if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)"   # sets SSH_AUTH_SOCK and SSH_AGENT_PID
  fi

  # Load key once per boot
  # if [[ -n $SSH_AUTH_SOCK && ! -f ~/.ssh/.agent-loaded ]]; then
  #   ssh-add ~/.ssh/id_ed25519 && touch ~/.ssh/.agent-loaded
  # fi

  start-hyprland
fi
