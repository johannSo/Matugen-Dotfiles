#source ~/.zsh/roundy/roundy.zsh
eval "$(starship init zsh)"
# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# My Config
## Aliases
alias wall=".config/hypr/scripts/wallSelect.sh"
alias ls="ls --color"
alias vim="nvim"
alias c="clear"
alias nv="nvim"
alias pls="sudo"
alias ls="eza --icons=always"
alias ll="eza -al --icons=always"
alias la="eza -a --icons=always"
alias upd="sudo dnf update && sudo dnf upgrade"
alias apt="dnf"
alias wifi="nmtui"
alias ble="/home/satoshi/.cargo/bin/bluetui"
alias pipes="pipes.sh"

## Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# Path:
export PATH=$PATH:/home/satoshi/bin
export PATH=$PATH:/home/satoshi/.cargo/bin
. "/home/satoshi/.deno/env"
[ -s "/home/satoshi/.bun/_bun" ] && source "/home/satoshi/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/home/satoshi/.bun/bin:$PATH"
export PATH="/home/satoshi/.spicetify:$PATH"
export PATH=$PATH:/home/satoshi/.spicetify
export PATH=$HOME/.local/bin:$PATH
