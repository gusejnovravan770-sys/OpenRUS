; ============================================================
; OpenRUS Installer - Answer File (unattend.xml generator)
; This script generates a Windows 7 unattend.xml for 
; automated OpenRUS installation
; ============================================================

@echo off
title OpenRUS Installer Generator
color 0B

echo [*] Создаём файл автоматической установки OpenRUS...

set "OUTPUT=C:\OpenRUS\installer\autounattend.xml"
if not exist "C:\OpenRUS\installer" mkdir "C:\OpenRUS\installer"

(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.
echo   ^<!-- =============================== -->
echo   ^<!-- OpenRUS - Automated Installer  -->
echo   ^<!-- =============================== -->
echo.
echo   ^<settings pass="windowsPE"^>
echo     ^<component name="Microsoft-Windows-International-Core-WinPE"
echo       processorArchitecture="amd64"
echo       publicKeyToken="31bf3856ad364e35"
echo       language="neutral"
echo       versionScope="nonSxS"
echo       xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
echo       ^<SetupUILanguage^>
echo         ^<UILanguage^>ru-RU^</UILanguage^>
echo       ^</SetupUILanguage^>
echo       ^<InputLocale^>ru-RU^</InputLocale^>
echo       ^<SystemLocale^>ru-RU^</SystemLocale^>
echo       ^<UILanguage^>ru-RU^</UILanguage^>
echo       ^<UserLocale^>ru-RU^</UserLocale^>
echo     ^</component^>
echo.
echo     ^<component name="Microsoft-Windows-Setup"
echo       processorArchitecture="amd64"
echo       publicKeyToken="31bf3856ad364e35"
echo       language="neutral"
echo       versionScope="nonSxS"
echo       xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
echo       ^<DiskConfiguration^>
echo         ^<Disk wcm:action="add"^>
echo           ^<CreatePartitions^>
echo             ^<CreatePartition wcm:action="add"^>
echo               ^<Order^>1^</Order^>
echo               ^<Type^>Primary^</Type^>
echo               ^<Size^>100^</Size^>
echo             ^</CreatePartition^>
echo             ^<CreatePartition wcm:action="add"^>
echo               ^<Order^>2^</Order^>
echo               ^<Type^>Primary^</Type^>
echo               ^<Extend^>true^</Extend^>
echo             ^</CreatePartition^>
echo           ^</CreatePartitions^>
echo           ^<ModifyPartitions^>
echo             ^<ModifyPartition wcm:action="add"^>
echo               ^<Order^>1^</Order^>
echo               ^<PartitionID^>1^</PartitionID^>
echo               ^<Label^>System^</Label^>
echo               ^<Format^>NTFS^</Format^>
echo               ^<Active^>true^</Active^>
echo             ^</ModifyPartition^>
echo             ^<ModifyPartition wcm:action="add"^>
echo               ^<Order^>2^</Order^>
echo               ^<PartitionID^>2^</PartitionID^>
echo               ^<Label^>OpenRUS^</Label^>
echo               ^<Format^>NTFS^</Format^>
echo               ^<Letter^>C^</Letter^>
echo             ^</ModifyPartition^>
echo           ^</ModifyPartitions^>
echo           ^<DiskID^>0^</DiskID^>
echo           ^<WillWipeDisk^>true^</WillWipeDisk^>
echo         ^</Disk^>
echo       ^</DiskConfiguration^>
echo       ^<ImageInstall^>
echo         ^<OSImage^>
echo           ^<InstallTo^>
echo             ^<DiskID^>0^</DiskID^>
echo             ^<PartitionID^>2^</PartitionID^>
echo           ^</InstallTo^>
echo         ^</OSImage^>
echo       ^</ImageInstall^>
echo     ^</component^>
echo   ^</settings^>
echo.
echo   ^<settings pass="specialize"^>
echo     ^<component name="Microsoft-Windows-Shell-Setup"
echo       processorArchitecture="amd64"
echo       publicKeyToken="31bf3856ad364e35"
echo       language="neutral"
echo       versionScope="nonSxS"
echo       xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
echo       ^<ComputerName^>OpenRUS-PC^</ComputerName^>
echo       ^<RegisteredOrganization^>OpenRUS Project^</RegisteredOrganization^>
echo       ^<RegisteredOwner^>OpenRUS User^</RegisteredOwner^>
echo       ^<TimeZone^>Russian Standard Time^</TimeZone^>
echo     ^</component^>
echo.
echo     ^<component name="Microsoft-Windows-NetworkDiagnosticsFramework"
echo       processorArchitecture="amd64"
echo       publicKeyToken="31bf3856ad364e35"
echo       language="neutral"
echo       versionScope="nonSxS"^>
echo       ^<EnabledScenarios^>All^</EnabledScenarios^>
echo     ^</component^>
echo   ^</settings^>
echo.
echo   ^<settings pass="oobeSystem"^>
echo     ^<component name="Microsoft-Windows-Shell-Setup"
echo       processorArchitecture="amd64"
echo       publicKeyToken="31bf3856ad364e35"
echo       language="neutral"
echo       versionScope="nonSxS"
echo       xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
echo       ^<OOBE^>
echo         ^<HideEULAPage^>true^</HideEULAPage^>
echo         ^<HideLocalAccountScreen^>false^</HideLocalAccountScreen^>
echo         ^<HideOEMRegistrationScreen^>true^</HideOEMRegistrationScreen^>
echo         ^<HideOnlineAccountScreens^>true^</HideOnlineAccountScreens^>
echo         ^<HideWirelessSetupInOOBE^>false^</HideWirelessSetupInOOBE^>
echo         ^<SkipMachineOOBE^>false^</SkipMachineOOBE^>
echo         ^<SkipUserOOBE^>false^</SkipUserOOBE^>
echo         ^<NetworkLocation^>Home^</NetworkLocation^>
echo       ^</OOBE^>
echo       ^<FirstLogonCommands^>
echo         ^<SynchronousCommand wcm:action="add"^>
echo           ^<Order^>1^</Order^>
echo           ^<CommandLine^>cmd /c xcopy /E /I /Y "D:\OpenRUS" "C:\OpenRUS\"^</CommandLine^>
echo           ^<Description^>Copy OpenRUS files^</Description^>
echo         ^</SynchronousCommand^>
echo         ^<SynchronousCommand wcm:action="add"^>
echo           ^<Order^>2^</Order^>
echo           ^<CommandLine^>cmd /c "C:\OpenRUS\scripts\01_apply_theme.bat"^</CommandLine^>
echo           ^<Description^>Apply OpenRUS Theme^</Description^>
echo         ^</SynchronousCommand^>
echo         ^<SynchronousCommand wcm:action="add"^>
echo           ^<Order^>3^</Order^>
echo           ^<CommandLine^>cmd /c "C:\OpenRUS\scripts\02_auto_drivers.bat"^</CommandLine^>
echo           ^<Description^>Install Drivers^</Description^>
echo         ^</SynchronousCommand^>
echo         ^<SynchronousCommand wcm:action="add"^>
echo           ^<Order^>4^</Order^>
echo           ^<CommandLine^>cmd /c "C:\OpenRUS\updater\register_autoupdate.bat"^</CommandLine^>
echo           ^<Description^>Register OpenRUS Auto-Update^</Description^>
echo         ^</SynchronousCommand^>
echo       ^</FirstLogonCommands^>
echo     ^</component^>
echo   ^</settings^>
echo ^</unattend^>
) > "%OUTPUT%"

echo [OK] autounattend.xml создан: %OUTPUT%
echo.
echo  Этот файл нужно положить в КОРЕНЬ флешки рядом с ISO.
echo  Windows автоматически найдёт его при установке.
pause
