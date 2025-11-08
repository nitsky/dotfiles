use std/util "path add"

# path
path add /opt/homebrew/sbin
path add /opt/homebrew/bin
path add /opt/homebrew/opt/llvm/bin
path add ~/.bun/bin
path add ~/.cargo/bin
path add ~/.orbstack/bin
path add ~/helix/target/release
path add ~/.local/bin

# aliases
alias b = bun
alias bx = bunx
alias c = bat
alias code = ^open -a "Visual Studio Code"
alias d = docker
alias dotfiles = git --git-dir ~/.dotfiles --work-tree ~/ -c core.fsmonitor=false
alias e = hx
alias f = fd
alias g = git
alias j = jj
alias l = lf
alias k = kubectl
alias time = timeit
alias tree = eza -T
alias u = cd ..
alias zed = ^open -a "Zed"

# banner
$env.config.show_banner = false

# bun
$env.BUN_INSTALL = "~/.bun" | path expand

# cursor
$env.config.cursor_shape.emacs = "line"

# editor
$env.EDITOR = "hx"
$env.config.buffer_editor = "hx"

# fzf
$env.FZF_DEFAULT_OPTS = "--reverse --exit-0 --select-1 --preview=bat --color=16,fg+:blue,pointer:blue"
$env.FZF_DEFAULT_COMMAND = "fd --type f --no-ignore"

# gpg
$env.GPG_TTY = (tty)
$env.SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket)
if ((pgrep -q gpg-agent | complete | get exit_code) == 0) {
	gpgconf --launch gpg-agent
}

# helix
$env.HELIX_RUNTIME = "~/helix/runtime" | path expand

# homebrew
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"

# less
$env.LESS = "-R"
$env.LESSHISTFILE = "/dev/null"

# nu
$env.config.display_errors.exit_code = false
$env.config.display_errors.termination_signal = false
$env.config.use_kitty_protocol = true
$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

# prompt
$env.PROMPT_COMMAND = {
  let user = $"(ansi green)(whoami)(ansi reset)"
  let hostname = $"(ansi green)(sys host | get hostname)(ansi reset)"
  let cwd = $"(ansi blue)($env.PWD | str replace $env.HOME "~")(ansi reset)"
  let git = try {
    let branch = (git rev-parse --abbrev-ref HEAD e> /dev/null | str trim)
    let hash = (git rev-parse --short HEAD e> /dev/null | str trim)
    $" (ansi cyan)($branch):($hash)(ansi reset)"
  } catch { "" }
  let exit = $" (if $env.LAST_EXIT_CODE == 0 { ansi green } else { ansi red })($env.LAST_EXIT_CODE)(ansi reset)";
  let duration = $" (if ($"($env.CMD_DURATION_MS)ms" | into duration) < 1sec { ansi green } else { ansi red })($"($env.CMD_DURATION_MS)ms" | into duration)(ansi reset)";
  $"($user)@($hostname):($cwd)($git)($exit)($duration)\n"
};
$env.PROMPT_COMMAND_RIGHT = ""
$env.PROMPT_INDICATOR = $"(ansi red)➜(ansi reset) "
$env.PROMPT_MULTILINE_INDICATOR = $"(ansi red)•(ansi reset) "

# secrets
open ~/.secrets | from toml | load-env

# tangram
path add ~/tangram/target/release
alias tg = tangram
alias tgd = ./target/debug/tangram -m client
alias tgr = ./target/release/tangram -m client
alias tgo = orb ./target/aarch64-unknown-linux-gnu/release/tangram

# ctrl f for lf
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_f
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: `
      cd (lf -print-last-dir)
    `
  }
}]

# ctrl g for search
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_g
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: `
      tv text
    `
  }
}]

# ctrl o for hx
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_o
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: `
      hx
    `
  }
}]

# ctrl q to exit
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_q
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: '
      exit
    '
  }
}]

# ctrl r for history
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_r
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: '
      commandline edit (history | get command | to text | tv --inline --no-remote -i (commandline))
    '
  }
}]

# ctrl s to edit the commandline
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_s
  mode: emacs
  event: { send: "openeditor" }
}]

# ctrl t for files
$env.config.keybindings ++= [{
  modifier: control
  keycode: char_t
  mode: emacs
  event: {
    send: executehostcommand,
    cmd: '
      commandline edit -i (fd | tv --inline --no-remote)
    '
  }
}]

def monitor [
  --duration (-d): duration = 1sec
  command: closure
] {
  loop {
    clear
    let last_run = (date now)
    let next = $last_run + $duration
    do $command | print
    sleep ($next - (date now))
  }
}
