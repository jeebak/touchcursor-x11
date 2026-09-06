#!/usr/bin/env bash

# Thin wrapper: keyd's command() runs every action as root (keyd.service has
# no User=). snap-window.bash itself doesn't need root -- it only queries/
# resizes the ALREADY-ACTIVE window via wmctrl/xdotool/xprop/xwininfo, none
# of which need more than a valid X11 connection (DISPLAY + XAUTHORITY).
# Running it as root anyway just widens the blast radius of any future bug
# in the script for no benefit, so this re-execs it as the real user instead.
# Same DISPLAY/XAUTHORITY-only requirement as toggle-visor-terminal.bash's
# wrapper, minus its DBUS_SESSION_BUS_ADDRESS/XDG_RUNTIME_DIR exports --
# snap-window.bash never spawns a new app, so it never needs a D-Bus session.

export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
exec "$HOME/.local/bin/snap-window.bash" "$@"
