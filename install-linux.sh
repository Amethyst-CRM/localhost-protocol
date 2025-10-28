sudo mkdir -p /opt/localfile-handler

sudo tee /opt/localfile-handler/handler.sh > /dev/null << 'EOF'
#!/bin/bash
# Linux Protocol Handler Script

URL="$1"
URL="${URL#localfile://}"

if [[ "$URL" =~ path=([^&]+) ]]; then
    PATH_TO_OPEN="${BASH_REMATCH[1]}"
    
    # URL decode
    PATH_TO_OPEN=$(printf '%b' "${PATH_TO_OPEN//%/\\x}")
    
    # Expand tilde
    PATH_TO_OPEN="${PATH_TO_OPEN/#\~/$HOME}"
    
    if [ -e "$PATH_TO_OPEN" ]; then
        # Use xdg-open to open in default file manager
        xdg-open "$PATH_TO_OPEN" 2>/dev/null
        logger "localfile-handler: Opened $PATH_TO_OPEN"
    else
        logger "localfile-handler: Path not found: $PATH_TO_OPEN"
    fi
else
    logger "localfile-handler: Invalid URL: $URL"
fi
EOF

sudo chmod +x /opt/localfile-handler/handler.sh

sudo tee /usr/share/applications/localfile-handler.desktop > /dev/null << 'EOF'
[Desktop Entry]
Type=Application
Name=Local File Protocol Handler
Exec=/opt/localfile-handler/handler.sh %u
StartupNotify=false
MimeType=x-scheme-handler/localfile;
NoDisplay=true
Terminal=false
EOF

sudo update-desktop-database

xdg-mime default localfile-handler.desktop x-scheme-handler/localfile

xdg-open "localfile://open?path=$HOME/Downloads"
