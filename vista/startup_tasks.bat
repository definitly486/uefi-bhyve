@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion

:: Укажите путь к скрипту, который нужно добавить в автозагрузку
set "SCRIPT_SOURCE=D:\create_vcore.bat"

:: Поиск системного диска с Windows Vista
set "target_drive="
for %%d in (C D E F G H I J K) do (
    if exist "%%d:\Windows\System32" (
        set "target_drive=%%d"
        goto :found
    )
)

:found
if "%target_drive%"=="" (
    echo [ERROR] Диск с установленной Windows Vista не найден.
    pause
    exit /b
)

echo [INFO] Найден системный диск: %target_drive%:

:: Поиск первого пользователя (кроме Public и Default)
set "USER_NAME="
for /f "tokens=*" %%u in ('dir /b /ad "%target_drive%:\Users"') do (
    if /i not "%%u"=="Public" if /i not "%%u"=="Default" (
        set "USER_NAME=%%u"
        goto :userfound
    )
)

:userfound
if "%USER_NAME%"=="" (
    echo [ERROR] Не удалось определить пользователя.
    pause
    exit /b
)

echo [INFO] Определен пользователь: %USER_NAME%

:: Создание папки Startup, если её нет
set "STARTUP_PATH=%target_drive%:\Users\%USER_NAME%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%STARTUP_PATH%" (
    echo [INFO] Создаю папку автозагрузки...
    mkdir "%STARTUP_PATH%"
)

:: Копирование скрипта в автозагрузку
copy /y "%SCRIPT_SOURCE%" "%STARTUP_PATH%\"

if %errorlevel% equ 0 (
    echo [SUCCESS] Скрипт успешно скопирован в автозагрузку.
) else (
    echo [ERROR] Не удалось скопировать скрипт.
)

pause