#!/usr/bin/env bash

# Stop and disable the keyd service, remove the rendered system config, and
# remove the symlinks install.sh created in $HOME.
sudo systemctl disable --now keyd || true
sudo rm -f /etc/keyd/default.conf

sudo apt-get remove -y keyd keyd-application-mapper

rm -f "$HOME/.config/keyd/app.conf" \
      "$HOME/.config/autostart/keyd-application-mapper.desktop" \
      "$HOME/.local/bin/snap-window.bash" \
      "$HOME/.local/bin/snap-window-user.bash" \
      "$HOME/.local/bin/toggle-hotkey-window.bash" \
      "$HOME/.local/bin/toggle-visor-terminal.bash"
