#!/usr/bin/env bash

# EXPERIMENTAL -- generalized dropdown/hotkey-window toggle, derived from
# toggle-visor-terminal.bash's toggle mechanics. Toggles any app's window
# (identified by WM_CLASS, or WM_WINDOW_ROLE via --by-role) between hidden
# and shown/focused/on-top, kept sticky across every workspace -- an
# iTerm2-style Hotkey Window, for any app whose launch command can be told
# what WM_CLASS or WM_WINDOW_ROLE to use.
#
# usage: toggle-hotkey-window.bash [-m|--maximize] [--verify] [--by-role] <ident> <command> [args...]
#
#   -m, --maximize   maximize the window the first time it's created
#   --verify         after hiding or showing, poll briefly for the expected
#                     window state and warn (via zenity) if it didn't take --
#                     off by default, since it adds a short poll-and-wait to
#                     every toggle to catch a failure mode that's rare, and
#                     when it does happen is usually a case of multiple
#                     windows sharing one identifier (ambiguous, not
#                     something this script can resolve) rather than the app
#                     itself being incompatible -- so the warning says the
#                     toggle didn't apply as expected, not that the app is
#                     unsupported
#   --by-role        match <ident> against WM_WINDOW_ROLE instead of
#                     WM_CLASS. Needed for apps with no CLI flag to set a
#                     custom WM_CLASS (e.g. xfce4-terminal, which only
#                     exposes --role, not --class) -- see
#                     toggle-visor-terminal.bash for the dispatch between
#                     the two.
#   <ident>          WM_CLASS (default) or WM_WINDOW_ROLE (--by-role) to
#                     search for / expect the launched window to register as
#   <command> [...]  how to launch the app when no matching window exists
#                     yet -- include whatever flag that app uses to set its
#                     own WM_CLASS/WM_WINDOW_ROLE to <ident> (e.g.
#                     gnome-terminal's --class=<ident>, or xfce4-terminal's
#                     --role=<ident> with --by-role), if it has one and you
#                     need an identifier distinct from the app's own default

set -e

qte () {
  "$@" 2> /dev/null
}

die() {
  qte zenity --error --text="$1"
  exit 1
}

usage() {
  echo "usage: $(basename "$0") [-m|--maximize] [--verify] [--by-role] <ident> <command> [args...]" >&2
  exit 64
}

MAXIMIZE=0
VERIFY=0
BY_ROLE=0
while [[ "$1" == "-m" || "$1" == "--maximize" || "$1" == "--verify" || "$1" == "--by-role" ]]; do
  case "$1" in
    -m|--maximize) MAXIMIZE=1 ;;
    --verify)      VERIFY=1 ;;
    --by-role)     BY_ROLE=1 ;;
  esac
  shift
done

[[ $# -ge 2 ]] || usage
IDENT="$1"
shift

WMCTRL="$( command -v wmctrl  || die "wmctrl not found!")"
XDOTOOL="$(command -v xdotool || die "xdotool not found!")"
XPROP="$(  command -v xprop   || die "xprop not found!")"

# wmctrl -lx (backed by _NET_CLIENT_LIST), not `xdotool search --class`: some
# apps (e.g. gnome-terminal-server) keep an internal group-leader window
# alive for their whole lifetime, carrying the SAME WM_CLASS as every real
# window they spawn -- `xdotool search --class` matches it too, and a later
# toggle can find and act on that stub instead of a real window.
# _NET_CLIENT_LIST only lists real top-level windows, excluding leaders like
# this, so it's the robust choice regardless of whether the target app has
# that quirk.
#
# Match ends-with ".<ident>", not contains: a plain substring check matches
# any class that has <ident> as a PREFIX too (confirmed live -- IDENT=Nemo
# matched nemo-desktop's own "nemo-desktop.Nemo-desktop", a persistent
# unrelated process, because "Nemo-desktop" contains "Nemo" as a prefix).
# Anchoring to the end of the field rejects that false positive while still
# matching the real "nemo.Nemo" window.
#
# --by-role mode (WM_WINDOW_ROLE, not WM_CLASS): for apps with no CLI flag
# to set a custom WM_CLASS (xfce4-terminal only exposes --role). wmctrl has
# no role column, so this walks `wmctrl -l`'s window list (still
# _NET_CLIENT_LIST-backed -- same stub-window exclusion as the class path
# above) and asks xprop for each one's role directly. An exact match, not a
# suffix match: unlike WM_CLASS, WM_WINDOW_ROLE has no instance-prefix
# convention to guard against, and apps that don't set a role at all (most
# don't, unless told to) report "not found", which never equals a real
# <ident>.
find_window_by_role () {
  local wid role
  while read -r wid _; do
    role="$(qte "$XPROP" -id "$wid" WM_WINDOW_ROLE | sed -n 's/.*= "\(.*\)"/\1/p')"
    [[ "$role" == "$IDENT" ]] && { echo "$wid"; return; }
  done < <(qte "$WMCTRL" -l)
  # Explicit success: falling off the loop otherwise returns the terminating
  # `read`'s failure (EOF = 1), and WINDOW_ID="$(find_window)" is a bare
  # assignment -- under `set -e` a non-zero here aborts the whole script
  # silently, before the "no window found, launch one" branch ever runs. The
  # --class path (awk, always exits 0) never hit this.
  return 0
}

find_window () {
  if [[ $BY_ROLE -eq 1 ]]; then
    find_window_by_role
  else
    qte "$WMCTRL" -lx | awk -v c=".$IDENT" '
      { tail = substr($3, length($3) - length(c) + 1)
        if (tail == c) { print $1; exit }
      }'
  fi
}

# --verify only: poll up to ~2s for a condition, instead of trusting the WM
# request took effect immediately. Not run by default -- every toggle would
# pay this latency to catch a failure mode that's rare, so it's opt-in.
poll_hidden () {
  # $1: 1 = wait for _NET_WM_STATE_HIDDEN to appear, 0 = wait for it to clear
  local want="$1" state
  for _ in $(seq 1 10); do
    state="$(qte xprop -id "$WINDOW_ID" _NET_WM_STATE)"
    [[ "$want" == 1 && "$state" == *_NET_WM_STATE_HIDDEN* ]] && return 0
    [[ "$want" == 0 && "$state" != *_NET_WM_STATE_HIDDEN* ]] && return 0
    sleep 0.2
  done
  return 1
}

poll_shown_on () {
  # Wait for HIDDEN to clear AND the window to actually be on $1
  #
  # Read _NET_WM_DESKTOP via xprop, not `xdotool get_desktop_for_window`:
  # xfwm4 (XFCE's WM) sets it to the literal EWMH "all desktops" sentinel
  # (0xFFFFFFFF = 4294967295) on a sticky window, and xdotool's
  # get_desktop_for_window fails outright on exactly that value ("XGetWindow
  # Property[_NET_WM_DESKTOP] failed") even though xprop reads it fine --
  # confirmed live on XFCE. That made this poll never succeed, which then
  # blocked the whole script on the foreground `zenity --warning` in warn().
  # Muffin (Cinnamon's WM) instead keeps a real desktop number on a sticky
  # window (see the retarget-before-activate comment above), which is why
  # this never surfaced there. Treat the sentinel as trivially "on current
  # desktop" -- sticky-to-all includes it by definition.
  local want_desktop="$1" state desk
  for _ in $(seq 1 10); do
    state="$(qte xprop -id "$WINDOW_ID" _NET_WM_STATE)"
    desk="$(qte xprop -id "$WINDOW_ID" _NET_WM_DESKTOP | sed -n 's/.*= //p')"
    [[ "$state" != *_NET_WM_STATE_HIDDEN* ]] || { sleep 0.2; continue; }
    [[ "$desk" == "$want_desktop" || "$desk" == "4294967295" ]] && return 0
    sleep 0.2
  done
  return 1
}

warn() {
  qte zenity --warning --text="$1"
}

WINDOW_ID="$(find_window)"

if [[ -z "$WINDOW_ID" ]]; then
  ("$@" &)
  # We seem to need to wait, or these will fail
  sleep 1
  WINDOW_ID="$(find_window)"
  [[ -n "$WINDOW_ID" ]] ||
    die "Launched '$*' but no window with $([[ $BY_ROLE -eq 1 ]] && echo role || echo class) '$IDENT' appeared."

  if [[ $MAXIMIZE -eq 1 ]]; then
    "$WMCTRL" -i -r "$WINDOW_ID" -b "toggle,maximized_vert,maximized_horz"
  fi
  "$WMCTRL" -i -r "$WINDOW_ID" -b "add,sticky"
else
  # _NET_WM_STATE_HIDDEN via xprop, not xwininfo's Map State: on this WM
  # (Cinnamon/Muffin) a minimized window still reports "Map State:
  # IsViewable" -- the toggle would keep re-minimizing an already-hidden
  # window instead of ever showing it again otherwise.
  # _NET_WM_STATE_HIDDEN is the EWMH-standard flag every modern WM sets/
  # clears on minimize/deiconify, so this is WM-agnostic.
  WmState="$(qte xprop -id "$WINDOW_ID" _NET_WM_STATE)"

  if [[ $WmState == *_NET_WM_STATE_HIDDEN* ]]; then
    # windowmap alone leaves _NET_WM_STATE_HIDDEN set when this runs via
    # `su $USER -c` from root (e.g. keyd's command() binding) -- the window
    # stays technically mapped but never actually redraws/clears the flag
    # until something also asks the WM to focus it. windowactivate right
    # after clears _HIDDEN and adds _FOCUSED.
    #
    # windowactivate on its own has a side effect on this WM (Cinnamon/
    # Muffin), though: it switches the CURRENT desktop to the window's own
    # _NET_WM_DESKTOP (fixed at creation time), even though the window is
    # sticky -- sticky only keeps it rendered on every desktop, it doesn't
    # stop the WM's activate handler from also jumping you there.
    #
    # Fix: retarget the window's own _NET_WM_DESKTOP to match wherever the
    # user currently is BEFORE activating it, so windowactivate's jump
    # becomes a same-desktop no-op -- nothing to undo, no workspace-switch
    # animation to suppress. `wmctrl -t` strips STICKY as a side effect, so
    # re-add it right after.
    #
    # The sleep after them is required: `wmctrl -t`'s retarget is a queued
    # request, not applied by the WM synchronously, and activating too soon
    # after acts on the window's PREVIOUS _NET_WM_DESKTOP, not the one just
    # requested -- surfacing as a one-cycle-behind lag across real,
    # human-paced toggles that's easy to misread as random, since any cycle
    # where the desktop happened to repeat looked correct by coincidence.
    CURRENT_DESKTOP="$("$XDOTOOL" get_desktop)"
    "$WMCTRL" -i -r "$WINDOW_ID" -t "$CURRENT_DESKTOP"
    "$WMCTRL" -i -r "$WINDOW_ID" -b "add,sticky"
    sleep 0.15
    "$XDOTOOL" windowmap "$WINDOW_ID"
    # qte: windowactivate internally reads _NET_WM_DESKTOP too, tripping the
    # same xdotool-vs-0xFFFFFFFF bug described in poll_shown_on above and
    # printing "XGetWindowProperty[_NET_WM_DESKTOP] failed" straight to
    # stderr on xfwm4 -- benign (activation still succeeds), just noisy.
    qte "$XDOTOOL" windowactivate "$WINDOW_ID"

    if [[ $VERIFY -eq 1 ]] && ! poll_shown_on "$CURRENT_DESKTOP"; then
      warn "Toggle didn't apply as expected for $([[ $BY_ROLE -eq 1 ]] && echo role || echo class) '$IDENT' -- the window didn't end up shown on the current workspace. If another window shares this identifier, the wrong one may have been matched."
    fi
  else
    "$XDOTOOL" windowminimize --sync "$WINDOW_ID"

    if [[ $VERIFY -eq 1 ]] && ! poll_hidden 1; then
      warn "Toggle didn't apply as expected for $([[ $BY_ROLE -eq 1 ]] && echo role || echo class) '$IDENT' -- the window didn't report as hidden. If another window shares this identifier, the wrong one may have been matched."
    fi
  fi
fi
