# homebrew
[ -d /opt/homebrew ] && eval $(/opt/homebrew/bin/brew shellenv)
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

# completions
autoload -U compinit
compinit

# rust
source $HOME/.cargo/env

# orbstack
source $HOME/.orbstack/shell/init.zsh

# bun
[ -s "/Users/nitsky/.bun/_bun" ] && source "/Users/nitsky/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# llvm
export PATH="$PATH:$HOMEBREW_PREFIX/opt/llvm/bin"

# docker
source <(docker completion zsh)

# prompt
autoload -U colors && colors
PROMPT="%{$fg[green]%}%B%n@%m%{$reset_color%}:%{$fg[blue]%}%4~%{$reset_color%}
%{$fg[red]%}%B›%{$reset_color%} "

# history
HISTSIZE=1000000
SAVEHIST=1000000
setopt inc_append_history
setopt share_history
setopt extended_history

# misc
export EDITOR="hx"
export LESS="-R"
export LESSHISTFILE=/dev/null
export PGUSER=postgres

# fzf
export FZF_DEFAULT_OPTS="--reverse --exit-0 --select-1 --preview=bat --color=16,fg+:blue,pointer:blue"
export FZF_DEFAULT_COMMAND="fd --type f --no-ignore"
source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
 
# gpg
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# aliases
alias code='open -a "Visual Studio Code"'
alias d='trash'
alias e='hx'
alias f='lf'
alias g='rg'
alias j='just'
alias l='lazygit'
alias p='bat'
alias rc='$EDITOR ~/.zshrc'
alias src='source ~/.zshrc'
alias t='fd'
alias tree='eza -T'
alias u='cd ..'

function weather() {
	curl -sSL http://wttr.in/$(echo "$@" | tr " " +)
}

# enable vi mode
bindkey -v

# set the cursor
print -n -- "\e[5 q"

# do not wait after hitting escape
KEYTIMEOUT=0

# use the system clipboard
function copy {
	zle vi-yank
	echo "$CUTBUFFER" | pbcopy
}
zle -N copy
bindkey -M vicmd 'y' copy
function paste_before {
	CUTBUFFER=$(pbpaste)
	zle vi-put-before
}
zle -N paste_before
bindkey -M vicmd 'P' paste_before
function paste_after {
	CUTBUFFER=$(pbpaste)
	zle vi-put-after
}
zle -N paste_after
bindkey -M vicmd 'p' paste_after

# set cursor based on keymap
function zle-line-init {
	print -n -- "\e[5 q"
}
function zle-keymap-select {
	case $KEYMAP in
		main) print -n -- "\e[5 q";;
		vicmd) print -n -- "\e[0 q";;
	esac
}
function zle-line-finish {
	print -n -- "\e[0 q"
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# set highlight colors
zle_highlight=(region:bg=#05428f;paste:bg=none)

# enable binding of ^s
stty -ixon

# g followed by s or l to move to the beginning and end of a line.
bindkey -M vicmd 'g s' beginning-of-line
bindkey -M vicmd 'g l' end-of-line

# fix space issue with tab completion
ZLE_REMOVE_SUFFIX_CHARS=""

# ctrl f to clear screen
bindkey ^f clear-screen
bindkey -M vicmd ^f clear-screen

# ctrl e to edit command
autoload edit-command-line
zle -N edit-command-line
bindkey ^e edit-command-line
bindkey -M vicmd ^e edit-command-line

# ctrl o to cd
function cd_widget () {
	echo
	cd $(lf -print-last-dir)
	echo
	zle reset-prompt
}
zle -N cd_widget
bindkey ^o cd_widget
bindkey -M vicmd ^o cd_widget

# ctrl s to list files
function list_widget() {
	echo
	pwd && eza --long --header --all --group-directories-first
	echo
	zle reset-prompt
}
zle -N list_widget
bindkey ^s list_widget
bindkey -M vicmd ^s list_widget

# ctrl g to show git status
function git_widget() {
	echo
	git status --short --branch
	echo
	zle reset-prompt
}
zle -N git_widget
bindkey ^g git_widget
bindkey -M vicmd ^g git_widget

# ctrl w or ctrl q to exit
function exit_widget() {
	exit
}
zle -N exit_widget
bindkey ^w exit_widget
bindkey ^q exit_widget
bindkey -M vicmd ^w exit_widget
bindkey -M vicmd ^q exit_widget
