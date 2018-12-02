engine.run_script('init-touchcursor')
# winTitle = window.get_active_title()
winClass = window.get_active_class()

# dialog.info_dialog("Window information", "Active window information:\\nTitle: '%s'\\nClass: '%s'" % (winTitle, winClass))

if winClass == 'xfce4-terminal.Xfce4-terminal':
  keyboard.send_keys('<shift>+<ctrl>+q')
else:
  keyboard.send_keys('<ctrl>+w')
