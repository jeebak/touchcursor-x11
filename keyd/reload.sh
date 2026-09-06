#!/usr/bin/env bash

set -e

# Re-render etc/keyd/default.conf.in and hot-reload the running keyd daemon
# (IPC to the daemon, NOT systemctl reload -- keyd.service has no
# ExecReload). Run this after editing etc/keyd/default.conf.in, instead of
# a full ./install.sh rerun.
#
# See install.sh for why this is templated rather than a plain copy, and
# for why we derive from `id`/`getent` rather than $HOME/$USER/$UID
# directly.
REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
render_user="$(id -un)"
render_uid="$(id -u)"
render_home="$(getent passwd "$render_user" | cut -d: -f6)"
sed \
  -e "s|@HOME@|$render_home|g" \
  -e "s|@USER@|$render_user|g" \
  -e "s|@UID@|$render_uid|g" \
  "$REPO_DIR/etc/keyd/default.conf.in" \
  | sudo tee /etc/keyd/default.conf > /dev/null
sudo "$(command -v keyd || command -v keyd.rvaiya)" reload

# keyd-application-mapper (app.conf) has no reload of its own to trigger --
# it self-reloads app.conf by mtime on the next window-focus event -- but it
# doesn't survive a reboot without a session-autostart entry (see README).
# Start it here too, guarded by pgrep: a second instance just dies on its
# lockfile ("only one instance may run at a time"), so this is idempotent.
pgrep -f keyd-application-mapper >/dev/null || keyd-application-mapper -d
