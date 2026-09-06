#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# ── keyd: kernel-level keyboard remapper ─────────────────────────────────────
# Ubuntu 25.04+ / Debian 13+ ship keyd in the official repos. Earlier releases
# (e.g. Ubuntu 24.04 "noble") need the project's own PPA backport instead —
# verified live on Launchpad, builds for noble among others.
# https://github.com/rvaiya/keyd
if ! apt-cache show keyd &>/dev/null; then
  command -v add-apt-repository &>/dev/null || sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt-get update
fi
# keyd-application-mapper (started below) is a separate package on Debian/the
# PPA — not bundled into `keyd` itself. Its Debian build is patched to invoke
# the renamed `keyd.rvaiya` binary internally, so this Just Works.
sudo apt-get install -y keyd keyd-application-mapper

# keyd-application-mapper (started below, driven by app.conf) talks to keyd's
# IPC socket and needs the user in the `keyd` group to do so.
# https://github.com/rvaiya/keyd (Post-Installation Setup)
sudo usermod -aG keyd "$USER"
echo "NOTE: added $USER to 'keyd' group — reboot before keyd-application-mapper works (a re-login alone was not enough in practice)."

# ── xdotool / wmctrl: required by toggle-visor-terminal.bash ────────────────
sudo apt-get install -y xdotool wmctrl

# ── Symlink .config/ and .local/bin/ into $HOME ──────────────────────────────
mkdir -p "$HOME/.config/keyd" "$HOME/.config/autostart" "$HOME/.local/bin"
ln -sf "$REPO_DIR/.config/keyd/app.conf" "$HOME/.config/keyd/app.conf"
ln -sf "$REPO_DIR/.config/autostart/keyd-application-mapper.desktop" \
  "$HOME/.config/autostart/keyd-application-mapper.desktop"
for script in "$REPO_DIR"/.local/bin/*.bash; do
  ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
done

# ── Deploy keyd system config (requires sudo) ────────────────────────────────
# etc/keyd/default.conf.in is the source of truth, templated with
# @HOME@/@USER@/@UID@ placeholders since its command() bindings need real,
# hard-coded values baked in, not env-var expansions keyd itself would have
# to resolve at runtime. Render with sed (unprivileged) and elevate only the
# write via `sudo tee`.
#
# Derive from `id`/`getent`, not $HOME/$USER/$UID: only $UID is guaranteed by
# bash itself (computed via getuid() at startup); $HOME and $USER are just
# inherited env vars, set by login/PAM for an interactive shell but not
# guaranteed in every invocation context.
render_user="$(id -un)"
render_uid="$(id -u)"
render_home="$(getent passwd "$render_user" | cut -d: -f6)"
sudo mkdir -p /etc/keyd
sed \
  -e "s|@HOME@|$render_home|g" \
  -e "s|@USER@|$render_user|g" \
  -e "s|@UID@|$render_uid|g" \
  "$REPO_DIR/etc/keyd/default.conf.in" \
  | sudo tee /etc/keyd/default.conf > /dev/null
sudo systemctl enable --now keyd

# No DE keyboard-shortcut configuration needed: Space+;/Space+'/Space+Enter
# send Ctrl+Alt+Left/Right/Up directly, piggybacking on each DE's own
# default workspace-switching chord, and Space+/ runs the drop-down
# terminal script directly via command() -- both bypass xfconf-query
# entirely (it's XFCE-specific and silently does nothing on Cinnamon/GNOME/
# etc. sessions). This is what makes this package portable across DEs: it
# reads whichever terminal each DE already ships (gnome-terminal on
# Cinnamon, xfce4-terminal on XFCE) via toggle-visor-terminal.bash's own
# /etc/alternatives/x-terminal-emulator dispatch, rather than requiring a
# specific one be installed. See README.md → Workspace Navigation, →
# Drop-down Terminal, and → Config Syntax Gotchas.

# toggle-visor-terminal.bash only knows how to drive gnome-terminal and
# xfce4-terminal (see its own header comment for why the two need different
# treatment). Warn now, at install time, rather than let Space+/ silently
# fail with a zenity popup the first time it's pressed.
resolved_terminal="$(basename "$(readlink -f /etc/alternatives/x-terminal-emulator 2>/dev/null)")"
case "$resolved_terminal" in
  gnome-terminal*|xfce4-terminal*) : ;;
  *) echo "NOTE: x-terminal-emulator resolves to '$resolved_terminal', which toggle-visor-terminal.bash doesn't know how to drive yet -- see its header comment to add a case for it." ;;
esac

# ── Start keyd-application-mapper ────────────────────────────────────────────
# Reads ~/.config/keyd/app.conf to apply per-app layer switching. This starts
# it for the CURRENT login session only -- persistence across reboots comes
# from ~/.config/autostart/keyd-application-mapper.desktop (symlinked above),
# a standard XDG autostart entry that Cinnamon/GNOME/KDE/XFCE all honor
# natively, no DE-specific GUI configuration needed.
keyd-application-mapper -d || true

echo "keyd installed. Log out and back in (or reboot) for the 'keyd' group membership to take effect."
