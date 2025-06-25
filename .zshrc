##############################################################
#
# orig .zshrc
#
#################################################################

#################################################################
# general options                                             {{{
#################################################################

# load some custom completions
fpath=(~/.zsh/completion ~/.zsh/completion/conda-zsh-completion $fpath)
# this is as directed in 20.2.1 of zsh manual
autoload -Uz compinit
compinit -i

# turn off all terminal beeps
unsetopt BEEP

export HISTSIZE=10000
export SAVEHIST=$HISTSIZE
export HISTFILE="$HOME/.zsh.history"
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
#setopt BANG_HIST                 # Treat the '!' character specially during expansion.
#setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
#setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
#setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
#setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
#setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
#setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
#setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
#setopt HIST_BEEP                 # Beep when accessing nonexistent history.

export SHELL=$(which zsh)
export EDITOR=vim
export VISUAL=vim
export LESS='-ifqm'         # set up the parameters for 'less'
export PAGER='less'     # use less for stuff (such as man)
#export PAGER='less -RM'

umask 077
limit coredumpsize 0        # Turn off core dumps

# report time for long-running commands (based on system+user time)
# can also notify with some hackery: https://superuser.com/a/578651
export REPORTTIME=5

#################################################################
# }}}
#################################################################




#################################################################
# specific environments                                       {{{
#################################################################

# start a keychain if available
[ $(command -v keychain) ] && eval "$(keychain --nogui --quiet --eval --agents ssh id_ed25519)"

# disable gnome/kde-ssh keyring nonsense on remote servers
[ -n "$SSH_CONNECTION" ] && unset SSH_ASKPASS

# use modulefiles if available
moduleinit=${HOME}/local/apps/modules-4.7.1/init/zsh
if [[ -f "$moduleinit" ]]; then
  source $moduleinit
  module use ~/local/modulefiles
fi
if [[ "$(hostname)" = "fi-kermit" ]] ; then
  module use /opt/nvidia/hpc_sdk/modulefiles/nvhpc
  export PATH="/home/glopez/local/bin:${PATH}"
fi

if [[ "$(hostname)" = "NV-7STSW14" ]] ; then
  export PATH="/home/graham/local/apps/nvim-linux-x86_64/bin:${PATH}"
fi

#################################################################
# }}}
#################################################################




#################################################################
# keybindings, aliases, functions, abbreviations              {{{
#################################################################

# display existing key bindings with `bindkey`

# reset to emacs style
bindkey -e

# this is to get bash-style word treatment: most importantly, kill-word only
# goes to the directory delimeter, instead of killing the entire path
autoload -U select-word-style
select-word-style bash

bindkey '^D' kill-word
bindkey '^B' backward-word
bindkey '^F' forward-word

# for quick alternate command
# - can also use ^U (cut) ^Y (paste) as well
bindkey '^K' push-line
bindkey '^R' history-incremental-search-backward
bindkey '^Y' yank
bindkey '^U' kill-whole-line

# setting defaults
alias ls="ls --color=auto -F"
alias grep="grep --color=auto"
alias less="less -RM"
alias tmux="tmux -2"
[ $(command -v nvim) ] && alias vim="nvim"

# shortcuts
alias fric='vim ${HOME}/Sync/notes/valence_computing/fric.md'
alias nvpn='nmcli connection up nvidia\ beaverton'
alias gpg-kill-agent='gpgconf --kill gpg-agent'
alias ssh-kill-agent='pkill ssh-agent'
alias dgit='git --git-dir=$HOME/.dots-git/ --work-tree=$HOME' # dotfile management
function agent-ssh() {
  eval "$(ssh-agent -s)"
  ssh-add ${HOME}/.ssh/id_ed25519
}

function dark_theme() {
  # change for plasma desktop - covers almost everything
  plasma-apply-lookandfeel -a org.kde.breezedark.desktop

  # change for all running konsole instances
  for instance in $(qdbus6 | grep org.kde.konsole); do
    for session in $(qdbus6 "$instance" | grep -E '^/Sessions/'); do
      qdbus6 "$instance" "$session" org.kde.konsole.Session.setProfile "Dark"
    done
  done
  # change default for new konsole instances
  sed -i "s/^DefaultProfile=.*/DefaultProfile=Dark.profile/g" "$HOME/.config/konsolerc"
}

function light_theme() {
  # change for plasma desktop - covers almost everything
  plasma-apply-lookandfeel -a org.kde.breeze.desktop

  # change for all running konsole instances
  for instance in $(qdbus6 | grep org.kde.konsole); do
    for session in $(qdbus6 "$instance" | grep -E '^/Sessions/'); do
      qdbus6 "$instance" "$session" org.kde.konsole.Session.setProfile "Light"
    done
  done
  # change default for new konsole instances
  sed -i "s/^DefaultProfile=.*/DefaultProfile=Light.profile/g" "$HOME/.config/konsolerc"
}



function uninstall_nvim() {
  if [ -z "$1" ]; then
    echo "uninstalling main nvim state"
    rm -rf ${HOME}/.local/share/nvim
    rm -rf ${HOME}/.local/state/nvim
    rm -rf ${HOME}/.cache/nvim
  else
    echo "uninstalling nvim.$1 state"
    rm -rf ${HOME}/.local/share/nvim.$1
    rm -rf ${HOME}/.local/state/nvim.$1
    rm -rf ${HOME}/.cache/nvim.$1
  fi
}
function reinstall_lazyvim() {
  uninstall_nvim "lazyvim"
  rm -rf ${HOME}/.config/nvim.lazyvim
  mkdir -p ${HOME}/.config/nvim.lazyvim
  /usr/bin/git clone https://github.com/LazyVim/starter ${HOME}/.config/nvim.lazyvim
}
function reinstall_kickstart() {
  uninstall_nvim "kickstart"
  rm -rf ${HOME}/.config/nvim.kickstart
  mkdir -p ${HOME}/.config/nvim.kickstart
  /usr/bin/git clone https://github.com/nvim-lua/kickstart.nvim.git ${HOME}/.config/nvim.kickstart
}


# check git repos under current directory
# needs some work and cleanup
showAllReposWithChanges() {
  for n in `find -name .git`
    do (
      cd ${n/%.git/}
      if [ "$(/usr/bin/git status --porcelain)" ]
        then echo $PWD
      fi
    )
    done
}

# messing with neovim
alias lazyvim="NVIM_APPNAME=nvim.lazyvim nvim"
alias ovim="NVIM_APPNAME=nvim.old nvim"
alias pvim="NVIM_APPNAME=nvim.perp nvim"

# more homegrown functions

# for config file management
function git() {
  if [[ $(pwd) == ${HOME} || $(pwd) == ${HOME}/.config/nvim ]] ; then
    command git --git-dir=$HOME/.dots-git/ --work-tree=$HOME "$@"
  else
    command git "$@"
  fi
}

# python and conda related stuff
function conda_zsh_init() {
  eval "$(/home/graham/local/apps/miniconda3/bin/conda shell.zsh hook)"
}

# for docker cleanup
function dcleanup() {
    docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
    docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}

# pandoc markdown to nice pdf
function mdtopdf {
    name=$1:r
    ext=$1:e
    echo "${name}.${ext} --> ${name}.pdf"
    pandoc -V geometry:margin=1.5in --output=${name}.pdf ${name}.${ext}
}

# djvu to pdf
function djvutopdf {
    name=$1:r
    ext=$1:e
    echo "${name}.${ext} --> ${name}.pdf"
    ddjvu -format=pdf -mode=black ${name}.djvu ${name}.pdf
}

# abbreviations and magic expansion
# obtained from stackoverflow (but the link now redirects incorrectly)

setopt extendedglob
typeset -Ag abbreviations
abbreviations=(
  "lxe"   "lxc exec __CURSOR__ -- sudo --login --user ubuntu"
  "lxg"   "lxc exec __CURSOR__ -- su --login graham"
  "no"    "~/Sync/notes/__CURSOR__"
)

magic-abbrev-expand() {
    local MATCH
    LBUFFER=${LBUFFER%%(#m)[_a-zA-Z0-9]#}
    command=${abbreviations[$MATCH]}
    LBUFFER+=${command:-$MATCH}

    if [[ "${command}" =~ "__CURSOR__" ]]
    then
        RBUFFER=${LBUFFER[(ws:__CURSOR__:)2]}
        LBUFFER=${LBUFFER[(ws:__CURSOR__:)1]}
    else
        zle self-insert
    fi
}

no-magic-abbrev-expand() {
  LBUFFER+=' '
}

zle -N magic-abbrev-expand
zle -N no-magic-abbrev-expand
bindkey " " magic-abbrev-expand
bindkey "^x " no-magic-abbrev-expand
bindkey -M isearch " " self-insert

#################################################################
# }}}
#################################################################




#################################################################
# Appearance and prompt                                       {{{
#################################################################
#
eval `/usr/bin/dircolors ~/.dir_colors`

# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Color shortcuts
  RED='%{[0;31m%}'
  LIGHTRED='%{[1;31m%}'

  GREEN='%{[0;32m%}'
  LIGHTGREEN='%{[1;32m%}'

  YELLOW='%{[0;33m%}'
  LIGHTYELLOW='%{[1;33m%}'

  BLUE='%{[0;34m%}'
  LIGHTBLUE='%{[1;34m%}'

  PURPLE='%{[0;35m%}'
  LIGHTPURPLE='%{[1;35m%}'

  CYAN='%{[0;36m%}'
  LIGHTCYAN='%{[1;36m%}'

  GRAY='%{[1;30m%}'
  LIGHTGRAY='%{[0;37m%}'

  WHITE='%{[0;37m%}'
  LIGHTWHITE='%{[1;37m%}'

  NOCOLOR='%{[0m%}'

  ARED='[0;31m'
  ANOCOLOR='[0;0m'
  AGREEN='[0;32m'
  ABLUE='[0;34m'
  ACYAN='[0;36'
  APURPLE='[0;35m'

# for git repo information
source ~/.zsh/git-prompt.sh
setopt prompt_subst

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=true

PROMPT='$GREEN%m$CYAN:$CYAN%3~$YELLOW$(__git_ps1 "(%s)")$CYAN-| $NOCOLOR'
# PROMPT='$RED%m$CYAN:$CYAN%3~$YELLOW$(__git_ps1 "(%s)")$CYAN-| $NOCOLOR' # root

RPROMPT='$RED%(?..[%?]) $CYAN|$WHITE%*$NOCOLOR'

export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export GROFF_NO_SGR=1                  # for konsole and gnome-terminal

export MANPAGER='less -s -M +Gg'

#################################################################
# }}}
#################################################################
# useful in root shells
# function boot {
#     efibootmgr -n $1
#     reboot
# }
