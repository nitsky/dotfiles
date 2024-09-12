# homebrew
[ -d /opt/homebrew ] && eval $(/opt/homebrew/bin/brew shellenv)
fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)

# aliases
alias b='bun'
alias bx='bunx'
alias c='bat'
alias code='open -a "Visual Studio Code"'
alias d='trash'
alias dotfiles='git --git-dir ~/.dotfiles --work-tree ~/ -c core.fsmonitor=false'
alias e='hx'
alias f='fd'
alias g='git'
alias h='xh'
alias erc='e ~/.zshrc'
alias src='source ~/.zshrc'
alias tree='eza -T'
alias u='cd ..'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# fly
autoload -U compinit; compinit
flyctl completion zsh > "${fpath[1]}/_flyctl"
compdef _flyctl fly

# fzf
export FZF_DEFAULT_OPTS="--reverse --exit-0 --select-1 --preview=bat --color=16,fg+:blue,pointer:blue"
export FZF_DEFAULT_COMMAND="fd --type f --no-ignore"

# gpg
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
if ! pgrep -q gpg-agent; then
	gpgconf --launch gpg-agent
fi

# helix
export HELIX_RUNTIME="$HOME/helix/runtime"
export PATH="$HOME/helix/target/release:$PATH"

# history
HISTSIZE=1000000
SAVEHIST=1000000
setopt incappendhistory
setopt sharehistory
setopt noextendedhistory

# llvm
export PATH="$PATH:$HOMEBREW_PREFIX/opt/llvm/bin"

# misc
export EDITOR="hx"
export LESS="-R"
export LESSHISTFILE=/dev/null

# orbstack
source $HOME/.orbstack/shell/init.zsh

# prompt
autoload -U colors && colors
PROMPT="%{$fg[green]%}%B%n@%m%{$reset_color%}:%{$fg[blue]%}%4~%{$reset_color%}
%{$fg[red]%}%B›%{$reset_color%} "
function set_cursor() {
	echo -ne "\e[5 q"
}
precmd_functions+=(set_cursor)

function mkfile() {
	mkdir -p "$(dirname "$1")" && touch "$1"
}

# rust
source $HOME/.cargo/env

# tangram
export PATH="$HOME/.tangram/bin:$PATH"
# source <(tg shellhook zsh)
# source <(tg run -p ~/env -- --shell zsh);

# set key timeout
KEYTIMEOUT=0

# set highlight colors
zle_highlight=(region:bg=#05428f;paste:bg=none)

# enable binding of ^s
stty -ixon

# never remove completion suffix
ZLE_REMOVE_SUFFIX_CHARS=""

# ctrl o for hx
function hx_widget() {
	hx
	set_cursor
	zle reset-prompt
}
zle -N hx_widget
bindkey ^o hx_widget

# ctrl f for lf
function lf_widget() {
	cd $(lf -print-last-dir)
	set_cursor
	zle reset-prompt
}
zle -N lf_widget
bindkey ^f lf_widget

# # ctrl g for gitui
# function gitui_widget() {
# 	gitui < $TTY
# 	set_cursor
# 	zle reset-prompt
# }
# zle -N gitui_widget
# bindkey ^g gitui_widget

# # ctrl g for git status
# function git_widget() {
# 	git status --short --branch | bat --color always
# 	zle reset-prompt
# }
# zle -N git_widget
# bindkey ^g git_widget

# ctrl g for search
function search_widget() {
	SEARCH_COMMAND="rg --color=always --column --line-number --multiline --no-heading --smart-case --with-filename {q}"
	rm -f /tmp/{r,f};
	fzf \
		--ansi \
		--bind "change:reload:sleep 0.1; ${SEARCH_COMMAND} || true" \
		--bind "ctrl-p:toggle-preview" \
		--bind "ctrl-v:change-preview-window(down|right)" \
		--bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(f > )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/r; cat /tmp/f)" \
		--bind "ctrl-r:unbind(ctrl-r)+change-prompt(r > )+disable-search+reload(${SEARCH_COMMAND})+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/f; cat /tmp/r)" \
		--bind "start:reload(${SEARCH_COMMAND})+unbind(ctrl-r)" \
		--delimiter ":" \
		--disabled \
		--preview "bat --color always --highlight-line {2} {1}" \
		--preview-window "right" \
		--prompt "r > " < $TTY
}
zle -N search_widget
bindkey ^g search_widget

# ctrl r for history
function history_widget() {
	LBUFFER=$(fc -lnr 1 | fzf --height "-50%" --query "$BUFFER")
	set_cursor
	zle reset-prompt
}
zle -N history_widget
bindkey ^r history_widget

# ctrl s to edit command
autoload edit-command-line
zle -N edit-command-line
function custom-edit-command-line() {
	zle edit-command-line
	set_cursor
	zle reset-prompt
}
zle -N custom-edit-command-line
bindkey ^s custom-edit-command-line

# ctrl t for files
function files_widget() {
	LBUFFER="${LBUFFER}$(fd | fzf --height "-50%")"
	set_cursor
	zle reset-prompt
}
zle -N files_widget
bindkey ^t files_widget

# ctrl w or ctrl q to exit
function exit_widget() {
	exit
}
zle -N exit_widget
bindkey ^w exit_widget
bindkey ^q exit_widget


# bun completions
[ -s "/Users/nitsky/.bun/_bun" ] && source "/Users/nitsky/.bun/_bun"
