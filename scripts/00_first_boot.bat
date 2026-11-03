@echo off
:: ============================================================
:: OpenRUS - First Boot Setup (OOBE)
:: Runs on first login after installation
:: ============================================================
title OpenRUS - Первый запуск
color 0B

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║   ██████╗ ██████╗ ███████╗███╗   ██╗██████╗ ██╗   ██╗███████╗ ║
echo  ║                                                              ║
echo  ║          Добро пожаловать в OpenRUS 1.0                     ║
echo  ║          Cyberpunk Edition                                   ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  Система настраивается... Пожалуйста, подождите.
echo.

:: Mark first boot complete
reg add "HKLM\SOFTWARE\OpenRUS" /v "FirstBoot" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\OpenRUS" /v "Version" /t REG_SZ /d "1.0.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\OpenRUS" /v "InstallDate" /t REG_SZ /d "%DATE%" /f >nul 2>&1

echo [1/6] Применяем тему OpenRUS Cyberpunk...
call "C:\OpenRUS\scripts\01_apply_theme.bat" >nul 2>&1
echo [OK]

echo [2/6] Настройка сети и WiFi...
:: Enable WLAN AutoConfig
sc config Wlansvc start= auto >nul 2>&1
net start Wlansvc >nul 2>&1
:: Enable Bluetooth
sc config bthserv start= auto >nul 2>&1
net start bthserv >nul 2>&1
echo [OK]

echo [3/6] Устанавливаем драйверы...
call "C:\OpenRUS\scripts\02_auto_drivers.bat" >nul 2>&1
echo [OK]

echo [4/6] Настройка центра обновлений GitHub...
call "C:\OpenRUS\updater\register_autoupdate.bat" >nul 2>&1
echo [OK]

echo [5/6] Создаём ярлыки на рабочем столе...

:: System Monitor shortcut
powershell -Command "& {
    \$WshShell = New-Object -comObject WScript.Shell
    \$Shortcut = \$WshShell.CreateShortcut('\$env:PUBLIC\Desktop\OpenRUS Monitor.lnk')
    \$Shortcut.TargetPath = 'C:\OpenRUS\scripts\03_hardware_monitor.bat'
    \$Shortcut.Description = 'OpenRUS System Monitor'
    \$Shortcut.Save()
}" >nul 2>&1

:: Update Center shortcut
powershell -Command "& {
    \$WshShell = New-Object -comObject WScript.Shell
    \$Shortcut = \$WshShell.CreateShortcut('\$env:PUBLIC\Desktop\OpenRUS Updates.lnk')
    \$Shortcut.TargetPath = 'C:\OpenRUS\updater\OpenRUS_Update.bat'
    \$Shortcut.Description = 'OpenRUS Update Center'
    \$Shortcut.Save()
}" >nul 2>&1

echo [OK]

echo [6/6] Финальная настройка...
:: Set version file
echo 1.0.0>"C:\OpenRUS\version.txt"

:: Remove from startup (ran once)
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "OpenRUS_OOBE" /f >nul 2>&1

echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  [OK] OpenRUS настроен и готов к работе!
echo.
echo  На рабочем столе появились:
echo  • OpenRUS Monitor    - мониторинг железа (CPU/RAM/GPU/диски)
echo  • OpenRUS Updates    - центр обновлений через GitHub
echo.
echo  WiFi и Bluetooth: используйте системный трей (правый угол)
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

choice /c YN /m "Перезагрузить для полного применения настроек? (Y=Да, N=Нет)"
if %errorLevel% EQU 1 shutdown /r /t 5 /c "OpenRUS: первичная настройка завершена"
