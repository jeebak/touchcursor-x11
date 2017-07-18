if not store.has_key("initializedTouchCursor"):
  cmd = 'ps aux | grep xcape | grep Hyper_R'
  output = system.exec_command(cmd, getOutput=True)

  if not 'Hyper_R' in output:
    # dialog.info_dialog("TouchCursor", "Initializing")
    cmd = '/usr/bin/xcape -t 500 -e Control_L Escape Hyper_R space'
    output = system.exec_command(cmd, getOutput=True)

  store.set_value("initializedTouchCursor", 1)