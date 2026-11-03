@echo off
:: ============================================================
:: OpenRUS - Theme Applicator
:: Applies cyberpunk dark theme to Windows 7 64-bit
:: ============================================================
title OpenRUS Theme Installer
color 0B

echo.
echo  ██████╗ ██████╗ ███████╗███╗   ██╗██████╗ ██╗   ██╗███████╗
echo  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██║   ██║██╔════╝
echo  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║███████╗
echo  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║╚════██║
echo  ╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝███████║
echo   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
echo.
echo                    [ OpenRUS v1.0 - Theme Setup ]
echo.

:: --- Check Administrator ---
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [ERROR] Запустите от имени Администратора!
    pause
    exit /b 1
)

echo [*] Применяем киберпанк тему OpenRUS...

:: --- Registry: Dark Taskbar and Window Colors ---
echo [*] Настройка цветов интерфейса...

:: Desktop wallpaper (will be set by asset installer)
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\OpenRUS\wallpapers\cyberpunk_bear.jpg" /f >nul 2>&1

:: Window colors - dark cyberpunk
reg add "HKCU\Control Panel\Colors" /v "Window" /t REG_SZ /d "10 10 26" /f >nul
reg add "HKCU\Control Panel\Colors" /v "WindowText" /t REG_SZ /d "0 255 255" /f >nul
reg add "HKCU\Control Panel\Colors" /v "ActiveTitle" /t REG_SZ /d "0 0 20" /f >nul
reg add "HKCU\Control Panel\Colors" /v "InactiveTitle" /t REG_SZ /d "5 5 15" /f >nul
reg add "HKCU\Control Panel\Colors" /v "TitleText" /t REG_SZ /d "0 255 255" /f >nul
reg add "HKCU\Control Panel\Colors" /v "ButtonFace" /t REG_SZ /d "15 15 35" /f >nul
reg add "HKCU\Control Panel\Colors" /v "ButtonText" /t REG_SZ /d "0 255 255" /f >nul
reg add "HKCU\Control Panel\Colors" /v "Highlight" /t REG_SZ /d "191 0 255" /f >nul
reg add "HKCU\Control Panel\Colors" /v "HighlightText" /t REG_SZ /d "255 255 255" /f >nul
reg add "HKCU\Control Panel\Colors" /v "Desktop" /t REG_SZ /d "5 5 20" /f >nul
reg add "HKCU\Control Panel\Colors" /v "Background" /t REG_SZ /d "5 5 20" /f >nul
reg add "HKCU\Control Panel\Colors" /v "Menu" /t REG_SZ /d "10 10 26" /f >nul
reg add "HKCU\Control Panel\Colors" /v "MenuText" /t REG_SZ /d "0 255 255" /f >nul

:: --- Taskbar ---
echo [*] Настройка панели задач...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarSmallIcons" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowInfoTip" /t REG_DWORD /d 1 /f >nul

:: --- Start Menu customization ---
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_ShowRun" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_ShowSearch" /t REG_DWORD /d 1 /f >nul

:: --- Disable unnecessary services ---
echo [*] Отключаем лишние сервисы для производительности...
sc config "Fax" start= disabled >nul 2>&1
sc config "TabletInputService" start= disabled >nul 2>&1
sc config "WSearch" start= auto >nul 2>&1

:: --- Performance settings ---
echo [*] Настройка производительности...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f >nul

:: Custom visual effects - keep only essentials for cyberpunk look
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 1 /f >nul

:: --- System name branding ---
echo [*] Брендирование системы OpenRUS...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName" /t REG_SZ /d "OpenRUS 1.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "OpenRUS Project" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOwner" /t REG_SZ /d "OpenRUS User" /f >nul 2>&1

:: OEM Info
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Manufacturer" /t REG_SZ /d "OpenRUS Project" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Model" /t REG_SZ /d "OpenRUS 1.0 Cyberpunk Edition" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "SupportURL" /t REG_SZ /d "https://github.com/OpenRUS/openrus-updates" /f >nul 2>&1
if exist "C:\OpenRUS\assets\logo.bmp" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Logo" /t REG_SZ /d "C:\OpenRUS\assets\logo.bmp" /f >nul 2>&1
)

:: --- Apply wallpaper immediately ---
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

echo.
echo [OK] Тема OpenRUS применена!
echo [*] Перезагрузите Explorer для полного эффекта.
echo.
timeout /t 3 >nul
