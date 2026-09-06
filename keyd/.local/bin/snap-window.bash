#!/usr/bin/env bash

set -e

qte () {
  "$@" 2> /dev/null
}

die() {
  qte zenity --error --text="$1"
  exit 1
}

usage() {
  cat <<EOT

$(basename "$0") 4 3 6
  +------+------+------+------+
  |  1   |  2   |  3   |  4   |
  +------+------+------+------+
  |  5   | [6]  |  7   |  8   |
  +------+------+------+------+
  |  9   | 10   | 11   | 12   |
  +------+------+------+------+

$(basename "$0") 4 1 2
  +------+------+------+------+
  |      |      |      |      |
  |      |      |      |      |
  |  1   | [2]  |  3   |  4   |
  |      |      |      |      |
  |      |      |      |      |
  +------+------+------+------+
EOT
  exit
}

WMCTRL="$(    command -v wmctrl   || die "wmctrl not found!"   )"
XDOTOOL="$(   command -v xdotool  || die "xdotool not found!"  )"
XWININFO="$(  command -v xwininfo || die "xwininfo not found!" )"
XPROP="$(     command -v xprop    || die "xprop not found!"    )"

# _NET_WORKAREA (EWMH-standard, every WM sets it -- xfwm4, Muffin, etc.)
# gives the usable desktop area directly: origin + size with panels/docks
# already excluded on every edge, not just the bottom. Replaces the old
# `xfconf-query -c xfce4-panel -p /panels/panel-0/size` lookup, which is
# XFCE-specific (no xfce4-panel exists on Cinnamon, so it failed there) and
# only ever accounted for a bottom panel eating into the height. One
# workspace's (x,y,width,height) repeats per desktop in the property; the
# first group is enough since panel geometry doesn't vary by desktop.
read -r WA_X WA_Y WA_WIDTH WA_HEIGHT _ <<<"$("$XPROP" -root _NET_WORKAREA |
  sed -e 's/^[^=]*= *//' -e 's/,//g')"

HEIGHT="$WA_HEIGHT"
WIDTH="$WA_WIDTH"

# https://unix.stackexchange.com/questions/14159/how-do-i-find-the-window-dimensions-and-position-accurately-including-decoration

# Get the coordinates of the active window's top-left corner, and the window's size. This excludes the window decoration.
# shellcheck disable=SC2034  # y and h captured for completeness; x and w are used
x='' y='' w='' h=''
# shellcheck disable=SC2046
eval "$("$XWININFO" -id "$("$XDOTOOL" getactivewindow)" |
  sed -n -e "s/^ \+Absolute upper-left X: \+\([0-9]\+\).*/x=\1/p" \
         -e "s/^ \+Absolute upper-left Y: \+\([0-9]\+\).*/y=\1/p" \
         -e "s/^ \+Width: \+\([0-9]\+\).*/w=\1/p" \
         -e "s/^ \+Height: \+\([0-9]\+\).*/h=\1/p" )"

case "$1" in
  up)
    X="$x"
    Y="$WA_Y"
    HEIGHT="$((HEIGHT / 2))"
    WIDTH="$w"
    ;;
  down)
    X="$x"
    Y="$((WA_Y + HEIGHT / 2))"
    HEIGHT="$((HEIGHT / 2))"
    WIDTH="$w"
    ;;
  center)
    X="$((WA_X + WIDTH / 6))"
    Y="$((WA_Y + HEIGHT / 6))"
    HEIGHT="$((HEIGHT * 2 / 3))"
    WIDTH="$((WIDTH * 2 / 3))"
    ;;
  maximized)
    # Toggle, not set -- matches every other wmctrl -b action here, and
    # lets the same chord un-maximize on a second press. No X/Y/WIDTH/
    # HEIGHT to compute, so skip straight past the shared resize call.
    "$WMCTRL" -r :ACTIVE: -b toggle,maximized_vert,maximized_horz
    exit
    ;;
  top)
    case "$3" in
      full)
        # Three columns (full height)
        # top left-third    full
        # top middle-third  full
        # top right-third   full

        # Two columns
        # top left          full
        # top right         full

        # Two-thirds / one-third split (full height)
        # top left-two-thirds   full
        # top right-two-thirds  full
        X="$WA_X"
        Y="$WA_Y"
        case "$2" in
          left-third)
            WIDTH="$((WA_WIDTH / 3))"
            ;;
          middle-third)
            WIDTH="$((WA_WIDTH / 3))"
            X="$((WA_X + WIDTH))"
            ;;
          right-third)
            WIDTH="$((WA_WIDTH / 3))"
            X="$((WA_X + WIDTH * 2))"
            ;;
          left)
            WIDTH="$((WA_WIDTH / 2))"
            ;;
          right)
            WIDTH="$((WA_WIDTH / 2))"
            X="$((WA_X + WIDTH))"
            ;;
          left-two-thirds)
            WIDTH="$((WA_WIDTH * 2 / 3))"
            ;;
          right-two-thirds)
            WIDTH="$((WA_WIDTH * 2 / 3))"
            X="$((WA_X + WA_WIDTH / 3))"
            ;;
          one-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            ;;
          two-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH))"
            ;;
          three-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH * 2))"
            ;;
          four-fourth)
            #zenity --info
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH * 3))"
            ;;
          *) exit;;
        esac
        ;;
      half)
        # Two rows
        # top full          half

        # Three columns (top half)
        # top left-third    half
        # top middle-third  half
        # top right-third   half

        # 4-corners
        # top left          half
        # top right         half
        HEIGHT="$((HEIGHT / 2))"
        WIDTH="$((WA_WIDTH / 3))"
        X="$WA_X"
        Y="$WA_Y"
        case "$2" in
          full)
            WIDTH="$WA_WIDTH"
            ;;
          left-third)
            ;;
          middle-third)
            X="$((WA_X + WIDTH))"
            ;;
          right-third)
            X="$((WA_X + WIDTH * 2))"
            ;;
          left)
            WIDTH="$((WA_WIDTH / 2))"
            ;;
          right)
            WIDTH="$((WA_WIDTH / 2))"
            X="$((WA_X + WIDTH))"
            ;;
          one-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            ;;
          two-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH))"
            ;;
          three-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH * 2))"
            ;;
          four-fourth)
            WIDTH="$((WA_WIDTH / 4))"
            X="$((WA_X + WIDTH * 3))"
            ;;
          *) exit;;
        esac
        ;;
      *) exit;;
    esac
    ;;
  bottom)
    # Two rows
    # bottom full         half

    # Three columns (bottom half)
    # bottom left-third   half
    # bottom middle-third half
    # bottom right-third  half

    # 4-corners
    # bottom left         half
    # bottom right        half
    HEIGHT="$((HEIGHT / 2))"
    WIDTH="$((WA_WIDTH / 3))"
    X="$WA_X"
    Y="$((WA_Y + HEIGHT))"
    case "$2" in
      full)
        WIDTH="$WA_WIDTH"
        ;;
      left-third)
        ;;
      middle-third)
        X="$((WA_X + WIDTH))"
        ;;
      right-third)
        X="$((WA_X + WIDTH * 2))"
        ;;
      left)
        WIDTH="$((WA_WIDTH / 2))"
        ;;
      right)
        WIDTH="$((WA_WIDTH / 2))"
        X="$((WA_X + WIDTH))"
        ;;
      one-fourth)
        WIDTH="$((WA_WIDTH / 4))"
        ;;
      two-fourth)
        WIDTH="$((WA_WIDTH / 4))"
        X="$((WA_X + WIDTH))"
        ;;
      three-fourth)
        WIDTH="$((WA_WIDTH / 4))"
        X="$((WA_X + WIDTH * 2))"
        ;;
      four-fourth)
        WIDTH="$((WA_WIDTH / 4))"
        X="$((WA_X + WIDTH * 3))"
        ;;
      *) exit;;
    esac
    ;;
  *) exit;;
esac

#                          windowsize [options] [window] width height
#"$XDOTOOL" getactivewindow windowsize --sync "$WIDTH" "$HEIGHT"

#                          windowmove [options] [window] x y
#"$XDOTOOL" getactivewindow windowmove "$X" "$Y"

"$WMCTRL" -r :ACTIVE: -b remove,maximized_horz,maximized_vert
"$WMCTRL" -r ":ACTIVE:" -e "0,$X,$Y,$WIDTH,$HEIGHT"
