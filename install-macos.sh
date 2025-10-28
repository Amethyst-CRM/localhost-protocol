mkdir -p ~/Applications/ProtocolHandler

cat > ~/Applications/ProtocolHandler/handler.sh << 'EOF'
#!/bin/bash
# macOS Protocol Handler Script

URL="$1"
URL="${URL#localfile://}"

if [[ "$URL" =~ path=([^&]+) ]]; then
    PATH_TO_OPEN="${BASH_REMATCH[1]}"
    PATH_TO_OPEN=$(printf '%b' "${PATH_TO_OPEN//%/\\x}")
    PATH_TO_OPEN="${PATH_TO_OPEN/#\~/$HOME}"
    
    if [ -e "$PATH_TO_OPEN" ]; then
        open "$PATH_TO_OPEN"
        echo "$(date): Opened $PATH_TO_OPEN" >> ~/Library/Logs/localfile-handler.log
    else
        echo "$(date): Path not found: $PATH_TO_OPEN" >> ~/Library/Logs/localfile-handler.log
    fi
else
    echo "$(date): Invalid URL: $URL" >> ~/Library/Logs/localfile-handler.log
fi
EOF

chmod +x ~/Applications/ProtocolHandler/handler.sh

mkdir -p ~/Applications/LocalFileHandler.app/Contents/MacOS

cat > ~/Applications/LocalFileHandler.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>LocalFileHandler</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.filehandler</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Local File Protocol</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>localfile</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

cat > ~/Applications/LocalFileHandler.app/Contents/MacOS/launcher << 'EOF'
#!/bin/bash
~/Applications/ProtocolHandler/handler.sh "$1" &
EOF

chmod +x ~/Applications/LocalFileHandler.app/Contents/MacOS/launcher

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/LocalFileHandler.app

open ~/Applications/LocalFileHandler.app

open "localfile://open?path=$HOME/Downloads"
