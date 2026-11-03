@echo off
:: ============================================================
:: OpenRUS - WiFi & Bluetooth Manager
:: Quick connect to WiFi, manage Bluetooth
:: ============================================================
title OpenRUS - Network Manager
color 0B

:menu
cls
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║         OpenRUS - СЕТЕВОЙ МЕНЕДЖЕР                     ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║  1. Показать доступные WiFi сети                        ║
echo  ║  2. Подключиться к WiFi                                 ║
echo  ║  3. Отключиться от WiFi                                 ║
echo  ║  4. Bluetooth - показать устройства                     ║
echo  ║  5. Включить/выключить WiFi                             ║
echo  ║  6. Включить/выключить Bluetooth                        ║
echo  ║  7. Показать сетевую статистику                         ║
echo  ║  8. Выход                                               ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
set /p "CHOICE=  Выберите действие (1-8): "

if "%CHOICE%"=="1" goto :wifi_scan
if "%CHOICE%"=="2" goto :wifi_connect
if "%CHOICE%"=="3" goto :wifi_disconnect
if "%CHOICE%"=="4" goto :bluetooth_devices
if "%CHOICE%"=="5" goto :wifi_toggle
if "%CHOICE%"=="6" goto :bt_toggle
if "%CHOICE%"=="7" goto :net_stats
if "%CHOICE%"=="8" exit /b 0
goto :menu

:wifi_scan
echo.
echo [*] Доступные WiFi сети:
echo.
netsh wlan show networks mode=bssid 2>nul | findstr /C:"SSID" /C:"Сигнал" /C:"Signal" /C:"Тип" /C:"Проверка"
if %errorLevel% NEQ 0 (
    echo [!] WiFi адаптер не найден или отключен.
    echo [*] Попробуйте: 1) Включить WiFi кнопкой на ноутбуке
    echo                 2) Установить драйверы (скрипт 02_auto_drivers.bat)
)
echo.
pause
goto :menu

:wifi_connect
echo.
set /p "SSID=Введите название сети (SSID): "
set /p "PASS=Введите пароль (Enter если нет): "

if "%PASS%"=="" (
    netsh wlan connect name="%SSID%"
) else (
    :: Create profile
    set "PROFILE_XML=%TEMP%\wifi_profile.xml"
    (
    echo ^<?xml version="1.0"?^>
    echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
    echo   ^<name^>%SSID%^</name^>
    echo   ^<SSIDConfig^>^<SSID^>^<name^>%SSID%^</name^>^</SSID^>^</SSIDConfig^>
    echo   ^<connectionType^>ESS^</connectionType^>
    echo   ^<connectionMode^>auto^</connectionMode^>
    echo   ^<MSM^>^<security^>
    echo     ^<authEncryption^>^<authentication^>WPA2PSK^</authentication^>^<encryption^>AES^</encryption^>^</authEncryption^>
    echo     ^<sharedKey^>^<keyType^>passPhrase^</keyType^>^<protected^>false^</protected^>^<keyMaterial^>%PASS%^</keyMaterial^>^</sharedKey^>
    echo   ^</security^>^</MSM^>
    echo ^</WLANProfile^>
    ) > "%PROFILE_XML%"
    netsh wlan add profile filename="%PROFILE_XML%" >nul
    netsh wlan connect name="%SSID%"
)
echo.
echo [*] Попытка подключения к "%SSID%"...
timeout /t 5 >nul
netsh wlan show interfaces | find "SSID"
pause
goto :menu

:wifi_disconnect
netsh wlan disconnect
echo [OK] Отключено от WiFi.
pause
goto :menu

:bluetooth_devices
echo.
echo [*] Bluetooth устройства:
echo.
powershell -Command "& {
    try {
        \$bt = [Windows.Devices.Enumeration.DeviceInformation, Windows, ContentType=WindowsRuntime]
        Write-Host 'Bluetooth доступен в системе'
        Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Select-Object Status, FriendlyName | Format-Table -AutoSize
    } catch {
        Write-Host 'Используем альтернативный метод...'
        Get-PnpDevice | Where-Object {$_.Class -eq 'Bluetooth'} | Select-Object Status,FriendlyName | Format-Table
    }
}" 2>nul
echo.
echo [*] Для сопряжения Bluetooth: Панель управления → Устройства → Bluetooth
pause
goto :menu

:wifi_toggle
for /f "tokens=*" %%A in ('netsh interface show interface ^| findstr /i "wireless\|wi-fi\|wlan"') do (
    echo %%A
)
echo.
echo [*] Переключаем WiFi...
netsh interface set interface "Wi-Fi" admin=enabled 2>nul
netsh interface set interface "Wireless Network Connection" admin=enabled 2>nul
echo [OK] Попробовали включить WiFi адаптер.
pause
goto :menu

:bt_toggle
echo [*] Bluetooth сервис...
sc query bthserv | find "RUNNING" >nul
if %errorLevel% EQU 0 (
    net stop bthserv >nul 2>&1
    echo [OK] Bluetooth выключен.
) else (
    net start bthserv >nul 2>&1
    echo [OK] Bluetooth включён.
)
pause
goto :menu

:net_stats
echo.
echo [*] Статистика сети:
echo.
ipconfig /all
echo.
netstat -e
pause
goto :menu
