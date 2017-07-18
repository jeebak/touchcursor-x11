engine.run_script('init-touchcursor')
cmd_cur_desktop = "wmctrl -d | grep '*' | awk '{ print $1; }'"
cmd_desktop_count = "wmctrl -d | wc -l"

cur_desktop   = system.exec_command(cmd_cur_desktop,   getOutput=True)
desktop_count = system.exec_command(cmd_desktop_count, getOutput=True)

move_to = int((int(cur_desktop) - 1) % int(desktop_count))

window.switch_desktop(move_to)
