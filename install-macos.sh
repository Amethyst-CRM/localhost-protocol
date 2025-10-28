cat > install-macos.sh << 'EOF'
#!/bin/bash

# Remove old installation
rm -rf ~/Applications/LocalFileHandler.app
rm -rf ~/Applications/ProtocolHandler

# Create handler script first
mkdir -p ~/Applications/ProtocolHandler
mkdir -p ~/Library/Logs

cat > ~/Applications/ProtocolHandler/handler.sh << 'HANDLER'
#!/bin/bash
URL="$1"
echo "$(date): Raw input: '$URL'" >> ~/Library/Logs/localfile-handler.log

# Remove protocol prefix
URL="${URL#localfile://}"
URL="${URL#localfile:}"
URL="${URL#//}"
URL="${URL#open?}"

echo "$(date): After prefix removal: '$URL'" >> ~/Library/Logs/localfile-handler.log

if [[ "$URL" =~ path=([^&]+) ]]; then
    PATH_TO_OPEN="${BASH_REMATCH[1]}"
    PATH_TO_OPEN=$(printf '%b' "${PATH_TO_OPEN//%/\\x}")
    PATH_TO_OPEN="${PATH_TO_OPEN/#\~/$HOME}"
    
    echo "$(date): Final path: '$PATH_TO_OPEN'" >> ~/Library/Logs/localfile-handler.log
    
    if [ -e "$PATH_TO_OPEN" ]; then
        open "$PATH_TO_OPEN"
        echo "$(date): Successfully opened $PATH_TO_OPEN" >> ~/Library/Logs/localfile-handler.log
    else
        echo "$(date): Path not found: $PATH_TO_OPEN" >> ~/Library/Logs/localfile-handler.log
    fi
else
    echo "$(date): Could not parse URL: '$URL'" >> ~/Library/Logs/localfile-handler.log
fi
HANDLER

chmod +x ~/Applications/ProtocolHandler/handler.sh

# Create the AppleScript
cat > /tmp/LocalFileHandler.scpt << 'APPLESCRIPT'
on open location theURL
    do shell script "~/Applications/ProtocolHandler/handler.sh " & quoted form of theURL & " &"
end open location
APPLESCRIPT

# Compile to app bundle
osacompile -o ~/Applications/LocalFileHandler.app /tmp/LocalFileHandler.scpt

# Update the Info.plist in the compiled app
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Local File Protocol'" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string 'Viewer'" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string 'localfile'" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null

/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string 'com.local.filehandler'" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier 'com.local.filehandler'" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null

/usr/libexec/PlistBuddy -c "Add :LSBackgroundOnly bool true" ~/Applications/LocalFileHandler.app/Contents/Info.plist 2>/dev/null

# Clean up temp file
rm /tmp/LocalFileHandler.scpt

# Force re-registration
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Register the app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -v -f ~/Applications/LocalFileHandler.app

echo ""
echo "Installation complete!"
echo ""
echo "Waiting 3 seconds for system to register..."
sleep 3

echo ""
echo "Now run this command to test:"
echo "open 'localfile://open?path=/Users/$USER/Downloads'"
EOF

chmod +x install-macos.sh
bash ./install-macos.sh
