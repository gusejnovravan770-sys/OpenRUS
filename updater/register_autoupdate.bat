:: ============================================================
:: OpenRUS - Auto Update Scheduler
:: Registers update check at Windows startup
:: ============================================================
@echo off
title OpenRUS - Register Auto-Update
net session >nul 2>&1
if %errorLevel% NEQ 0 (echo Нужны права администратора! & pause & exit /b 1)

echo [*] Регистрируем автообновление OpenRUS...

:: Register in Task Scheduler (runs update check at login)
schtasks /create /tn "OpenRUS Update Check" /tr "C:\OpenRUS\updater\OpenRUS_Update_Silent.bat" /sc onlogon /rl highest /f >nul 2>&1

:: Also add to registry for startup
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenRUS_Updater" /t REG_SZ /d "C:\OpenRUS\updater\OpenRUS_Update_Silent.bat" /f >nul 2>&1

echo [OK] Автообновление зарегистрировано!
echo [*] OpenRUS будет проверять обновления при каждом входе в систему.
pause
