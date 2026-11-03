@echo off
:: ============================================================
:: OpenRUS - Hardware Monitor
:: Shows CPU, RAM, GPU, Disk info in real time
:: ============================================================
title OpenRUS - System Monitor
color 0B

:loop
cls
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║          OpenRUS - SYSTEM MONITOR v1.0                  ║
echo  ╠══════════════════════════════════════════════════════════╣

:: --- CPU ---
echo  ║  [CPU]                                                   ║
for /f "skip=1 delims=" %%A in ('wmic cpu get Name /value 2^>nul') do (
    for /f "tokens=2 delims==" %%B in ("%%A") do (
        if not "%%B"=="" echo  ║  Модель: %%B
    )
)
for /f "skip=1 tokens=1" %%A in ('wmic cpu get LoadPercentage 2^>nul') do (
    if not "%%A"=="" echo  ║  Загрузка: %%A%%
)
for /f "skip=1 tokens=1" %%A in ('wmic cpu get NumberOfCores 2^>nul') do (
    if not "%%A"=="" echo  ║  Ядра: %%A
)
for /f "skip=1 tokens=1" %%A in ('wmic cpu get MaxClockSpeed 2^>nul') do (
    if not "%%A"=="" echo  ║  Частота (макс): %%A МГц
)

echo  ╠══════════════════════════════════════════════════════════╣

:: --- RAM ---
echo  ║  [ОПЕРАТИВНАЯ ПАМЯТЬ]                                    ║
for /f "skip=1 tokens=1" %%A in ('wmic OS get FreePhysicalMemory 2^>nul') do (
    if not "%%A"=="" (
        set /a FREE_MB=%%A/1024
        echo  ║  Свободно: !FREE_MB! МБ
    )
)
for /f "skip=1 tokens=1" %%A in ('wmic OS get TotalVisibleMemorySize 2^>nul') do (
    if not "%%A"=="" (
        set /a TOTAL_MB=%%A/1024
        echo  ║  Всего: !TOTAL_MB! МБ
    )
)

echo  ╠══════════════════════════════════════════════════════════╣

:: --- GPU ---
echo  ║  [ВИДЕОКАРТА]                                            ║
for /f "skip=1 delims=" %%A in ('wmic path win32_videocontroller get Name /value 2^>nul') do (
    for /f "tokens=2 delims==" %%B in ("%%A") do (
        if not "%%B"=="" echo  ║  %%B
    )
)
for /f "skip=1 tokens=1" %%A in ('wmic path win32_videocontroller get AdapterRAM 2^>nul') do (
    if not "%%A"=="" (
        set /a VRAM_MB=%%A/1048576
        if !VRAM_MB! GTR 0 echo  ║  VRAM: !VRAM_MB! МБ
    )
)

echo  ╠══════════════════════════════════════════════════════════╣

:: --- Disks ---
echo  ║  [ДИСКИ]                                                 ║
for /f "skip=1 tokens=1,2,3" %%A in ('wmic logicaldisk get DeviceID^,FreeSpace^,Size 2^>nul') do (
    if not "%%A"=="" if not "%%B"=="" if not "%%C"=="" (
        set /a FREE_GB=%%B/1073741824
        set /a TOTAL_GB=%%C/1073741824
        if !TOTAL_GB! GTR 0 echo  ║  %%A  Свободно: !FREE_GB! ГБ / Всего: !TOTAL_GB! ГБ
    )
)

echo  ╠══════════════════════════════════════════════════════════╣

:: --- Network ---
echo  ║  [СЕТЬ]                                                  ║
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| find "IPv4"') do (
    set IP=%%A
    set IP=!IP: =!
    echo  ║  IP: !IP!
)
netsh wlan show interfaces 2>nul | find "SSID" | find /v "BSSID" >nul 2>&1
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims=:" %%A in ('netsh wlan show interfaces ^| find "SSID" ^| find /v "BSSID"') do (
        echo  ║  WiFi: %%A
    )
) else (
    echo  ║  WiFi: Не подключен
)

echo  ║                                                          ║
echo  ║  [OpenRUS] Обновление каждые 5 сек. Ctrl+C для выхода   ║
echo  ╚══════════════════════════════════════════════════════════╝

timeout /t 5 /nobreak >nul
goto :loop
