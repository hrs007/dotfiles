alias python="python3"

# Vim-style command-line editing.
bindkey -v
bindkey -v '^?' backward-delete-char

# Completion: ignore case, show matches in a menu, and select with arrow keys.
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zmodload zsh/complist

# Prompt: current directory, Git branch (when available), then command input.
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt prompt_subst
PROMPT='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '

# Ask before overwriting files or removing them with rm.
alias rm='rm -i'
alias mv='mv -i'


