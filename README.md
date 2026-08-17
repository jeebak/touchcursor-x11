# TouchCursor for Linux / X11

_"There's no place like Home Row..."_

I've copied these configs out from my private WIP dotfiles, to provide an
example of how to get TouchCursor bindings under Linux / X11.

* http://martin-stone.github.io/touchcursor/
* https://github.com/alols/xcape
* https://github.com/autokey-py3/autokey
* https://github.com/viktorvan/TouchCursor
* Old (pre-sierra **only**) [Karabiner](https://github.com/jeebak/dotfiles/tree/master/karabiner) customizations
* My [Karabiner-Elements](https://pqrs.org/osx/karabiner/complex_modifications/#personal_jeebak) complex modification
* My [Windows](https://github.com/jeebak/keyboard-windows) configs
* [Example Layout](http://www.keyboard-layout-editor.com/#/gists/55f3e3c9149d23cbae5f8ac559627d0f)

**Note (2026):** this repo is archived. `autokey` (used below for the Hyper
combos) is a heavyweight, aging Python daemon — there are much better
options now for implementing TouchCursor-style layers on Linux:

* [touchcursor-linux](https://github.com/donniebreve/touchcursor-linux) —
  a purpose-built TouchCursor port for Linux, runs as a user-level systemd
  service, works under both Xorg and Wayland
* [keyd](https://github.com/rvaiya/keyd) — a general-purpose key-remapping
  daemon (C, kernel-level via evdev/uinput, sub-1ms latency) with native
  layers, key overloading, and per-application layer switching; what I've
  since switched to
* [kmonad](https://github.com/kmonad/kmonad) — a general-purpose advanced
  keyboard customization tool (Haskell), cross-platform (Linux/Windows/macOS)
* [kanata](https://github.com/jtroo/kanata) — a general-purpose keyboard
  remapper (Rust) inspired by kmonad, cross-platform (Linux/macOS/Windows)

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
