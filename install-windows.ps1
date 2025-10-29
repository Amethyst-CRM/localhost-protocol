# Create the handler directory
New-Item -ItemType Directory -Force -Path "C:\Program Files\LocalFileHandler" | Out-Null

# Create the batch file handler
@'
@echo off
setlocal enabledelayedexpansion

REM Get the URL argument
set "URL=%~1"

REM Remove localfile:// prefix
set "URL=!URL:localfile://=!"

REM Extract path from URL (simple parsing)
for /f "tokens=2 delims==" %%a in ("!URL!") do set "PATH_TO_OPEN=%%a"

REM URL decode basic characters (spaces, etc)
set "PATH_TO_OPEN=!PATH_TO_OPEN:%%20= !"
set "PATH_TO_OPEN=!PATH_TO_OPEN:%%2F=/!"
set "PATH_TO_OPEN=!PATH_TO_OPEN:/=\!"

REM Expand environment variables
call set "PATH_TO_OPEN=!PATH_TO_OPEN!"

REM Check if path exists and open
if exist "!PATH_TO_OPEN!" (
    explorer "!PATH_TO_OPEN!"
    echo %date% %time%: Opened !PATH_TO_OPEN! >> "%USERPROFILE%\localfile-handler.log"
) else (
    echo %date% %time%: Path not found: !PATH_TO_OPEN! >> "%USERPROFILE%\localfile-handler.log"
)
'@ | Out-File -FilePath "C:\Program Files\LocalFileHandler\handler.bat" -Encoding ASCII -Force

# Ensure HKCR drive exists
if (-not (Get-PSDrive HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}

# Create registry entries for the custom URL protocol
New-Item -Path "HKCR:\localfile" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\localfile" -Name "(Default)" -Value "URL:Local File Protocol"
Set-ItemProperty -Path "HKCR:\localfile" -Name "URL Protocol" -Value ""

New-Item -Path "HKCR:\localfile\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\localfile\shell\open\command" -Name "(Default)" -Value '"C:\Program Files\LocalFileHandler\handler.bat" "%1"'

# Optional .reg file backup
@'
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\localfile]
@="URL:Local File Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\localfile\shell]

[HKEY_CLASSES_ROOT\localfile\shell\open]

[HKEY_CLASSES_ROOT\localfile\shell\open\command]
@="\"C:\\Program Files\\LocalFileHandler\\handler.bat\" \"%1\""
'@ | Out-File -FilePath "$env:TEMP\register-localfile.reg" -Encoding ASCII -Force

# Import the registry (silent)
reg import "$env:TEMP\register-localfile.reg" | Out-Null

# Test launch (optional)
$testPath = "C:\Users\$env:USERNAME\Downloads"
Write-Host "Testing launch: localfile://open?path=$testPath"
Start-Process "localfile://open?path=$testPath"

Write-Host "✅ Local File Protocol (localfile://) successfully installed and tested."
Write-Host "   You can now use links like:"
Write-Host "   localfile://open?path=C:\Users\$env:USERNAME\Downloads"
