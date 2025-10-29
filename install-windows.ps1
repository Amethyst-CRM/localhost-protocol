# Windows Local File Protocol Handler Installer
# Run as Administrator

# Create the handler directory
$handlerDir = "C:\Program Files\LocalFileHandler"
New-Item -ItemType Directory -Force -Path $handlerDir | Out-Null

# Create PowerShell handler script (more reliable than batch)
$handlerScript = @'
param($url)

# Log function
function Write-Log {
    param($message)
    $logPath = "$env:USERPROFILE\localfile-handler.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp : $message" | Out-File -FilePath $logPath -Append
}

Write-Log "Raw URL: $url"

# Remove protocol prefix
$url = $url -replace '^localfile://', ''
$url = $url -replace '^localfile:', ''
$url = $url -replace '^//', ''
$url = $url -replace '^open\?', ''

Write-Log "After prefix removal: $url"

# Extract path parameter
if ($url -match 'path=([^&]+)') {
    $pathEncoded = $matches[1]
    
    # URL decode
    Add-Type -AssemblyName System.Web
    $pathDecoded = [System.Web.HttpUtility]::UrlDecode($pathEncoded)
    
    # Handle forward slashes
    $pathDecoded = $pathDecoded -replace '/', '\'
    
    # Expand environment variables
    $pathExpanded = [System.Environment]::ExpandEnvironmentVariables($pathDecoded)
    
    Write-Log "Decoded path: $pathExpanded"
    
    # Check if path exists
    if (Test-Path $pathExpanded) {
        # Open in Explorer
        Start-Process explorer.exe $pathExpanded
        Write-Log "Successfully opened: $pathExpanded"
    } else {
        Write-Log "ERROR: Path not found: $pathExpanded"
        # Show error to user
        [System.Windows.Forms.MessageBox]::Show(
            "Path not found: $pathExpanded",
            "Local File Handler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
} else {
    Write-Log "ERROR: Could not parse URL: $url"
}
'@

$handlerScript | Out-File -FilePath "$handlerDir\handler.ps1" -Encoding UTF8 -Force

# Create wrapper batch file that calls PowerShell
$batchWrapper = @'
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Program Files\LocalFileHandler\handler.ps1" %*
'@

$batchWrapper | Out-File -FilePath "$handlerDir\handler.bat" -Encoding ASCII -Force

# Ensure HKCR drive exists
if (-not (Get-PSDrive HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}

# Create registry entries
Write-Host "Creating registry entries..."

New-Item -Path "HKCR:\localfile" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\localfile" -Name "(Default)" -Value "URL:Local File Protocol"
New-ItemProperty -Path "HKCR:\localfile" -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null

New-Item -Path "HKCR:\localfile\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\localfile\DefaultIcon" -Name "(Default)" -Value "explorer.exe,0"

New-Item -Path "HKCR:\localfile\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKCR:\localfile\shell\open\command" -Name "(Default)" -Value "`"$handlerDir\handler.bat`" `"%1`""

Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Testing the handler..."
Start-Sleep -Seconds 2

# Test with Downloads folder
$testPath = "$env:USERPROFILE\Downloads"
$testUrl = "localfile://open?path=$testPath"

Write-Host "Opening: $testUrl" -ForegroundColor Cyan
Start-Process $testUrl

Write-Host ""
Write-Host "If your Downloads folder opened, the handler is working!" -ForegroundColor Green
Write-Host "Check the log at: $env:USERPROFILE\localfile-handler.log" -ForegroundColor Yellow
Write-Host ""
Write-Host "Example usage:"
Write-Host "  localfile://open?path=C:\Users\YourName\Documents"
Write-Host "  localfile://open?path=%USERPROFILE%\Downloads"
