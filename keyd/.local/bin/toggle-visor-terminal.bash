#!/usr/bin/env bash

# Thin wrapper: keyd's command() has a 256-char hard length cap, and
# toggle-hotkey-window.bash's full invocation -- plus the DISPLAY/XAUTHORITY/
# DBUS_SESSION_BUS_ADDRESS/XDG_RUNTIME_DIR exports needed to reach the real
# session from keyd's rootless `su @USER@ -c` -- blows past it (258 chars
# with --verify). Moving the exports and args in here instead of the
# default.conf.in command() line shrinks that binding to ~65 chars, so this
# is a plain symlinked script under $HOME (not a templated etc/ file) --
# it can use $HOME / `id -u` for real at runtime, no @HOME@/@UID@ rendering
# needed.

this_uid="$(id -u)"

export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$this_uid/bus"
export XDG_RUNTIME_DIR="/run/user/$this_uid"

# Dispatch on whichever terminal Debian's alternatives system resolves --
# Cinnamon's default is gnome-terminal, XFCE's is xfce4-terminal, and the
# two need genuinely different toggle-hotkey-window.bash arguments, not
# just a different launch command:
#   - gnome-terminal has --class, which fully REPLACES WM_CLASS's class
#     field, so the drop-down instance is uniquely matchable by class alone
#     (see app.conf's header comment).
#   - xfce4-terminal has no --class/--name flag at all (confirmed via its
#     man page: only --role, which sets WM_WINDOW_ROLE, a different X11
#     property). Every xfce4-terminal window keeps the SAME WM_CLASS
#     regardless, so the drop-down instance can only be told apart from a
#     regular one via --role + toggle-hotkey-window.bash's --by-role match.
#
# Resolve to the REAL binary name, not `x-terminal-emulator` itself: on
# Debian/Ubuntu, that alternative's target for xfce4-terminal is
# /usr/bin/xfce4-terminal.wrapper, a legacy-xterm-flag translator (only
# understands -e/-T/-geometry/etc.) that silently DROPS any option it
# doesn't recognize -- including --role. Invoking `xfce4-terminal` by its
# own bare name (found on PATH, the real GOption-parsed GTK binary) is what
# the readlink is here to choose between; it is not itself invoked.
terminal="$(readlink -f /etc/alternatives/x-terminal-emulator 2>/dev/null)"
case "$(basename "${terminal:-}")" in
  gnome-terminal*)
    exec "$HOME/.local/bin/toggle-hotkey-window.bash" --verify visor-terminal gnome-terminal --class=visor-terminal
    ;;
  xfce4-terminal*)
    exec "$HOME/.local/bin/toggle-hotkey-window.bash" --verify --by-role visor-terminal xfce4-terminal --role=visor-terminal
    ;;
  *)
    zenity --error --text="toggle-visor-terminal.bash: unsupported x-terminal-emulator '$terminal' -- add a case for it (see this script's header and app.conf's header comment for the class-vs-role reasoning)." 2>/dev/null
    exit 1
    ;;
esac
