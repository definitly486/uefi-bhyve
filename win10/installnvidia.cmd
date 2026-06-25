@echo off
setlocal enabledelayedexpansion

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

if %errorlevel% neq 0 (
    echo WARNING: Some drivers were not installed (possibly no GPU detected yet).
) else (
    echo NVIDIA drivers installed successfully.
)




echo.
echo Done.
echo If GPU is not installed yet, drivers will activate automatically after detection.
echo.



pause
endlocal