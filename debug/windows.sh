# Check logs
Get-Content "$env:USERPROFILE\localfile-handler.log" -Tail 10

# Check registry
Get-ItemProperty "HKCR:\localfile\shell\open\command"

# Test handler directly
& "C:\Program Files\LocalFileHandler\handler.bat" "localfile://open?path=C:\Users"
