# TouchCursor for Linux / X11

_"There's no place like Home Row..."_

Home-row navigation and keyboard layers for Linux, derived from a Karabiner
Elements gold standard, implemented via [keyd](https://github.com/rvaiya/keyd)
— see "Background — why keyd?" below for the alternatives evaluated,
including [touchcursor-linux](https://github.com/donniebreve/touchcursor-linux)
(a purpose-built TouchCursor port for Linux, runs as a user-level systemd
service, works under both Xorg and Wayland). An older `xcape`+`autokey`-based
implementation is kept for reference under "Legacy: xcape + autokey" below.

- [keyd](https://github.com/rvaiya/keyd) — kernel-level keyboard remapper (the engine)
- [keyd-application-mapper](https://github.com/rvaiya/keyd) — per-app layer switching

---

## What is TouchCursor?

[TouchCursor](https://touchcursor.sourceforge.net/) is a concept: hold **Space** as a
modifier key, and your home row becomes a navigation cluster — arrows, Home/End,
Page Up/Down, Delete — without moving your hands.

This package extends that idea into a full keyboard layer system with:

- **Space layer** — navigation, editing, F-keys, media keys
- **CapsLock → Control (hold) / Escape (tap)** — always on

---

## Architecture

```
Physical keyboard
      │
      ▼
  /dev/input/  (raw evdev events)
      │
      ▼
   keyd daemon  ←── /etc/keyd/default.conf (rendered from keyd/etc/keyd/default.conf.in)
      │             ~/.config/keyd/app.conf (keyd-application-mapper)
      ▼
   /dev/uinput  (remapped events)
      │
      ▼
  X11 / Wayland  (display server — keyd is agnostic)
```

keyd operates at the kernel evdev level, below X11 and Wayland entirely.
It is Wayland-compatible even though XFCE currently runs on X11.

---

## Key Mappings

### Space layer — TouchCursor Extended Mode

Hold **Space**; tap a key. Release Space to deactivate. Tap Space alone for a
literal space.

Modifier stacking works naturally — no special config needed:

| Chord | Sends | Effect |
|---|---|---|
| Space + Shift + I | Shift+Up | Select up |
| Space + Ctrl + J | Ctrl+Left | Word left |
| Space + Ctrl + L | Ctrl+Right | Word right |
| Space + Ctrl + Backspace | Ctrl+Backspace | Kill word backward |
| Space + Ctrl + M | Ctrl+Delete | Kill word forward |

`A` (hold) is its own modifier layer, not a real physical key, so it resolves
differently by app (Karabiner-Elements-style: matches the macOS config's
per-app modifier split) — see "Space+A: Control in GUI apps, Alt in
terminals" below:

| Chord | GUI apps send | Terminal apps send | Effect |
|---|---|---|---|
| Space + A + J | Ctrl+Left | Alt+Left | Word left |
| Space + A + L | Ctrl+Right | Alt+Right | Word right |
| Space + A + P | Ctrl+Backspace | Alt+Backspace | Kill word backward |
| Space + A + M | Ctrl+Delete | Alt+D *(overridden — not Alt+Delete)* | Kill word forward |

#### QWERTY row

| Key | Sends | Notes |
|---|---|---|
| Q | Alt+Tab | App switcher |
| W | Ctrl+Tab | Next tab |
| E (tap) | Ctrl+N | New window |
| E (hold) | Meta | Meta modifier for nav combos |
| R (tap) | Ctrl+R | Refresh |
| R (hold) | Shift | Shift modifier — e.g. Space+R+I = Shift+Up (select up) |
| T | ~ | Tilde |
| Y | Mute | Media key |
| U | Home | |
| I | Up | |
| O | End | |
| P | Backspace | |
| [ | Volume Down | |
| ] | Volume Up | |
| \ | Play/Pause | |

#### Home row

| Key | Sends | Notes |
|---|---|---|
| A (tap) | Ctrl+A | Select all |
| A (hold) | Control (GUI apps) / Alt (terminals) | Modifier for nav combos — e.g. Space+A+J = Ctrl+Left in GUI apps, Alt+Left in terminals. See "Space+A: Control in GUI apps, Alt in terminals" below |
| S | Space | Literal space |
| D | Ctrl+W | Close tab/window |
| F | Ctrl+F | Find |
| G | Ctrl+G | Find next |
| H | Page Up | |
| J | Left | |
| K | Down | |
| L | Right | |
| ; | Ctrl+Alt+Left | Workspace previous (see Workspace Navigation below) |
| ' | Ctrl+Alt+Right | Workspace next (see Workspace Navigation below) |

#### Bottom row

| Key | Sends | Notes |
|---|---|---|
| Z | Ctrl+Z | Undo |
| X | Ctrl+X | Cut |
| C | Ctrl+C | Copy |
| V | Ctrl+V | Paste |
| B | ` | Backtick |
| N | Page Down | |
| M | Delete | Forward delete. With A held (Space+A+M): Ctrl+Delete in GUI apps; overridden to Alt+D (not Alt+Delete) in terminals — see below |
| , | Ctrl+T | New tab |
| . | Ctrl+Shift+T | Reopen tab |
| / | (script) | Toggle terminal dropdown — runs `toggle-visor-terminal.bash` directly via `command()` |

#### Number row → F-keys

| Key | Sends |
|---|---|
| 1 | F1 |
| 2 | F2 |
| … | … |
| 0 | F10 |
| - | F11 |
| = | F12 |

#### Other keys in Space layer

| Key | Sends | Notes |
|---|---|---|
| Tab | Alt+Tab | Cycle windows in same app |
| Enter | Ctrl+Alt+Up | Workspace up (see Workspace Navigation below) |
| Escape | Previous Track | Media key |
| ` | Previous Track | Media key (same, alternate key) |
| Backspace | Next Track | Media key |
| Left Shift | Alt+Space | Non-breaking space |
| Right Shift | Ctrl+Alt+Up | Workspace above (see Workspace Navigation below) |

---

### CapsLock → Control (hold) / Escape (tap)

Always remapped — replaces xcape's dual-function CapsLock. The passthrough
layer (applied in remote desktop/VM apps via `app.conf`) restores CapsLock to
its literal key so the remote machine handles it independently.

---

## Space+A: Control in GUI apps, Alt in terminals

`A` (hold) is keyd's own modifier layer, not a real physical modifier key, so
what it resolves to is configurable per app — mirroring the per-app modifier
split already used for other things in this package (see Architecture) and
matching the equivalent Karabiner-Elements setup on macOS.

- **Default (`keyd/etc/keyd/default.conf.in`'s `[nav]`):** `a = overload(control, C-a)` —
  holding Space+A stacks Control, matching the standard Linux/Windows GUI
  word-nav convention (Ctrl+Left/Right/Backspace/Delete).
- **Terminal override (`keyd/.config/keyd/app.conf`, `gnome-terminal`/`visor-terminal`/
  `xfce4-terminal`):** `nav.a = overload(alt, C-a)` — holding Space+A stacks
  Alt instead, matching readline/emacs conventions (Alt+Left/Right/
  Backspace/B/F/D) and how Claude Code's own chat input handles the same
  keys.

Both are real physical-modifier holds under the hood, so every other
Space+A+`<key>` chord is plain stacking — whatever `nav`'s key sends gets
Control or Alt applied on top, no per-key config needed. The one exception is
M's *forward*-delete direction:

### Why M needs its own override

Ctrl+Delete (GUI apps, and Space+Ctrl+M without A at all) is a real,
universally-implemented convention — no override needed. Alt+Delete isn't:
there's no standard "kill word forward via Delete" the way Alt+Backspace/
Alt+B are standard for backward, so it's up to whatever an app does with an
unrecognized modified-Delete sequence. zsh (confirmed via `cat -v`: keyd
emits `^[[3;3~`) had no binding for it at all and did nothing — fixed via a
`bindkey '^[[3;3~' kill-word` in the shell's own `zsh` config. Claude
Code *does* interpret it, but as "kill to end of line," not delete-word-
forward — undocumented, and not exposed via `~/.claude/keybindings.json`
(confirmed against code.claude.com/docs/en/keybindings, which only covers
app-level actions, not text-editing primitives).

Alt+D (`A-d`), by contrast, is the actual standard kill-word-forward binding,
and both zsh and Claude Code already handle it correctly — same family as
Alt+Backspace, which already works without an override. `default.conf.in`'s
`[alt+nav]` composite layer (active only when Control's terminal override has
put Alt in play) sends `A-d` for M instead of letting it fall through to
`nav`'s `m = delete` + Alt (physical Alt+Delete). P (Alt+Backspace) is
untouched — it already gets the right behavior via plain fallthrough.

---

## Workspace Navigation

Space+;, Space+', and Space+Enter send `Ctrl+Alt+Left` / `Ctrl+Alt+Right` /
`Ctrl+Alt+Up` directly — the DE's own default multi-workspace-switching
chord (both XFCE's xfwm4 and Cinnamon's Muffin bind these out of the box) —
rather than a custom Super+key shortcut needing `xfconf-query` registration.
This sidesteps `xfconf-query` being XFCE-specific for these three keys
entirely (unlike the drop-down terminal's Space+/, which needed the
`command()` workaround below since there's no DE-default shortcut to
piggyback on for that one).

| Chord | Sends | Notes |
|---|---|---|
| Space+; | Ctrl+Alt+Left | Workspace left/previous |
| Space+' | Ctrl+Alt+Right | Workspace right/next |
| Space+Enter | Ctrl+Alt+Up | Workspace up — same action Space+RightShift already sends; a second, more ergonomic trigger for it, not an expose/Mission Control replacement |

No custom keyboard-shortcut configuration is required for these three — they
rely entirely on the DE's own pre-bound Ctrl+Alt+arrow shortcuts. If your DE
(or window-manager theme) doesn't have Ctrl+Alt+Left/Right/Up bound to
workspace switching by default, bind them yourself in the DE's own keyboard
settings (Cinnamon: Settings → Keyboard → Shortcuts → Windows; XFCE: Window
Manager → Keyboard tab).

XFCE has no built-in expose/Mission Control equivalent; this config doesn't
attempt one — Space+Enter is workspace-up, full stop.

### Conflicts to verify

- Confirm your DE doesn't bind Ctrl+Alt+Left/Right/Up to something else
  (e.g. a VT switch on some setups, or a different window-manager action)
  that would collide with workspace switching.

---

## Window Snap-to-Grid

Two modifier chords — held simultaneously, no separate trigger key — each
run `snap-window.bash` directly via `command()`, resizing/repositioning the
currently focused window. Ported from an earlier XFCE-based window-snap
setup that wired the same 24 actions to `xfconf`-registered shortcuts
instead — replaced here for the same reason as Space+;/Space+'/
Space+Enter above: `xfconf-query` is XFCE-specific and silently does
nothing on this Cinnamon session. `keyd` binds by physical key, not the
shifted symbol, so `<Shift>greater`/`<Shift>less` in the original become
the physical period/comma keys below (Shift is already part of the chord).

### Ctrl+Shift+Super — grid positions

| Key | Snaps to |
|---|---|
| Y | Top, left third, full height |
| H | Top, middle third, full height |
| N | Top, right third, full height |
| I | Top half, full width |
| K | Bottom half, full width |
| J | Left half, full height |
| L | Right half, full height |
| U | Top-left quarter |
| O | Top-right quarter |
| M | Bottom-left quarter |
| . | Bottom-right quarter |
| , | Center (⅔ size) |
| ; | Toggle maximize |

### Ctrl+Shift+Alt — half-height thirds, quarter-columns, resize

| Key | Snaps to |
|---|---|
| J | Top, left third, half height |
| K | Top, middle third, half height |
| L | Top, right third, half height |
| M | Bottom, left third, half height |
| , | Bottom, middle third, half height |
| . | Bottom, right third, half height |
| U | Top, first quarter-column, full height |
| I | Top, second quarter-column, full height |
| O | Top, third quarter-column, full height |
| P | Top, fourth quarter-column, full height |
| H | Resize current window up |
| N | Resize current window down |

---

## Drop-down Terminal (Space+/)

Space+/ runs `toggle-visor-terminal.bash` directly via `command()` (no DE
shortcut config involved — see Config Syntax Gotchas for why). It resolves
the system's default terminal via `/etc/alternatives/x-terminal-emulator`
and dispatches to whichever this machine actually uses:

- **gnome-terminal (Cinnamon):** finds or creates a dedicated
  `gnome-terminal --class=visor-terminal` window, matched by `WM_CLASS`.
- **xfce4-terminal (XFCE):** finds or creates a dedicated
  `xfce4-terminal --role=visor-terminal` window, matched by
  `WM_WINDOW_ROLE` — xfce4-terminal has no `--class`/`--name` flag, so its
  drop-down instance can't be given a distinct `WM_CLASS` the way
  gnome-terminal's can (see `app.conf`'s header comment for the full
  reasoning, and `toggle-hotkey-window.bash`'s `--by-role` mode).

Either way it toggles the window between minimized and shown/focused/on-top
— an iTerm2-style "Hotkey Window."

**"Show on all workspaces" (iTerm2's equivalent setting):** achieved via
EWMH sticky (`wmctrl -b add,sticky`, applied once at window creation in
`toggle-hotkey-window.bash`) rather than reapplied on every toggle — this is
a persistent per-window property, not something to redo on every show/hide.
Once set, the terminal renders on every workspace, matching iTerm2's
behavior.

Sticky alone isn't sufficient on this WM (Cinnamon/Muffin), though:
`xdotool windowactivate` — needed to actually clear `_NET_WM_STATE_HIDDEN`
and unminimize (`windowmap` alone doesn't) — switches the *current* desktop
to the window's own fixed `_NET_WM_DESKTOP`, regardless of it being sticky.
Without a fix, "toggle down, switch workspace, toggle up" jumps you back to
wherever the window was first created instead of staying put.

An earlier revision let that jump happen and tried to undo it afterward
(save the current desktop, activate, restore it) — but that's still two real
desktop switches as far as Cinnamon is concerned, so its workspace-switch
slide animation and "Workspace N" OSD both fired for an operation the user
never asked to see, and restoring the desktop re-triggered Cinnamon's own
restack-on-desktop-switch handling, which kept racing with (and clobbering)
the raise/focus that needed to follow it. Flaky even with the animations
suppressed and a settle delay added.

The actual fix is simpler: retarget the window's own `_NET_WM_DESKTOP` to
match wherever the user currently is *before* activating it
(`wmctrl -t <current-desktop>`), so `windowactivate`'s jump becomes a
same-desktop no-op — nothing to undo, no animation to suppress. `wmctrl -t`
strips `STICKY` as a side effect, so the script re-adds it right after.

One more race, though: `wmctrl -t`'s retarget is a queued request, not
applied by Muffin synchronously — activating the window too soon after acts
on its *previous* `_NET_WM_DESKTOP`, not the one just requested. This showed
up as a one-cycle-behind lag across real, human-paced toggle presses (easy
to misread as random — logging `CURRENT_DESKTOP` against the resulting
`_NET_WM_DESKTOP` showed every mismatch was exactly the prior cycle's
target, and every cycle where the user happened to stay on the same desktop
twice in a row looked correct by coincidence). Rapid automated testing never
caught it: separate tool-call round-trips between commands gave Muffin
plenty of time to apply each request. A short settle delay after the
retarget, before activating, fixed it — confirmed over repeated live trials
across genuinely different target desktops each time, no coincidence
needed.

This is commented in detail at the point of use in
`toggle-visor-terminal.bash` — this section is the summary of *why* the
script looks the way it does, not a substitute for reading it.

---

## Installation

**Developed and tested on Linux Mint (Cinnamon and XFCE) only.** `install.sh`
assumes an apt-based system (Debian/Ubuntu-derived); other distros will need
to adapt the package-manager calls, and the app-detection logic (`app.conf`,
`toggle-visor-terminal.bash`) has only been exercised against Cinnamon's
`gnome-terminal` and XFCE's `xfce4-terminal`.

```bash
./keyd/install.sh
```

The script:
1. Installs `keyd` and `keyd-application-mapper` (a separate package on
   Debian/the PPA) via apt — from the official repos on Ubuntu 25.04+ / Debian
   13+, or from the [`keyd-team` PPA](https://launchpad.net/~keyd-team/+archive/ubuntu/ppa)
   backport on earlier releases (e.g. Ubuntu 24.04 "noble")
2. Adds the user to the `keyd` group (required by `keyd-application-mapper`;
   **needs a reboot to take effect** — a re-login alone was not enough in
   practice) and installs `xdotool`, `wmctrl` via apt
3. Symlinks `.config/keyd/app.conf`, `.config/autostart/keyd-application-mapper.desktop`,
   and every `.local/bin/*.bash` script into `$HOME`
4. Renders `keyd/etc/keyd/default.conf.in` (substituting `@HOME@`/`@USER@`/`@UID@`
   for the real values) to `/etc/keyd/default.conf` (requires sudo)
5. Enables and starts the `keyd` systemd service
6. Starts `keyd-application-mapper` as a background daemon for the current
   login session — the symlinked `keyd-application-mapper.desktop` autostart
   entry makes it start on every future login/reboot too

**Persisting keyd-application-mapper across reboots:**
`.config/autostart/keyd-application-mapper.desktop` is a standard
[XDG Desktop Entry autostart file](https://specifications.freedesktop.org/autostart-spec/latest/) —
symlinked by `install.sh` into `~/.config/autostart/`, where Cinnamon (like
GNOME/KDE/XFCE/MATE) picks it up natively on login. No DE-specific GUI
configuration needed. If it ever goes missing (e.g. `~/.config/autostart/`
didn't exist before install — rerun `install.sh` to recreate the symlink),
the daemon simply won't survive the next reboot until `./keyd/reload.sh` is
run again.

**After editing `keyd/etc/keyd/default.conf.in`**, re-deploy and reload:
```bash
./keyd/reload.sh
```
This re-renders `default.conf.in` to `/etc/keyd/default.conf` and hot-reloads
the running daemon (`keyd reload`, or `keyd.rvaiya reload` on Debian/Ubuntu
packages — see below). It's `keyd`'s own CLI subcommand, an IPC call to the
running daemon — **not** `systemctl reload`, which doesn't work
(`keyd.service` has no `ExecReload`).

It also starts `keyd-application-mapper` if it isn't already running (guarded
by `pgrep`, so re-running `reload.sh` is safe either way). `app.conf` itself
needs no such reload step — the mapper re-reads it by mtime on the next
window-focus event — but the mapper process itself doesn't survive a reboot
without the autostart entry described above.

**Uninstalling:** `./keyd/uninstall.sh` reverses the above — stops and
disables `keyd`, removes `/etc/keyd/default.conf`, removes the `$HOME`
symlinks `install.sh` created, and uninstalls the `keyd`/`keyd-application-mapper`
packages.

On Debian/Ubuntu packages (apt or the PPA) the binary is installed as
`keyd.rvaiya`, not `keyd` — the upstream name conflicts with a utility in the
`onak` package (see `/usr/share/doc/keyd/README.Debian`).

**Discover window classes** for `app.conf`:
```bash
xprop | grep WM_CLASS         # click a window after running
```

**Discover key names / device IDs** for `default.conf`:
```bash
keyd monitor                  # or `keyd.rvaiya monitor` on Debian/Ubuntu packages
                               # shows key events + device ids in real time
```

---

## Config Syntax Gotchas

Found the hard way while debugging silently-dropped bindings (`journalctl -u
keyd | grep ERROR` after any edit is the way to catch these):

- **No inline trailing comments.** keyd's parser only treats `#` as a comment
  when it's the *first* character on the line — `key = action   # comment`
  appends the comment text to the action value and the whole binding fails to
  parse ("invalid key or action"), silently dropping it. Parenthesized calls
  (`overload(...)`, `command(...)`) are immune — the parser stops at the
  *first* close-paren, so trailing text including a comment gets ignored —
  but bare-token actions (`m = delete`, `s = space`, chord shorthand like
  `d = C-w`) are not. Put comments on their own line above the binding
  instead. `default.conf`'s own header comment documents this in more
  detail, with the exact parser behavior.
- **`command()`'s argument parsing stops at the FIRST `)`, not a balanced
  one.** A nested `$(...)` inside the command string (e.g.
  `command(echo hi $(id) > file)`) gets silently truncated at `$(id)`'s own
  close-paren, leaving an unterminated shell fragment that fails with no
  visible error. Avoid subshell substitution inside `command()`, or route
  through a wrapper script instead. Confirmed live while debugging the
  Space+/ binding below.
- **`command()` has a hard 256-character length cap** — `keyd bind` and
  config-file loading both fail with `max command length (256) exceeded`.
  Keep the invoked command short (a script path + short args), not an
  inline multi-step pipeline.
- **`command()` runs as root with no desktop session** (`keyd.service` has
  no `User=`). Root's own attempt to reach the real session's D-Bus bus
  (even with `DISPLAY`/`DBUS_SESSION_BUS_ADDRESS`/`XDG_RUNTIME_DIR` all set
  correctly) silently fails for D-Bus-activated apps like `gnome-terminal`
  — confirmed live, it left a broken, permanently `IsUnMapped` 10x10
  `InputOnly` stub window instead of a real one. Wrap in `su <user> -c
  "..."` to actually run as the desktop user; X11-only tools (`xdotool`,
  `wmctrl`) don't need this, just `DISPLAY`/`XAUTHORITY`. xfce4-terminal is
  also D-Bus-activated by default (its `--disable-server` flag exists
  specifically to opt out — see its man page), so it needs the same `su`
  wrap; `toggle-visor-terminal.bash` applies it uniformly regardless of
  which terminal it dispatches to.
- **Key names must match `keyd list-keys` exactly.** `M-Return` silently
  failed (should be `M-enter`) — keyd has no `return` key name, only `enter`
  and `kpenter`.
- **The Debian/PPA package renames the binary to `keyd.rvaiya`** (conflicts
  with a utility in the `onak` package — see `/usr/share/doc/keyd/README.Debian`).
  `keyd reload`/`keyd monitor` become `keyd.rvaiya reload`/`keyd.rvaiya
  monitor` on those builds. Also: **`systemctl reload keyd` does not work** —
  the shipped unit has no `ExecReload`; use keyd's own `reload` CLI subcommand
  (IPC to the running daemon), not systemctl.

---

## Limitations

| Feature | Status |
|---|---|
| zsh word-nav for Space+A+J/L/M (Alt+Left/Right/Delete) | Needed a companion fix outside this package — zsh had no bindings for the CSI-modifier-3 sequences these chords send. See "Alt+Delete Override" above. |
| An app that mis-binds an unrecognized Alt-modified key (e.g. Claude Code's chat input treating Alt+Delete as kill-to-end-of-line instead of delete-word-forward) | Not fixable in this package beyond swapping the sent chord for one the app already handles correctly (done for Space+A+M — see "Alt+Delete Override"). No general defense against a given app's own undocumented text-input bindings. |
| Space+CapsLock+P (Ctrl+Backspace via the CapsLock overload) silently does nothing — no event at all, confirmed via both `xev` and `keyd monitor` | Keyboard matrix ghosting (N-key rollover limit), not a keyd/config issue — the physical keydown never reaches keyd. Isolated by testing: CapsLock+P, Space+P, and Space+CapsLock+O/`;` all register fine; only the Space+CapsLock+P triad drops, and only on this specific keyboard's matrix. Workaround: use the real physical Ctrl key instead of CapsLock — Ctrl+Space+P registers and gives the same Ctrl+Backspace. Not fixable in software since the keystroke is lost before it reaches the OS. |

---

## Wayland

keyd works on Wayland — it operates at the evdev layer below the display server.
`keyd-application-mapper` has backends for GNOME, KDE, Sway, Hyprland, and
wlroots compositors. XFCE is still X11-only as of 2026; this will be revisited
when XFCE ships a Wayland compositor.

---

## Background — why keyd?

The previous implementation (`touchcursor-x11/`) used three tools:
**xcape** (dual-function Space), **xmodmap** (keycode remapping), and
**AutoKey** (Python daemon to send remapped keys). AutoKey regularly pegged CPU
at 100%, requiring a manual restart.

Six modern alternatives were evaluated:

| Tool | Lang | App-aware | CPU | Verdict |
|---|---|---|---|---|
| **keyd** | C | ✅ built-in | <1ms | ✅ Chosen |
| kanata | Rust | via ext tool | excellent | runner-up |
| kmonad | Haskell | ❌ | GC risk | skip |
| xremap | Rust | basic | excellent | Wayland-first, weaker layers |
| interception-tools | C | ❌ | excellent | too limited |
| input-remapper | Python | limited | poor | skip |

keyd was chosen because it is the only Linux tool with **native per-application
layer switching** (`keyd-application-mapper`), matching Karabiner Elements'
`frontmost_application_unless` — the feature that makes the macOS implementation
feel seamless.

The macOS [Karabiner Elements config](https://ke-complex-modifications.pqrs.org/?rule=json%2Fpersonal_jeebak.json)
([src](https://github.com/pqrs-org/KE-complex_modifications/blob/main/src/json/personal_jeebak.json.js))
remains the gold standard. All mappings in this package are derived from it, with adaptations:
`left_command` → Meta, `left_option` → Alt, `Cmd+key` → `Ctrl+key`.

---

## Files

```
keyd/
├── install.sh          ← ./keyd/install.sh
├── reload.sh            ← ./keyd/reload.sh (after editing etc/keyd/default.conf.in)
├── uninstall.sh
├── .config/keyd/
│   └── app.conf                         ← keyd-application-mapper (symlinked to ~/.config/keyd/)
├── .config/autostart/
│   └── keyd-application-mapper.desktop  ← XDG autostart entry (survives reboot)
├── .local/bin/
│   ├── toggle-visor-terminal.bash
│   ├── toggle-hotkey-window.bash
│   ├── snap-window.bash
│   └── snap-window-user.bash
└── etc/keyd/
    └── default.conf.in  ← keyd config template (@HOME@/@USER@/@UID@ placeholders;
                             rendered to /etc/keyd/default.conf by install.sh/reload.sh)
```

---

## Legacy: xcape + autokey

The original implementation here (2015–2026) used `xcape` + `autokey` instead
of `keyd`. I've copied these configs out from my private WIP dotfiles, to
provide an example of how to get TouchCursor bindings under Linux / X11.
`autokey` is a heavyweight, aging Python daemon that regularly pegged CPU at
100%, requiring a manual restart — see "Background — why keyd?" above for the
full evaluation that replaced it.

Use `xcape` to:

* Set the CapsLock to emit an `esc` on tap, and act as a control
  key modifier when held
* Set the Space key to emit a `space` on tap, and act as the hyper
  key modifier when held

Use `autokey` to map all the `Hyper_L` combos

You'll need some sort of init script, like this:

```
  killall xcape

  # Clear changes
  setxkbmap

  # TouchCursor-ish
  #   Based on the example from: https://github.com/alols/xcape

  # Map an unused modifier's keysym to the spacebar's keycode and make it a
  # control modifier. It needs to be an existing key so that emacs won't
  # spazz out when you press it. Hyper_L is a good candidate.
  spare_modifier="Hyper_L"
  xmodmap -e "keycode 65 = $spare_modifier"
# xmodmap -e "remove mod4 = $spare_modifier" # hyper_l is mod4 by default
  # This is in example, but breaks things here :/

  # Map space to an unused keycode (to keep it around for xcape to use).
  xmodmap -e "keycode any = space"

  # Finally use xcape to cause the space bar to generate a space when tapped.
  xcape -t 500 -e "Control_L=Escape;$spare_modifier=space"
  # Play around w/ the -t value, to your liking
```

---

## Resources

- [keyd](https://github.com/rvaiya/keyd)
- [TouchCursor (original)](https://touchcursor.sourceforge.net/)
- [xcape](https://github.com/alols/xcape)
- [autokey](https://github.com/autokey-py3/autokey)
- [viktorvan/TouchCursor](https://github.com/viktorvan/TouchCursor)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/)
- My [Karabiner-Elements](https://ke-complex-modifications.pqrs.org/?rule=json%2Fpersonal_jeebak.json) complex modification ([src](https://github.com/pqrs-org/KE-complex_modifications/blob/main/src/json/personal_jeebak.json.js))
- Old (pre-Sierra **only**) [Karabiner](https://github.com/jeebak/dotfiles/tree/master/karabiner) customizations
- My [Windows](https://github.com/jeebak/keyboard-windows) configs
- [Example Layout](http://www.keyboard-layout-editor.com/#/gists/55f3e3c9149d23cbae5f8ac559627d0f)
- [ArchWiki: Input remap utilities](https://wiki.archlinux.org/title/Input_remap_utilities)
