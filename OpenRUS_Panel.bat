@echo off
:: ============================================================
:: OpenRUS - Main Menu / Control Panel
:: Central hub for all OpenRUS features
:: ============================================================
title OpenRUS Control Panel
color 0B

:menu
cls
echo.
echo  ██████╗ ██████╗ ███████╗███╗   ██╗██████╗ ██╗   ██╗███████╗
echo  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██║   ██║██╔════╝
echo  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║███████╗
echo  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║╚════██║
echo  ╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝███████║
echo   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
echo.
echo                    ПАНЕЛЬ УПРАВЛЕНИЯ v1.0
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

:: Show current status
for /f "skip=1 tokens=1" %%A in ('wmic cpu get LoadPercentage 2^>nul') do (
    if not "%%A"=="" set "CPU_LOAD=%%A"
)
for /f "skip=1 tokens=1" %%A in ('wmic OS get FreePhysicalMemory 2^>nul') do (
    if not "%%A"=="" set /a "FREE_RAM=%%A/1024"
)

echo  Статус системы: CPU: %CPU_LOAD%% ^| RAM свободно: %FREE_RAM% МБ
echo.
echo  ┌─────────────────────────────────────────────────────────┐
echo  │                      МЕНЮ                              │
echo  ├─────────────────────────────────────────────────────────┤
echo  │  [1] Мониторинг железа (CPU/RAM/GPU/Диски)             │
echo  │  [2] Сеть и WiFi менеджер                              │
echo  │  [3] Установка драйверов                               │
echo  │  [4] Центр обновлений GitHub                           │
echo  │  [5] Применить тему OpenRUS                            │
echo  │  [6] Генерировать обои Cyberpunk                       │
echo  │  [7] Информация о системе                              │
echo  │  [8] Создать загрузочную флешку                        │
echo  │  [9] Выход                                             │
echo  └─────────────────────────────────────────────────────────┘
echo.
set /p "CHOICE=  Выберите (1-9): "

if "%CHOICE%"=="1" start "Hardware Monitor" "C:\OpenRUS\scripts\03_hardware_monitor.bat" & goto :menu
if "%CHOICE%"=="2" call "C:\OpenRUS\scripts\04_network_manager.bat" & goto :menu
if "%CHOICE%"=="3" call "C:\OpenRUS\scripts\02_auto_drivers.bat" & goto :menu
if "%CHOICE%"=="4" call "C:\OpenRUS\updater\OpenRUS_Update.bat" & goto :menu
if "%CHOICE%"=="5" call "C:\OpenRUS\scripts\01_apply_theme.bat" & goto :menu
if "%CHOICE%"=="6" powershell -ExecutionPolicy Bypass -File "C:\OpenRUS\wallpapers\generate_wallpaper.ps1" & goto :menu
if "%CHOICE%"=="7" goto :sysinfo
if "%CHOICE%"=="8" call "C:\OpenRUS\installer\CREATE_OPENRUS_USB.bat" & goto :menu
if "%CHOICE%"=="9" exit /b 0
goto :menu

:sysinfo
cls
echo.
echo  [OpenRUS] Информация о системе
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Type" /C:"Total Physical" /C:"Processor" /C:"BIOS" /C:"System Model" /C:"System Manufacturer"
echo.
echo  OpenRUS версия:
if exist "C:\OpenRUS\version.txt" type "C:\OpenRUS\version.txt"
echo.
pause
goto :menu
