@echo off
:: ============================================================
:: OpenRUS - Auto Driver Installer
:: Downloads and installs drivers automatically on first boot
:: Uses Snappy Driver Installer Origin (SDIO) - free & offline
:: ============================================================
title OpenRUS - Auto Driver Setup
color 0B

echo.
echo  [OpenRUS] Автоматическая установка драйверов
echo  ================================================
echo.

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [ERROR] Нужны права Администратора!
    pause
    exit /b 1
)

set "DRIVERS_DIR=C:\OpenRUS\drivers"
set "SDIO_DIR=%DRIVERS_DIR%\SDIO"
set "SDIO_EXE=%SDIO_DIR%\SDIO_auto.exe"

:: --- Check internet connection ---
echo [*] Проверяем подключение к интернету...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Интернет подключен. Загружаем свежие драйверы...
    call :download_sdio
) else (
    echo [!] Интернет недоступен. Используем локальные драйверы...
    call :use_local_drivers
)
goto :end

:download_sdio
echo [*] Скачиваем Snappy Driver Installer Origin...
if not exist "%SDIO_DIR%" mkdir "%SDIO_DIR%"

:: Download SDIO
powershell -Command "& {
    $url = 'https://www.snappy-driver-installer.org/downloads/SDIO_auto.exe'
    $out = '%SDIO_DIR%\SDIO_auto.exe'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
        Write-Host '[OK] SDIO загружен'
    } catch {
        Write-Host '[!] Ошибка загрузки SDIO: ' + $_.Exception.Message
    }
}" 2>nul

if exist "%SDIO_EXE%" (
    echo [*] Запускаем автоустановку драйверов...
    echo [*] Это может занять 5-20 минут. Пожалуйста, подождите.
    start /wait "%SDIO_EXE%" -autoinstall -reboot
    echo [OK] Драйверы установлены!
) else (
    echo [!] SDIO не найден. Пробуем альтернативный метод...
    call :install_basic_drivers
)
goto :eof

:use_local_drivers
echo [*] Поиск локальных драйверов в %DRIVERS_DIR%\local...
if exist "%DRIVERS_DIR%\local" (
    echo [*] Устанавливаем драйверы из локального хранилища...
    pnputil /add-driver "%DRIVERS_DIR%\local\*.inf" /subdirs /install
    echo [OK] Локальные драйверы установлены!
) else (
    echo [!] Локальные драйверы не найдены.
    call :install_basic_drivers
)
goto :eof

:install_basic_drivers
echo [*] Устанавливаем базовые компоненты Windows...

:: Enable Windows Update for driver detection
sc config wuauserv start= auto >nul
net start wuauserv >nul 2>&1

:: Network drivers via Windows Update
echo [*] Запускаем поиск драйверов через Windows Update...
wuauclt /detectnow

:: Direct device scan
echo [*] Сканируем устройства без драйверов...
pnputil /scan-devices 2>nul

echo [*] WiFi и Bluetooth: проверяем состояние...
netsh wlan show interfaces 2>nul | find "SSID" >nul
if %errorLevel% EQU 0 (
    echo [OK] WiFi адаптер найден и работает!
) else (
    echo [!] WiFi требует установки драйверов - подключитесь к интернету через кабель для авто-загрузки
)
goto :eof

:end
echo.
echo  ================================================
echo  [OpenRUS] Установка драйверов завершена!
echo  Рекомендуется перезагрузка.
echo  ================================================
echo.
choice /c YN /m "Перезагрузить сейчас? (Y=Да, N=Нет)"
if %errorLevel% EQU 1 shutdown /r /t 5 /c "OpenRUS: перезагрузка после установки драйверов"
