#!/bin/bash

tmux new-session -d -s 0 'sudo su -'   # First window runs your command, then stays open
tmux new-window -d -t 0:1              # Second window with default shell
