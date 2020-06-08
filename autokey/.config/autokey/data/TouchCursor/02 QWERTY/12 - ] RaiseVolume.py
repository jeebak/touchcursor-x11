engine.run_script('init-touchcursor')

# https://github.com/autokey/autokey/issues/127
#   Can't simulate multimedia keys #127
# xmodmap -pk | grep XF86AudioRaiseVolume
#   123         0x1008ff13 (XF86AudioRaiseVolume)       0x0000 (NoSymbol)       0x1008ff13 (XF86AudioRaiseVolume)
# keyboard.send_keys("<code123>")

# https://unix.stackexchange.com/questions/342554/how-to-enable-my-keyboards-volume-keys-in-xfce/342555
# xfce4-pulseaudio-plugin
# pactl -- set-sink-volume 0 +5% # raise volume by each 10% (more than 100% possible, might distort the sound) 
# pactl -- set-sink-volume 0 -5% # reduce volume by each 10% 
# pactl -- set-sink-mute 0 toggle # mute/unmutes audio 
system.exec_command("pactl -- set-sink-volume @DEFAULT_SINK@ +5%", getOutput=False)