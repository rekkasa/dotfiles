# Created by newuser for 5.9
export PATH="$PATH:$HOME/bin:$HOME/scripts:$HOME/.local/bin:/usr/sbin:/snap/bin/"
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
XDG_DATA_DIRS=/usr/share/:/usr/local/share/:/var/lib/snapd/desktop/

# Created by newuser for 5.8
autoload -U colors && colors
# source "$HOME/.cargo/env"

# Detect if running inside Emacs eshell
if [[ "$TERM" == "dumb" && -n "$INSIDE_EMACS" ]]; then
  STARSHIP_DISABLED=1
fi

# Run Starship only if not in eshell
if [[ -z "$STARSHIP_DISABLED" ]]; then
  eval "$(starship init zsh)"
fi


# History
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE=~/.zsh_history

# Tab completion
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.


#### ALIASES ####

alias l="eza -alh --icons --group-directories-first"
# alias l="ls -lah"
alias f="feh -F"
alias p="qpdfview"
alias rr="open *.Rproj"
alias f="feh -F"
alias rb="R CMD INSTALL --preclean --no-multiarch --with-keep.source"
alias cat="batcat --theme='OneHalfLight'"
alias v="~/Documents/appimages/nvim.appimage"
alias sq="source /home/arekkas/src/qtile/venv/bin/activate && startx"

# ---- Git ----
alias gg="git status --short"
alias ga="git add"
alias gaa="git add ."
alias gcm="git commit -m"
alias gp="git push"
alias gpo="git push origin"
alias guo="git pull origin"
alias gco="git checkout"
alias gl="git log -n 5 --oneline"


alias tt="tmux new-session -s"
alias tat="tmux a -t"

# ---- Projects ----
# alias pp="cd ~/Documents/projects"
# alias fr="cd ~/Documents/Projects/arekkas_HteFramework_XXXX_2021"
# alias sim="cd ~/Documents/Projects/arekkas_HteSimulation_XXXX_2021"
# alias legend="cd ~/Documents/Projects/arekkas_LegendHte_XXXX_2021"
# alias ter="cd ~/Documents/Projects/arekkas_TerVsBis_XXXX_2021"
# alias obs="cd ~/Documents/Projects/HteSimulationObservational_SETUP"
# alias tt="killall teams && teams"

# ---- Django ----
alias da="django-admin"

##### END ALIASES ####

# vi mode
bindkey -v
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char
export KEYTIMEOUT=1

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

source .zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source .zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh 2>/dev/null
