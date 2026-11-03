@echo off
setlocal enabledelayedexpansion
:: ============================================================
:: OpenRUS - Master Installer
:: Создаёт загрузочный USB с OpenRUS
:: Требуется: Windows ISO + этот скрипт
:: ============================================================
title OpenRUS - Flash Drive Creator
color 0B

echo.
echo  ██████╗ ██████╗ ███████╗███╗   ██╗██████╗ ██╗   ██╗███████╗
echo  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██║   ██║██╔════╝
echo  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║███████╗
echo  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║╚════██║
echo  ╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝███████║
echo   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
echo.
echo              МАСТЕР СОЗДАНИЯ ЗАГРУЗОЧНОЙ ФЛЕШКИ
echo               OpenRUS Installation Media Creator
echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo  [!] ОШИБКА: Запустите от имени Администратора!
    echo  [*] Нажмите ПКМ на файл → "Запуск от имени администратора"
    pause
    exit /b 1
)

:: Check for wimlib or use built-in dism
where dism >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [!] DISM не найден! Убедитесь что Windows установлена корректно.
    pause
    exit /b 1
)

:: ─── STEP 1: Select Windows ISO ─────────────────────────────
echo.
echo  ШАГ 1: Укажите путь к вашему Windows 7 ISO файлу
echo  ─────────────────────────────────────────────────
echo  Пример: D:\Windows_7_x64.iso
echo  (или перетащите ISO файл в это окно и нажмите Enter)
echo.
set /p "ISO_PATH=  ISO путь: "
set ISO_PATH=%ISO_PATH:"=%

if not exist "%ISO_PATH%" (
    echo [!] Файл не найден: %ISO_PATH%
    pause
    exit /b 1
)
echo [OK] ISO найден: %ISO_PATH%

:: ─── STEP 2: Select USB Drive ────────────────────────────────
echo.
echo  ШАГ 2: Вставьте флешку (минимум 8 ГБ) и выберите её букву
echo  ──────────────────────────────────────────────────────────
echo.
echo  Доступные диски:
wmic logicaldisk get DeviceID,Size,Description,DriveType 2>nul | findstr /v "^$"
echo.
set /p "USB_DRIVE=  Буква диска флешки (например E): "
set "USB_DRIVE=%USB_DRIVE%:"
set "USB_DRIVE=%USB_DRIVE::=%"
set "USB_PATH=%USB_DRIVE%:"

if not exist "%USB_PATH%\" (
    echo [!] Диск %USB_PATH% не найден!
    pause
    exit /b 1
)

echo.
echo  ┌─────────────────────────────────────────────────────┐
echo  │  ВНИМАНИЕ! ВСЕ ДАННЫЕ НА %USB_PATH% БУДУТ УДАЛЕНЫ! │
echo  │  Убедитесь что вы выбрали правильную флешку!        │
echo  └─────────────────────────────────────────────────────┘
echo.
choice /c YN /m "Продолжить форматирование %USB_PATH%? (Y=ДА, N=Нет)"
if %errorLevel% EQU 2 (echo Отменено. & pause & exit /b 0)

:: ─── STEP 3: Format USB ──────────────────────────────────────
echo.
echo  ШАГ 3: Форматируем флешку под MBR/NTFS для Rufus DD-режима
echo  ─────────────────────────────────────────────────────────
echo [*] Форматирование %USB_PATH%...

(
echo select disk %USB_DRIVE%
echo clean
echo create partition primary
echo select partition 1
echo active
echo format fs=ntfs label="OpenRUS" quick
echo assign letter=%USB_DRIVE%
echo exit
) | diskpart >nul 2>&1

echo [OK] Флешка отформатирована!

:: ─── STEP 4: Mount ISO and copy ──────────────────────────────
echo.
echo  ШАГ 4: Монтируем ISO и копируем файлы...
echo  ────────────────────────────────────────

:: Mount ISO using PowerShell
powershell -Command "Mount-DiskImage -ImagePath '%ISO_PATH%'" >nul 2>&1
timeout /t 3 >nul

:: Find mount letter
for /f "tokens=1" %%A in ('powershell -Command "(Get-DiskImage -ImagePath '%ISO_PATH%' | Get-Volume).DriveLetter"') do (
    set "MOUNT_DRIVE=%%A"
)

if not defined MOUNT_DRIVE (
    echo [!] Не удалось смонтировать ISO. Попробуйте вручную через Rufus.
    goto :manual_instructions
)

echo [*] ISO смонтирован как %MOUNT_DRIVE%:
echo [*] Копируем файлы Windows на флешку...

xcopy /E /H /Y "%MOUNT_DRIVE%:\*" "%USB_PATH%\" 2>nul
if %errorLevel% NEQ 0 (
    echo [!] Ошибка копирования. Попробуйте Rufus.
    goto :unmount
)

:: ─── STEP 5: Copy OpenRUS files ──────────────────────────────
echo.
echo  ШАГ 5: Добавляем файлы OpenRUS на флешку...
echo  ─────────────────────────────────────────────

:: Create OpenRUS folder on USB
if not exist "%USB_PATH%\OpenRUS" mkdir "%USB_PATH%\OpenRUS"

:: Copy OpenRUS scripts and assets
xcopy /E /Y /I "C:\OpenRUS\*" "%USB_PATH%\OpenRUS\" >nul 2>&1

:: Copy autounattend.xml to root (Windows reads it automatically!)
if exist "C:\OpenRUS\installer\autounattend.xml" (
    copy /Y "C:\OpenRUS\installer\autounattend.xml" "%USB_PATH%\autounattend.xml" >nul
    echo [OK] autounattend.xml скопирован в корень флешки!
    echo [*] Установка Windows будет автоматической!
) else (
    echo [!] autounattend.xml не найден. Запустите generate_unattend.bat сначала.
)

:: Make bootable
echo [*] Делаем флешку загрузочной...
bootsect /nt60 %USB_PATH% /mbr >nul 2>&1

:unmount
:: Unmount ISO
powershell -Command "Dismount-DiskImage -ImagePath '%ISO_PATH%'" >nul 2>&1

echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  [OK] Флешка OpenRUS готова! 
echo.
echo  Инструкция по загрузке:
echo  1. Вставьте флешку в ноутбук
echo  2. При включении нажмите F2/F12/Del для Boot Menu
echo  3. Выберите вашу флешку
echo  4. Установка OpenRUS начнётся автоматически!
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
pause
exit /b 0

:manual_instructions
echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  Инструкция для Rufus (ручной метод):
echo  1. Скачайте Rufus: https://rufus.ie
echo  2. Вставьте флешку (8+ ГБ)
echo  3. Выберите ваш Windows 7 ISO
echo  4. Схема раздела: MBR
echo  5. Файловая система: NTFS
echo  6. Нажмите START
echo  7. После записи скопируйте папку OpenRUS на флешку
echo  8. Скопируйте autounattend.xml в корень флешки
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
pause
