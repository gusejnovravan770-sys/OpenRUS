@echo off
setlocal enabledelayedexpansion
:: ============================================================
:: OpenRUS - GitHub Update System
:: Checks for updates from GitHub and applies them silently
:: Repository: https://github.com/OpenRUS/openrus-updates
:: ============================================================
title OpenRUS - Update Center
color 0B

set "GITHUB_USER=OpenRUS"
set "GITHUB_REPO=openrus-updates"
set "GITHUB_API=https://api.github.com/repos/%GITHUB_USER%/%GITHUB_REPO%/releases/latest"
set "INSTALL_DIR=C:\OpenRUS"
set "UPDATE_TEMP=%TEMP%\OpenRUS_Update"
set "VERSION_FILE=%INSTALL_DIR%\version.txt"
set "CURRENT_VER=1.0.0"

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║         OpenRUS - ЦЕНТР ОБНОВЛЕНИЙ                      ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║  Репозиторий: github.com/OpenRUS/openrus-updates         ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: Read current version
if exist "%VERSION_FILE%" (
    set /p CURRENT_VER=<"%VERSION_FILE%"
)
echo [*] Текущая версия OpenRUS: %CURRENT_VER%

:: Check internet
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [!] Нет подключения к интернету. Обновление невозможно.
    goto :no_internet
)

echo [*] Проверяем обновления на GitHub...

:: Get latest release info via PowerShell
powershell -Command "& {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $api = '%GITHUB_API%'
        $response = Invoke-RestMethod -Uri $api -UseBasicParsing
        $version = $response.tag_name
        $download = ($response.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1).browser_download_url
        $body = $response.body
        
        Write-Host ('LATEST_VERSION=' + $version)
        Write-Host ('DOWNLOAD_URL=' + $download)
        Write-Host ('CHANGELOG=' + $body.Replace([Environment]::NewLine, ' | '))
    } catch {
        Write-Host 'LATEST_VERSION=ERROR'
        Write-Host ('ERROR_MSG=' + $_.Exception.Message)
    }
}" > "%TEMP%\openrus_update_check.txt" 2>nul

:: Parse results
set "LATEST_VER=ERROR"
set "DOWNLOAD_URL="
for /f "tokens=1,2 delims==" %%A in ('type "%TEMP%\openrus_update_check.txt"') do (
    if "%%A"=="LATEST_VERSION" set "LATEST_VER=%%B"
    if "%%A"=="DOWNLOAD_URL" set "DOWNLOAD_URL=%%B"
    if "%%A"=="CHANGELOG" set "CHANGELOG=%%B"
)

if "%LATEST_VER%"=="ERROR" (
    echo [!] Ошибка проверки обновлений. Попробуйте позже.
    goto :end
)

echo [*] Последняя версия на GitHub: %LATEST_VER%

if "%LATEST_VER%"=="%CURRENT_VER%" (
    echo [OK] У вас установлена последняя версия OpenRUS!
    goto :end
)

echo.
echo  ┌─────────────────────────────────────────────────────┐
echo  │  Доступно обновление: %CURRENT_VER% → %LATEST_VER%  
echo  │  Журнал изменений: %CHANGELOG%
echo  └─────────────────────────────────────────────────────┘
echo.

choice /c YN /m "Установить обновление OpenRUS %LATEST_VER%? (Y=Да, N=Нет)"
if %errorLevel% EQU 2 goto :end

echo [*] Загружаем обновление...
if not exist "%UPDATE_TEMP%" mkdir "%UPDATE_TEMP%"

powershell -Command "& {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%UPDATE_TEMP%\update.zip' -UseBasicParsing
        Expand-Archive -Path '%UPDATE_TEMP%\update.zip' -DestinationPath '%UPDATE_TEMP%\extracted' -Force
        Write-Host '[OK] Архив распакован'
    } catch {
        Write-Host '[ERROR] ' + $_.Exception.Message
        exit 1
    }
}"

if not exist "%UPDATE_TEMP%\extracted" (
    echo [ERROR] Ошибка загрузки обновления!
    goto :end
)

:: Run update installer if exists
if exist "%UPDATE_TEMP%\extracted\install_update.bat" (
    echo [*] Применяем обновление...
    call "%UPDATE_TEMP%\extracted\install_update.bat"
) else (
    echo [*] Копируем файлы обновления...
    xcopy /E /Y /I "%UPDATE_TEMP%\extracted\*" "%INSTALL_DIR%\" >nul 2>&1
)

:: Update version file
echo %LATEST_VER%>"%VERSION_FILE%"

echo.
echo [OK] OpenRUS обновлён до версии %LATEST_VER%!
echo [*] Изменения вступят в силу после перезагрузки.

choice /c YN /m "Перезагрузить сейчас? (Y=Да, N=Нет)"
if %errorLevel% EQU 1 shutdown /r /t 10 /c "OpenRUS Update: перезагрузка для применения обновлений"
goto :end

:no_internet
echo [*] Подключитесь к интернету и запустите обновление снова.
echo [*] Центр обновлений: C:\OpenRUS\updater\OpenRUS_Update.bat

:end
echo.
echo [*] Следующая проверка: при следующем запуске системы
pause
