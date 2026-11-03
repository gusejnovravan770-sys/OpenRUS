@echo off
:: Silent update check - runs in background at startup
set "VERSION_FILE=C:\OpenRUS\version.txt"
set "LOG=C:\OpenRUS\logs\update.log"

if not exist "C:\OpenRUS\logs" mkdir "C:\OpenRUS\logs"

ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% NEQ 0 exit /b 0

powershell -WindowStyle Hidden -Command "& {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $response = Invoke-RestMethod -Uri 'https://api.github.com/repos/OpenRUS/openrus-updates/releases/latest' -UseBasicParsing
        $latest = $response.tag_name
        $current = Get-Content 'C:\OpenRUS\version.txt' -ErrorAction SilentlyContinue
        if ($latest -ne $current) {
            Add-Type -AssemblyName System.Windows.Forms
            $result = [System.Windows.Forms.MessageBox]::Show(
                'Доступно обновление OpenRUS: ' + $latest + [Environment]::NewLine + 'Установить сейчас?',
                'OpenRUS - Центр обновлений',
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-Process 'C:\OpenRUS\updater\OpenRUS_Update.bat' -Verb RunAs
            }
        }
    } catch {}
}" 2>nul
