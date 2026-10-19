#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: bash setup.sh [options] (or zsh setup.sh)

Bootstrap ~/.dotfiles, configure Git, and create ~/.local/bin symlinks.
Install Git, Nushell, tmux, GnuPG, and pinentry first.

  --ssh-remote          Use SSH for origin and fetch/set the main upstream
                       (run after configuring GitHub SSH authentication).
  --mac-name NAME       Set macOS ComputerName.
  --mac-hostname NAME   Set macOS HostName and LocalHostName.
  --reload             Reload running tmux and the local GPG agent.
  --help               Show this help.

Existing checkouts are preserved. Checkout conflicts must be backed up manually.
YubiKey provisioning and SSH/GPG forwarding are separate, optional procedures.
EOF
}

ssh_remote=false
reload=false
mac_name=
mac_hostname=
while [ "$#" -gt 0 ]; do
    case $1 in
        --ssh-remote) ssh_remote=true ;;
        --reload) reload=true ;;
        --mac-name|--mac-hostname)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                echo "$1 requires a nonempty name." >&2; exit 1
            fi
            case $1 in
                --mac-name) mac_name=$2 ;;
                --mac-hostname) mac_hostname=$2 ;;
            esac
            shift ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

# Include Homebrew locations when run from a fresh Bash or Zsh session.
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export PATH

case $(uname -s) in
    Darwin) pinentry=pinentry-mac ;;
    Linux) pinentry=pinentry-tty ;;
    *) echo "Unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

if [ "$(uname -s)" != Darwin ] && { [ -n "$mac_name" ] || [ -n "$mac_hostname" ]; }; then
    echo "Mac naming options require macOS." >&2; exit 1
fi
case $mac_hostname in
    *[!a-zA-Z0-9-]*|-*|*-)
        echo "Use letters, digits, and interior hyphens for the Mac hostname." >&2; exit 1 ;;
esac

find_program() {
    program=$(command -v "$1") || {
        echo "Install $1 before running this script." >&2
        exit 1
    }
    case $program in
        /*) ;;
        *) echo "Expected an absolute executable path for $1: $program" >&2; exit 1 ;;
    esac
    test -x "$program"
    printf '%s\n' "$program"
}

nu_path=$(find_program nu)
pinentry_path=$(find_program "$pinentry")
for dependency in git tmux gpgconf; do
    find_program "$dependency" >/dev/null
done
bin_dir="$HOME/.local/bin"

# Check both destinations before changing either. Existing symlinks are safe
# to replace, but ordinary files and directories belong to the user.
for name in dotfiles-nu dotfiles-pinentry; do
    destination="$bin_dir/$name"
    if [ -e "$destination" ] && [ ! -L "$destination" ]; then
        echo "Refusing to replace $destination; move it aside first." >&2
        exit 1
    fi
done

dotfiles_git() {
    git -c core.fsmonitor=false --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

if [ ! -e "$HOME/.dotfiles" ]; then
    git clone --bare https://github.com/nitsky/dotfiles "$HOME/.dotfiles"
fi
if [ "$(dotfiles_git config --bool core.bare)" != true ]; then
    echo "Expected a bare Git repository at $HOME/.dotfiles." >&2; exit 1
fi
dotfiles_git config core.fsmonitor false
dotfiles_git config status.showUntrackedFiles no
# A bare clone has no index. Do not re-checkout an existing working tree,
# which may contain staged or unstaged changes.
if [ ! -f "$HOME/.dotfiles/index" ]; then
    if ! dotfiles_git checkout; then
        echo "Back up the conflicting files reported above, then rerun setup." >&2
        exit 1
    fi
fi

mkdir -p "$bin_dir"
for name in dotfiles-nu dotfiles-pinentry; do
    case $name in
        dotfiles-nu) target=$nu_path ;;
        dotfiles-pinentry) target=$pinentry_path ;;
    esac
    destination="$bin_dir/$name"
    if [ -L "$destination" ]; then rm "$destination"; fi
    ln -s "$target" "$destination"
    printf '%s -> %s\n' "$destination" "$target"
done

if [ "$ssh_remote" = true ]; then
    if dotfiles_git remote get-url origin >/dev/null 2>&1; then
        dotfiles_git remote set-url origin git@github.com:nitsky/dotfiles
    else
        dotfiles_git remote add origin git@github.com:nitsky/dotfiles
    fi
    dotfiles_git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    dotfiles_git fetch origin main
    dotfiles_git branch --set-upstream-to=origin/main main
fi

if [ -n "$mac_name" ]; then sudo scutil --set ComputerName "$mac_name"; fi
if [ -n "$mac_hostname" ]; then
    sudo scutil --set HostName "$mac_hostname"
    sudo scutil --set LocalHostName "$mac_hostname"
fi

if [ "$reload" = true ]; then
    if tmux list-sessions >/dev/null 2>&1; then
        tmux source-file "$HOME/.config/tmux/tmux.conf"
    fi
    gpgconf --reload gpg-agent
fi
printf '%s\n' 'Dotfiles setup complete.'
