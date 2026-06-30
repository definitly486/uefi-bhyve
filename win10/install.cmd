@echo off
setlocal enabledelayedexpansion

:: Проверка и автоматический запрос прав Администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo =====================================
echo NVIDIA driver install script
echo =====================================

:: Папка с драйверами (рядом со скриптом)
set DRIVER_DIR=%~dp0NVIDIA
set DRIVER_KVM_DIR=%~dp0NetKVM

echo Checking driver folder: %DRIVER_DIR%

if not exist "%DRIVER_DIR%" (
    echo ERROR: Driver folder not found!
    echo Expected: %DRIVER_DIR%
    pause
    exit /b 1
)

echo.
echo Adding NVIDIA drivers to Driver Store...
echo.

pnputil /add-driver "%DRIVER_DIR%\nv_dispi.inf" /subdirs

if %errorlevel% neq 0 (
    echo.
    echo WARNING: pnputil returned error code %errorlevel%
    echo Drivers may not have been added correctly.
) else (
    echo.
    echo Drivers successfully added to Driver Store.
)

echo.
echo Trying to install drivers on available hardware...
echo.



pnputil /add-driver "%DRIVER_DIR%\nv_dispi.inf" /subdirs /install
pnputil /add-driver "%DRIVER_KVM_DIR%\netkvm.inf" /subdirs /install

rd /s /q %DRIVER_DIR%
rd /s /q %DRIVER_KVM_DIR%
robocopy "C:\app\profile.tar.xz" "C:\app\Firefox Setup 152.0.2\core\profile" /E /R:1 /W:1
mkdir "C:\Users\vcore\Documents\WindowsPowerShell"
copy "C:\Microsoft.PowerShell_profile.ps1" "C:\Users\vcore\Documents\WindowsPowerShell\"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
powershell -NoProfile -ExecutionPolicy Bypass -Command ". $PROFILE"

netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
net use Z: \\192.168.8.101\Share


::создание ссылок

mklink "%userprofile%\Desktop\portable.bat" "C:\app\Firefox Setup 152.0.2\core\portable.bat"
mklink "%userprofile%\Desktop\start_vpn.cmd" "C:\app\AmneziaVPN_4.8.19.0_x64\start_vpn.cmd"
mklink "%userprofile%\Desktop\AmneziaVPN.exe" "C:\app\AmneziaVPN_4.8.19.0_x64\AmneziaVPN.exe"
mklink "%userprofile%\Desktop\FreeTube.exe" "C:\app\freetube-0.24.1-beta-win-x64-portable\FreeTube.exe"
mklink "%userprofile%\Desktop\GTweak.exe" "C:\app\GTweak.exe"

if %errorlevel% neq 0 (
    echo WARNING: Some drivers were not installed (possibly no GPU detected yet).
) else (
    echo NVIDIA drivers installed successfully.
)

echo.
echo =====================================
echo Enabling Remote Desktop (RDP)...
echo =====================================

:: 1. Включение RDP в реестре
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul

:: 2. Разрешение RDP в Брандмауэре Windows (для всех языковых версий ОС)
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="удаленный рабочий стол" new enable=Yes >nul 2>&1

:: 3. Настройка автозапуска и старт службы Терминалов
sc config TermService start= auto >nul
sc start TermService >nul

echo Remote Desktop has been enabled.



echo.
echo Done.
echo If GPU is not installed yet, drivers will activate automatically after detection.
echo.

pause
endlocal
