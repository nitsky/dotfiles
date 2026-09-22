use std/util "path add"

source "~/.cargo/env.nu"

# path
path add /opt/homebrew/sbin
path add /opt/homebrew/bin
path add /opt/homebrew/opt/llvm/bin
path add ~/.bun/bin
path add ~/.cargo/bin
path add ~/.grok/bin
path add ~/.orbstack/bin
path add ~/helix/target/release
path add ~/.local/bin

# aliases
alias b = bun
alias bx = bunx
alias c = bat
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

# git
# Show LOC changes by calendar period.
def git-stats [] {
	help git-stats
}

# Show the LOC landed on a day, such as `git-stats day 2026-08-11` or `git-stats day yesterday`.
def "git-stats day" [day?: string, --ref: string = "main"] {
	let day = if $day == null { date now } else { $day | date from-human }
	let since = ($day | format date "%Y-%m-%d 00:00:00")
	let until = ($day + 1day | format date "%Y-%m-%d 00:00:00")
	_git-stats $since $until $ref
}

# Show the LOC landed in the Monday-based week containing a date, such as `git-stats week 2026-08-03`.
def "git-stats week" [day?: string, --ref: string = "main"] {
	let day = if $day == null { date now } else { $day | date from-human }
	let weekday = ($day | format date "%u" | into int)
	let start = ($day - (($weekday - 1) * 1day))
	let since = ($start | format date "%Y-%m-%d 00:00:00")
	let until = ($start + 7day | format date "%Y-%m-%d 00:00:00")
	_git-stats $since $until $ref
}

# Show the LOC landed in a month, such as `git-stats month 2026-07`.
def "git-stats month" [month?: string, --ref: string = "main"] {
	let month = if $month == null { date now } else { $"($month)-01" | date from-human }
	let day = ($month | format date "%d" | into int)
	let start = ($month - (($day - 1) * 1day))
	let since = ($start | format date "%Y-%m-01 00:00:00")
	let until = ($start + 32day | format date "%Y-%m-01 00:00:00")
	_git-stats $since $until $ref
}

def _git-stats [since: string, until: string, ref: string] {
	let result = (
		^git log $ref --first-parent $"--since=($since)" $"--until=($until)" --format=commit:%H --numstat --diff-merges=first-parent
		| complete
	)
	if $result.exit_code != 0 {
		error make { msg: ($result.stderr | str trim) }
	}
	let lines = ($result.stdout | lines)
	let commits = ($lines | where {|line| $line =~ '^commit:' } | length)
	let stats = (
		$lines
		| where {|line| $line | str contains "\t" }
		| each {|line|
			let columns = ($line | split row "\t")
			if $columns.0 == "-" {
				null
			} else {
				{
					insertions: ($columns.0 | into int)
					deletions: ($columns.1 | into int)
				}
			}
		}
		| compact
	)
	let insertions = if ($stats | is-empty) { 0 } else { $stats.insertions | math sum }
	let deletions = if ($stats | is-empty) { 0 } else { $stats.deletions | math sum }
	{
		ref: $ref
		since: $since
		until: $until
		commits: $commits
		insertions: $insertions
		deletions: $deletions
		churn: ($insertions + $deletions)
		net: ($insertions - $deletions)
	}
}

# banner
$env.config.show_banner = false

# bun
$env.BUN_INSTALL = "~/.bun" | path expand

# cursor
$env.config.cursor_shape.emacs = "line"
$env.config.cursor_shape.helix_insert = "line"
$env.config.cursor_shape.helix_normal = "block"
$env.config.color_config.selection = { bg: "#05428f" }

# editor
$env.EDITOR = "hx"
$env.config.buffer_editor = "hx"
$env.config.edit_mode = 'emacs'

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
$env.PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
$env.PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
$env.PROMPT_MULTILINE_INDICATOR = $"(ansi red)•(ansi reset) "

# secrets
open ~/.secrets | from toml | load-env

# codex
def _codex-rate-limits [] {
	let initialize = ({
		method: initialize
		id: 1
		params: {
			clientInfo: { name: codex-rate-limits, version: "1.0" }
			capabilities: { experimentalApi: true }
		}
	} | to json -r)
	let initialized = ({ method: initialized } | to json -r)
	let read = ({
		method: "account/rateLimits/read"
		id: 2
		params: null
	} | to json -r)
	let responses = (
		[
			{ delay: 0ms, message: $initialize }
			{ delay: 200ms, message: $initialized }
			{ delay: 100ms, message: $read }
			{ delay: 3sec, message: $initialized }
		]
		| each {|item| sleep $item.delay; $item.message }
		| to text
		| ^codex app-server --stdio err> /dev/null
		| lines
		| each {|line| try { $line | from json } catch { null } }
		| compact
	)
	let matches = ($responses | where id? == 2)
	if ($matches | is-empty) {
		error make { msg: "Codex did not return usage information." }
	}
	let response = ($matches | first)
	if $response.error? != null {
		error make { msg: ($response.error | to json -r) }
	}
	$response.result
}

def codex-usage [] {
	let result = (_codex-rate-limits)
	[
		($result | get -o rateLimits.primary)
		($result | get -o rateLimits.secondary)
	]
	| compact
	| each {|window|
		let resets_at = ($window | get -o resetsAt)
		{
			window: ($window.windowDurationMins * 1min)
			available: $"(100 - $window.usedPercent)%"
			resets: (if $resets_at == null {
				"unknown"
			} else {
				$resets_at
				| into datetime -f "%s"
				| date to-timezone local
				| format date "%b %d, %Y %I:%M %p %Z"
			})
		}
	}
}

def codex-resets [] {
	let result = (_codex-rate-limits)
	$result
	| get -o rateLimitResetCredits.credits
	| default []
	| each {|credit|
		let expires_at = ($credit | get -o expiresAt)
		{
			reset: ($credit | get -o title)
			expires: (if $expires_at == null {
				"never"
			} else {
				$expires_at
				| into datetime -f "%s"
				| date to-timezone local
				| format date "%b %d, %Y %I:%M %p %Z"
			})
		}
	}
}

# tangram
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

const box_instance_id = "ocid1.instance.oc1.iad.anuwcljtw252hhqckwm6hatmpxt22zhvoku4jwmhihdwwvx42f2slco54jgq"
def "box start" [
	--cpus: number  # Optional OCPU count for the flex shape.
	--memory: number  # Optional memory in GB for the flex shape.
] {
	if ($cpus != null) or ($memory != null) {
		mut shape_config = {}
		if $cpus != null {
			$shape_config = ($shape_config | insert ocpus $cpus)
		}
		if $memory != null {
			$shape_config = ($shape_config | insert memoryInGBs $memory)
		}
		oci compute instance update --instance-id $box_instance_id --shape-config ($shape_config | to json -r) --force
	}
	oci compute instance action --instance-id $box_instance_id --action START --wait-for-state RUNNING
}
def "box status" [] {
	let instance = (
		oci compute instance get --instance-id $box_instance_id
		| from json
		| get data
	)
	{
		name: ($instance | get display-name)
		state: ($instance | get lifecycle-state)
		shape: ($instance | get shape)
		ocpus: ($instance | get shape-config.ocpus)
		memory_gb: ($instance | get shape-config.memory-in-gbs)
		region: ($instance | get region)
		availability_domain: ($instance | get availability-domain)
	}
}
def "box stop" [] {
	oci compute instance action --instance-id $box_instance_id --action SOFTSTOP --wait-for-state STOPPED
}
