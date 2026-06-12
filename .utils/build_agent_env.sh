#!/bin/bash

# print a message to get user confirmation that ssh keys are installed
# TODO:

# install dotfiles from github
git clone --bare git@github.com:grahamlopez/dots $HOME/.dots-git
cd $HOME
git --git-dir=$HOME/.dots-git/ --work-tree=$HOME checkout
git clone git@github.com:grahamlopez/pi-agent $HOME/.pi

# install latest released tmux from github
cd $HOME/local/scratch
wget https://github.com/tmux/tmux/releases/download/3.6b/tmux-3.6b.tar.gz
# TODO: build and install to $HOME/local/apps/tmux with symlink at $HOME/local/bin/tmux

# install latest released nvim from github
# TODO: build in local scratch and install similarly to tmux above

# install fresh and up to date npm
sh -lc 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash'
bash -c "source /home/ubuntu/.nvm/nvm.sh && nvm install node"

# ------- AI / agent tooling installs -------
# Claude Code CLI (example: adjust if you use a different package name)
sh -lc 'curl -fsSL https://claude.ai/install.sh | bash'

# Codex CLI
sh -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'

# Cursor agent CLI (placeholder name; replace with actual package / install method)
sh -lc 'curl https://cursor.com/install -fsS | bash'

# pi.dev CLI (placeholder; replace with actual install)
bash -c "source /home/ubuntu/.nvm/nvm.sh && npm install -g @mariozechner/pi-coding-agent"

# other useful stuff
bash -c "source /home/ubuntu/.nvm/nvm.sh && npm install vite"
# TODO: install ripgrep and fd
