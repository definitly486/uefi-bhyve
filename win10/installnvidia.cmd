@echo off
setlocal enabledelayedexpansion

echo =====================================
echo NVIDIA driver install script
echo =====================================

:: Папка с драйверами (рядом со скриптом)
set DRIVER_DIR=%~dp0NVIDIA

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

if %errorlevel% neq 0 (
    echo WARNING: Some drivers were not installed (possibly no GPU detected yet).
) else (
    echo NVIDIA drivers installed successfully.
)

echo.
echo Done.
echo If GPU is not installed yet, drivers will activate automatically after detection.
echo.


:: 1. Включаем встроенную учетную запись Гостя
net user Гость /active:yes

:: 2. Разрешаем использовать пустые пароли для сетевых подключений
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LimitBlankPasswordUse" /t REG_DWORD /d 0 /f

:: 3. Разрешаем небезопасный гостевой вход в SMB (критично для Windows 10/11)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "RestrictNullSessAccess" /t REG_DWORD /d 0 /f

:: 4. Включаем общий доступ без парольной защиты
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "everyoneincludesanonymous" /t REG_DWORD /d 1 /f

:: 5. Перезапускаем сетевую службу для применения настроек
net stop LanmanServer /y
net start LanmanServer

pause
endlocal