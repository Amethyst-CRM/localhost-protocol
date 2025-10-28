# Check logs
journalctl -t localfile-handler

# Check registration
xdg-mime query default x-scheme-handler/localfile

# Re-register
xdg-mime default localfile-handler.desktop x-scheme-handler/localfile
