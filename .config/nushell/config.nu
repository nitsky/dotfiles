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

# Refresh this shell's SSH agent after reattaching to tmux.
def --env ssh-agent-refresh [] {
	if ($env.TMUX_PANE? | is-empty) {
		error make { msg: "run this command inside tmux" }
	}
	let session = (^tmux display-message -p -t $env.TMUX_PANE '#{session_id}' | complete)
	if $session.exit_code != 0 {
		error make { msg: ($session.stderr | str trim) }
	}
	let agent = (^tmux show-environment -t ($session.stdout | str trim) SSH_AUTH_SOCK | complete)
	let agent = ($agent.stdout | str trim)
	if not ($agent | str starts-with 'SSH_AUTH_SOCK=') {
		error make { msg: "this tmux session has no SSH agent; reconnect with agent forwarding and reattach" }
	}
	let socket = ($agent | str replace 'SSH_AUTH_SOCK=' '')
	let agent = (with-env { SSH_AUTH_SOCK: $socket } { ^ssh-add -l | complete })
	if $agent.exit_code not-in [0 1] {
		error make { msg: "the tmux session's SSH agent is unreachable; reconnect with agent forwarding and reattach" }
	}
	$env.SSH_AUTH_SOCK = $socket
	print $"SSH agent: ($socket)"
}

# gpg
$env.GPG_TTY = (tty)
# Prefer local GPG, but preserve a reachable agent inherited over SSH.
let ssh_agent = (^ssh-add -l | complete)
let forwarded_agent = (not ($env.SSH_CONNECTION? | is-empty)) and ($ssh_agent.exit_code in [0 1])
if not $forwarded_agent {
	$env.SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket)
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
if ("~/.secrets" | path exists) {
	open ~/.secrets | from toml | load-env
}

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

def _usage-time [value, missing: string = "unknown"] {
	if $value == null { return $missing }
	let date = if ($value | describe) == "int" {
		$value | into datetime -f "%s"
	} else {
		$value | into datetime
	}
	$date | date to-timezone local | format date "%b %d, %Y %I:%M %p %Z"
}

def _usage-openai [result: record] {
	let limits = ($result | get -o rateLimitsByLimitId | default {})
	let limits = if ($limits | is-empty) {
		[($result | get -o rateLimits)] | compact
	} else {
		$limits | values
	}
	let windows = ($limits | each {|limit|
		[$limit.primary? $limit.secondary?] | compact | each {|window|
			{
				provider: OpenAI
				window: ($window.windowDurationMins * 1min | into string)
				used: $"($window.usedPercent)%"
				available: $"(100 - $window.usedPercent)%"
				resets: (_usage-time $window.resetsAt?)
			}
		}
	} | flatten)
	let credit = ($result | get -o rateLimits.credits)
	let balance = if $credit.unlimited? == true {
		"unlimited"
	} else if $credit.balance? != null {
		$"($credit.balance | into float | math round --precision 2) credits"
	} else if $credit.hasCredits? == false {
		"0 credits"
	} else {
		"not reported"
	}
	let resets = ($result | get -o rateLimitResetCredits.credits | default [] | each {|credit|
		{
			provider: OpenAI
			reset: ($credit.title? | default "Rate-limit reset")
			count: 1
			status: ($credit.status? | default "unknown")
			expires: (_usage-time $credit.expiresAt? "never")
		}
	})
	{
		windows: $windows
		credits: [{provider: OpenAI, balance: $balance}]
		resets: $resets
		reset_count: ($result | get -o rateLimitResetCredits.availableCount)
	}
}

def _anthropic-usage [] {
	let config_dir = ($env.CLAUDE_CONFIG_DIR? | default ($env.HOME | path join ".claude"))
	let credentials_file = ($config_dir | path join ".credentials.json")
	# Keep the token in memory, not shell arguments, logs, or output.
	let token = if not ($env.CLAUDE_CODE_OAUTH_TOKEN? | is-empty) {
		$env.CLAUDE_CODE_OAUTH_TOKEN
	} else {
		let credentials = if $nu.os-info.name == "macos" {
			let keychain = (^security find-generic-password -s "Claude Code-credentials" -w | complete)
			if $keychain.exit_code == 0 {
				try { $keychain.stdout | from json } catch { {} }
			} else if ($credentials_file | path exists) {
				try { open --raw $credentials_file | from json } catch { {} }
			} else { {} }
		} else if ($credentials_file | path exists) {
			try { open --raw $credentials_file | from json } catch { {} }
		} else { {} }
		$credentials | get -o claudeAiOauth.accessToken
	}
	if ($token | is-empty) {
		error make { msg: "No Claude subscription login found; run claude auth login if applicable." }
	}
	# Undocumented Claude Code endpoint; do not refresh or alter its credentials.
	let response = try {
		http get --full --allow-errors --max-time 10sec --redirect-mode error --headers {
			Authorization: $"Bearer ($token)"
			anthropic-beta: "oauth-2025-04-20"
		} "https://api.anthropic.com/api/oauth/usage?cedar_ember=1"
	} catch {
		error make { msg: "Anthropic usage request failed; check your network connection." }
	}
	if $response.status in [401 403] {
		error make { msg: "Claude login expired or lacks usage access; open Claude Code or run claude auth login." }
	}
	if $response.status != 200 {
		error make { msg: $"Anthropic usage unavailable: HTTP ($response.status)." }
	}
	# Claude Code's prepaid balance endpoint can report a balance even when
	# usage.spend.balance is null. Failure here must not hide quota information.
	let prepaid = try {
		let auth = (^claude auth status | complete)
		let org = ($auth.stdout | from json | get -o orgId)
		if $org == null or $org !~ '^[a-zA-Z0-9-]+$' { null } else {
			let balance = (http get --full --allow-errors --max-time 10sec --redirect-mode error --headers {
				Authorization: $"Bearer ($token)"
				anthropic-beta: "oauth-2025-04-20"
			} $"https://api.anthropic.com/api/oauth/organizations/($org)/prepaid/credits")
			if $balance.status == 200 { $balance.body } else { null }
		}
	} catch { null }
	$response.body | insert prepaid_balance $prepaid
}

def _usage-anthropic [result: record] {
	# New responses include model-specific limits that the legacy fields omit.
	let limits = ($result.limits? | default [])
	let windows = if not ($limits | is-empty) {
		$limits | each {|limit|
			let window = match $limit.kind {
				"session" => "5hr"
				"weekly_all" => "7day"
				"weekly_scoped" => $"7day ($limit.scope.model.display_name? | default ($limit.scope.surface? | default 'scoped'))"
				_ => $limit.kind
			}
			{
				provider: Anthropic
				window: $window
				used: $"($limit.percent)%"
				available: $"(100 - $limit.percent)%"
				resets: (_usage-time $limit.resets_at?)
			}
		}
	} else {
		$result | transpose name value
		| where {|entry| $entry.value != null and ($entry.name =~ '^(five_hour|seven_day)') }
		| each {|entry|
			{
				provider: Anthropic
				window: ($entry.name | str replace 'five_hour' '5hr' | str replace 'seven_day' '7day' | str replace --all '_' ' ')
				used: $"($entry.value.utilization)%"
				available: $"(100 - $entry.value.utilization)%"
				resets: (_usage-time $entry.value.resets_at?)
			}
		}
	}
	# A spending cap minus spend is NOT a prepaid credit balance.
	let prepaid = ($result.prepaid_balance? | default {})
	let credit = ($prepaid | get -o balance.credits)
	let money = ($prepaid | get -o balance.money | default ($result | get -o spend.balance))
	let balance = if $credit.amount_minor? != null and $credit.exponent? != null {
		$"($credit.amount_minor / (10 ** $credit.exponent) | math round --precision 2) credits"
	} else if $prepaid.balance_credits? != null {
		$"($prepaid.balance_credits) credits"
	} else if $money.amount_minor? != null and $money.exponent? != null {
		$"($money.amount_minor / (10 ** $money.exponent) | math round --precision 2) ($money.currency? | default 'credits')"
	} else if $prepaid.amount? != null {
		$"($prepaid.amount / 100 | math round --precision 2) ($prepaid.currency? | default 'USD')"
	} else {
		"not reported"
	}
	let grants = ($result | get -o cedar_ember.grants | default [])
	let resets = ($grants | each {|grant|
		{
			provider: Anthropic
			reset: ($grant.label? | default "Rate-limit reset")
			count: $grant.resets_left
			status: (if $grant.paused? == true { "paused" } else if $grant.usable_now? == true { "available" } else { "not currently usable" })
			expires: (_usage-time $grant.ends_at? "never")
		}
	})
	let reset_count = if $result.cedar_ember? == null {
		"not reported"
	} else if $result.cedar_ember.eligible? == false {
		"not eligible"
	} else if ($grants | is-empty) {
		0
	} else {
		$grants | get resets_left | math sum
	}
	{
		windows: $windows
		credits: [{provider: Anthropic, balance: $balance}]
		resets: $resets
		reset_count: $reset_count
	}
}

# Subscription quotas, reset times/credits, and balances (not Platform API billing).
def usage [--json # Return structured JSON instead of displaying tables.
] {
	mut windows = []
	mut credits = []
	mut resets = []
	mut reset_counts = []
	mut errors = []
	for provider in [OpenAI Anthropic] {
		let data = try {
			if $provider == "OpenAI" {
				_usage-openai (_codex-rate-limits)
			} else {
				_usage-anthropic (_anthropic-usage)
			}
		} catch {|err|
			{error: $err.msg}
		}
		if $data.error? != null {
			$errors = ($errors | append {provider: $provider, error: $data.error})
		} else {
			$windows = ($windows | append $data.windows)
			$credits = ($credits | append $data.credits)
			$resets = ($resets | append $data.resets)
			$reset_counts = ($reset_counts | append {
				provider: $provider
				available: ($data.reset_count | default "not reported")
			})
		}
	}
	let result = {usage: $windows, credits: $credits, reset_counts: $reset_counts, resets: $resets, errors: $errors}
	if $json { return ($result | to json) }
	print "usage"
	print ($windows | table)
	print "resets"
	let openai_resets = ($resets | where provider == "OpenAI")
	if not ($openai_resets | is-empty) { print ($openai_resets | table) }
	print "credits"
	print ($credits | table)
	for err in $errors { print --stderr $"($err.provider): ($err.error)" }
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
# Show the available box subcommands.
def box [] {
	help box
}

# Resize nitsky, preserving unspecified resources. A running instance may reboot.
# Examples: box resize --cpus 8 --memory 32; box resize --memory 64
def "box resize" [
	--cpus: number  # OCPU count (one OCPU is two vCPUs on this AMD machine).
	--memory: number  # Memory in GB.
] {
	if ($cpus == null) and ($memory == null) {
		error make { msg: "Specify --cpus and/or --memory, e.g. box resize --cpus 8 --memory 32." }
	}
	if $cpus != null {
		if $cpus <= 0 {
			error make { msg: "--cpus must be greater than zero." }
		}
	}
	if $memory != null {
		if $memory <= 0 {
			error make { msg: "--memory must be greater than zero." }
		}
	}
	let instance = (box status)
	if $instance.state not-in [RUNNING STOPPED] {
		error make { msg: $"Wait for nitsky to be RUNNING or STOPPED before resizing; current state: ($instance.state)." }
	}
	let shape_config = {
		ocpus: ($cpus | default $instance.ocpus)
		memoryInGBs: ($memory | default $instance.memory_gb)
	}
	let result = (
		oci compute instance update --instance-id $box_instance_id --shape-config ($shape_config | to json -r) --force --wait-for-state $instance.state
		| complete
	)
	if $result.exit_code != 0 {
		error make { msg: ($result.stderr | str trim) }
	}
	box status
}

# Set nitsky's OCPU count, preserving its memory. A running instance may reboot.
def "box cpus" [count: number] {
	box resize --cpus $count
}

# Set nitsky's memory in GB, preserving its OCPU count. A running instance may reboot.
def "box memory" [gb: number] {
	box resize --memory $gb
}

# Start nitsky, optionally resizing it first.
def "box start" [
	--cpus: number  # Optional OCPU count for the flex shape.
	--memory: number  # Optional memory in GB for the flex shape.
] {
	if ($cpus != null) or ($memory != null) {
		box resize --cpus $cpus --memory $memory | ignore
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
