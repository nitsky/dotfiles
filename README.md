# Dotfiles

Personal configuration for macOS and Linux. The bare Git repository is at
`~/.dotfiles`, and the working tree is the home directory.

Manage tracked files explicitly:

```nu
^git --git-dir /Users/nitsky/.dotfiles --work-tree /Users/nitsky status --untracked-files=no
^git --git-dir /Users/nitsky/.dotfiles --work-tree /Users/nitsky add README.md
```

Do not add private-key backups, PINs, passphrases, or recovery codes to Git.

## Set up a machine from scratch

All routine setup lives in `~/.config/dotfiles/setup.sh`. It runs with Bash,
Zsh, or a POSIX shell. Install Git, Nushell, tmux, GnuPG, and `pinentry-mac`
(macOS) or `pinentry-tty` (Linux) first; package installation is managed separately.

On a new machine, download and review the script, then run it:

```sh
curl -fsSL https://raw.githubusercontent.com/nitsky/dotfiles/main/.config/dotfiles/setup.sh -o /tmp/dotfiles-setup.sh
bash /tmp/dotfiles-setup.sh
```

The download uses the published `main` branch; local changes must be pushed
before they are available there. You can also copy the script to a new machine.
Use `zsh` in place of `bash` if preferred. On an existing machine:

```sh
bash "$HOME/.config/dotfiles/setup.sh"
```

The script clones the bare repository over HTTPS when needed, checks out a
fresh clone, disables Git's filesystem monitor for this repository, hides
untracked home-directory files, and creates executable symlinks. Existing
checkouts and their pending changes are preserved. If checkout reports conflicts,
back up the specific conflicting files and rerun setup.

### Executable symlinks

| Local symlink | Target |
| --- | --- |
| `~/.local/bin/nu` | Installed `nu` executable |
| `~/.local/bin/dotfiles-pinentry` | `pinentry-mac` on macOS; `pinentry-tty` on Linux |

Tmux and GPG use these stable paths. Setup searches `PATH` and the usual Homebrew
locations. The symlinks are generated per machine; do not add them to Git.
Rerun setup if an installation path changes. It replaces existing symlinks and
refuses to overwrite ordinary files or directories. It does not change the
login shell.

### Optional setup steps

After configuring GitHub SSH authentication, switch origin to SSH and configure
the `main` upstream with:

```sh
bash "$HOME/.config/dotfiles/setup.sh" --ssh-remote
```

To name a Mac, choose names appropriate to that machine. For David's MacBook Pro:

```sh
bash "$HOME/.config/dotfiles/setup.sh" --mac-name "David's MacBook Pro" --mac-hostname davids-macbook-pro
```

Mac naming uses `sudo`. Add `--reload` to reload a running tmux server and the
local GPG agent after setup; the tmux shell setting applies to new panes.
Options can be combined. Run the script with `--help` for a list.

Review machine-specific paths and the `Host nitsky` forwarding block before
using them on another machine. The YubiKey provisioning, agent forwarding, and
private-key restoration procedures below are separate from routine setup.

## YubiKeys

Configured in October 2026:

| Device | Use |
| --- | --- |
| YubiKey 5C Nano | Daily use, plugged into the Mac |
| YubiKey 5C NFC | Backup, stored securely |

Both devices are registered separately for Daybreak and have FIDO2 PINs.
Always Require User Verification is off: PIN verification depends on the
credential policy and the website's request.

Both devices contain the same OpenPGP signing, encryption, and authentication
subkeys. OpenPGP touch requirements are off to permit agent-driven operations.
The OpenPGP user PIN and admin PIN are independent of the FIDO2 PIN.

Primary key fingerprint:

```text
A94DC81E2E27806C0C8C0E0F011FE34E52FC7F38
```

| Subkey | Fingerprint |
| --- | --- |
| Signing | `BFF8E6C3C08EE06D18E21095F1C7A089E3C59BAF` |
| Encryption | `BAA108D9E24B878993B15EBB131F9399109D73B9` |
| Authentication | `91CB0C9FD1965F121F7707D1A479BC191AA0B85F` |

As of October 12, 2026, both the Mac and `nitsky` store passphrase-protected
software copies of the primary key and all three subkeys in their own
`~/.gnupg/private-keys-v1.d`. They do not need the Mac, a forwarded agent, or a
YubiKey for private-key operations. Both YubiKeys still contain the same subkeys.
The passphrase-protected `~/nitsky.gpg` remains the full private-key backup;
an additional backup is stored elsewhere.

`~/nitsky.public.gpg` on both machines is an ASCII-armored export containing only
the public key and subkeys.
It is safe to copy this export to a new machine. To use either YubiKey there:

```nu
^gpg --import ~/nitsky.public.gpg
# Plug in the intended YubiKey, then learn its card references.
^gpg --card-status
^gpg-connect-agent 'learn --force' /bye
```

These card-reference steps are for a machine without software private keys.
Do not run `keytocard` on the everyday software keyrings: it replaces software
keys with card references. Neither YubiKey needs to be reprovisioned.

Software keys still require their GPG passphrase when it is not cached.
Both agents currently cache it for one day of inactivity, with a seven-day
maximum, for both GPG operations and SSH authentication (`default-cache-ttl`
and `default-cache-ttl-ssh` are `86400`; both maximum TTLs are `604800`).
A reboot or agent restart clears that cache. On the Mac, `pinentry-mac`
can save software-key passphrases in macOS Keychain; the server uses
`pinentry-tty` and needs its own initial unlock.

### Switch between devices

Connect only the intended device, then update the local card references:

```nu
^gpg-connect-agent 'scd serialno' 'learn --force' /bye
^gpg --card-status
^ssh-add -l
```

Signing, decryption, and signing through the SSH authentication key have been
tested on both devices. Private keys cannot be exported from a YubiKey; retain
the offline backup for recovery and provisioning replacement devices.

## SSH and GPG forwarding to `nitsky` (preserved, currently disabled)

The following describes the optional forwarding setup. It is not the active
configuration. The `RemoteForward` and `ExitOnForwardFailure` lines are commented
out in the Mac's `~/.ssh/config`, and `ForwardAgent no` is set for `nitsky`.
The remote `no-autostart` option is commented out, the local GPG agent units are
unmasked and running, and the SSH-server drop-in is preserved as
`/etc/ssh/sshd_config.d/50-gpg-forwarding-nitsky.conf.disabled`.

Nushell on both machines defaults to the local GPG SSH agent. The original
forwarded-agent detection and `ssh-agent-refresh` command are retained. To opt
back into using a reachable forwarded SSH agent, set this before reloading:

```nu
$env.GPG_USE_FORWARDED_AGENT = true
source ~/.config/nushell/config.nu
```

To re-enable GPG forwarding, first close connections to `nitsky`, stop and mask
its local GPG agent units listed below, enable `no-autostart`, and restore the
disabled SSH-server drop-in (validate with `sudo sshd -t`, then reload sshd).
On the Mac, uncomment the two forwarding lines and change `ForwardAgent no`
to `ForwardAgent yes` for `nitsky`. Reconnect and opt into the forwarded agent
in Nushell as above. Software private-key copies may remain installed; they
do not have to be deleted to use the forwarded agent.

### Original forwarding setup

Connect normally from the Mac:

```nu
ssh nitsky
```

When enabled, `ForwardAgent yes` forwards SSH authentication. This host-specific
block in `~/.ssh/config` forwards GPG operations:

```sshconfig
Host nitsky
  ControlMaster auto
  ControlPersist 10m
  ForwardAgent yes
  ExitOnForwardFailure yes
  RemoteForward /run/user/1001/gnupg/S.gpg-agent /Users/nitsky/.gnupg/S.gpg-agent.extra
```

With `GPG_USE_FORWARDED_AGENT=true`, Nushell prefers GPG's SSH agent in local sessions, rather than the empty Apple
agent inherited by new Mac terminals. In SSH sessions (`SSH_CONNECTION` is set),
it preserves the inherited agent only if `ssh-add -l` reports it reachable:
exit code 0 means it has keys, and 1 means it is reachable but empty. Otherwise,
Nushell selects GPG's local SSH socket and launches the local agent. Overwriting
a usable forwarded socket on the server breaks onward SSH and Git
authentication even when GPG forwarding still works. Reconnect after changing
this configuration so the shell receives a fresh forwarded socket.

After disconnecting and reattaching to tmux, existing panes can retain the old
`SSH_AUTH_SOCK`. Tmux updates its session environment when attaching, but does
not rewrite the environment of already-running shells. In each affected
Nushell pane, run:

```nu
ssh-agent-refresh
```

This reads the current pane's tmux session environment, verifies that its agent
is reachable, and updates the calling shell. Load a newly added command with
`source ~/.config/nushell/config.nu`. Already-running child processes retain
their old environment and may need to be restarted separately.

The remote socket path comes from `gpgconf --list-dirs agent-socket` on `nitsky`.
The local destination is GPG's restricted extra socket, rather than its normal
agent socket.

Connections using the `nitsky` alias share one SSH master connection, kept alive
for ten minutes after the last session closes. This avoids separate connections
competing to replace the same remote GPG socket. Avoid forwarding that same
socket through a separate connection with `-S none` or another SSH alias.

### Remote configuration

The following changes were made on `nitsky` for the original forwarding-only
setup; they have now been reversed as described above:

- `~/.gnupg/gpg.conf` contains `no-autostart` so GPG does not start a local agent.
- The user units `gpg-agent.service`, `gpg-agent.socket`,
  `gpg-agent-browser.socket`, `gpg-agent-extra.socket`, and
  `gpg-agent-ssh.socket` are masked and stopped.
- `/etc/ssh/sshd_config.d/50-gpg-forwarding-nitsky.conf` contains:

  ```sshconfig
  Match User nitsky
    StreamLocalBindUnlink yes
  Match all
  ```

  This allows reconnection to replace a stale forwarding socket. The SSH server
  configuration was validated and reloaded.
- The primary private key and all three private subkeys were removed from
  `/home/nitsky/.gnupg/private-keys-v1.d`. Public keys remain installed.

Remote signing and decryption use the Mac's agent and YubiKey. PIN prompts appear
on the Mac. The server needs an active forwarding connection and the connected
YubiKey for these private-key operations. Without forwarding, it can still
verify signatures and encrypt using public keys.

Remote signing, decryption, SSH-agent access, and reconnecting were tested. GPG
may report `problem with fast path key listing: Forbidden - ignored` because the
forwarded agent is restricted; the tested operations still succeeded.

Only forward agents to trusted hosts: software on the remote host can request
operations while the connection is active. With touch disabled, these requests
do not require a separate physical approval.

### Undo forwarding and restore remote private keys

These instructions change the remote machine back to using its own software
private keys. They are not needed for normal forwarded use.

1. On the Mac, remove the `Host nitsky` block shown above from `~/.ssh/config`.
   Keep `ForwardAgent yes` if ordinary SSH-agent forwarding is still wanted.
2. Close existing forwarding connections, then reconnect to `nitsky` using the
   updated configuration. Removing the block does not change an existing SSH
   connection.
3. On `nitsky`, remove `no-autostart` from `~/.gnupg/gpg.conf`.
4. On `nitsky`, unmask the local agent units and remove the stale forwarded socket
   before starting the local socket:

   ```sh
   systemctl --user unmask gpg-agent.socket gpg-agent-browser.socket gpg-agent-extra.socket gpg-agent-ssh.socket gpg-agent.service
   rm -f -- /run/user/1001/gnupg/S.gpg-agent
   systemctl --user start gpg-agent.socket
   ```

   Remove that socket only after all forwarding sessions have closed.
5. On `nitsky`, remove the SSH-server drop-in and reload the validated config:

   ```sh
   sudo rm -- /etc/ssh/sshd_config.d/50-gpg-forwarding-nitsky.conf
   sudo sshd -t && sudo systemctl reload sshd
   ```
6. Securely copy the private-key backup to `nitsky`, then import it there:

   ```sh
   gpg --import /path/to/nitsky.gpg
   ```

   Remove the transferred backup file after confirming the import if it is no
   longer needed on the server. The imported software private keys remain in
   the remote keyring and allow operation without the Mac or YubiKey.
