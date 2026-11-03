@echo off
title OpenRUS OS - Desktop Shell Launcher
echo ========================================================
echo         Запуск оболочки OpenRUS (Cyberpunk Edition)
echo ========================================================
echo.
echo Открытие графического интерфейса по твоему эскизу...
echo.

start "" "%~dp0ui\index.html"

echo [OK] Оболочка OpenRUS успешно запущена в твоем браузере!
timeout /t 3 >nul
exit
