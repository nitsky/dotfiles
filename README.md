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

### Install the dotfiles

Install Git first. Run the bootstrap commands below in the machine's default
Bash or Zsh shell, before Nushell is installed and configured.

Clone over HTTPS so the initial checkout does not require SSH authentication:

```sh
git clone --bare https://github.com/nitsky/dotfiles "$HOME/.dotfiles"
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config core.fsmonitor false
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config status.showUntrackedFiles no
```

If checkout reports existing files that would be overwritten, stop and move or
back up the specific conflicting files, then retry checkout. Avoid forcing a
checkout over existing configuration. The repository-local settings disable
the filesystem monitor during bootstrap and hide untracked home-directory files.

Once SSH authentication to GitHub is configured, switch the remote to SSH and
configure the upstream branch:

```sh
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" remote remove origin
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" remote add origin git@github.com:nitsky/dotfiles
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" fetch origin main
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" branch --set-upstream-to=origin/main main
```

The checkout installs configuration files; it does not install the applications
they configure. Review machine-specific paths and the `Host nitsky` forwarding
block before using them on a different machine.

### Name a Mac

Choose names appropriate to the machine. For David's MacBook Pro:

```sh
sudo scutil --set ComputerName "David's MacBook Pro"
sudo scutil --set HostName "davids-macbook-pro"
sudo scutil --set LocalHostName "davids-macbook-pro"
```

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

The Mac's everyday keyring contains card references for these subkeys. The
primary certification private key remains on the Mac. The passphrase-protected
`~/nitsky.gpg` contains the full private key and subkeys; an additional backup is
stored elsewhere. Moving all software private-key copies offline remains a
separate hardening step.

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

## SSH and GPG forwarding to `nitsky`

Connect normally from the Mac:

```nu
ssh nitsky
```

The existing `ForwardAgent yes` forwards SSH authentication. This host-specific
block in `~/.ssh/config` also forwards GPG operations:

```sshconfig
Host nitsky
  ControlMaster auto
  ControlPersist 10m
  ExitOnForwardFailure yes
  RemoteForward /run/user/1001/gnupg/S.gpg-agent /Users/nitsky/.gnupg/S.gpg-agent.extra
```

Nushell prefers GPG's SSH agent in local sessions, rather than the empty Apple
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

The following changes were made on `nitsky`:

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
