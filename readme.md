# Localfile protocol helper
## Installation
### Windows
Open power shell as admin
```bash
irm https://raw.githubusercontent.com/Amethyst-CRM/localhost-protocol/main/install-windows.ps1 | iex
```
### MacOS
```bash
curl -fsSL https://raw.githubusercontent.com/Amethyst-CRM/localhost-protocol/main/install-macos.sh | bash
```
### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/Amethyst-CRM/localhost-protocol/main/install-linux.sh | bash
```
<br/>

## Uninstall
### Windows
```bash
Remove-Item "HKCR:\localfile" -Recurse -Force
Remove-Item "C:\Program Files\LocalFileHandler" -Recurse -Force
Remove-Item "$env:USERPROFILE\localfile-handler.log"
```
### MacOS
```bash
rm -rf ~/Applications/LocalFileHandler.app
rm -rf ~/Applications/ProtocolHandler
rm ~/Library/Logs/localfile-handler.log
```
### Linux
```bash
sudo rm /opt/localfile-handler/handler.sh
sudo rm /usr/share/applications/localfile-handler.desktop
sudo update-desktop-database
```
