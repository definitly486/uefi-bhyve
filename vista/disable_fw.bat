@echo off
chcp 1251 >nul
setlocal enabledelayedexpansion

:: Поиск системного диска с Windows Vista
set "target_drive="
for %%d in (C D E F G H I J K) do (
    if exist "%%d:\Windows\System32\config\SYSTEM" (
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

:: Загрузка куста реестра SYSTEM во временную ветку OfflineSystem
reg load HKLM\OfflineSystem "%target_drive%:\Windows\System32\config\SYSTEM"
if %errorlevel% neq 0 (
    echo [ERROR] Не удалось загрузить куст реестра.
    pause
    exit /b
)

:: Отключение службы брандмауэра (MpsSvc) через изменение параметра Start на 4
reg add "HKLM\OfflineSystem\ControlSet001\Services\MpsSvc" /v Start /t REG_DWORD /d 4 /f

:: Включение удаленного рабочего стола
reg add "HKLM\OfflineSystem\ControlSet001\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

:: Настройка службы Терминального сервера на автоматический запуск (опционально)
reg add "HKLM\OfflineSystem\ControlSet001\Services\TermService" /v Start /t REG_DWORD /d 2 /f


:: 3. Внесение твиков для работы RDP без пароля
echo Применение настроек сети и RDP...
reg add "HKLM\VistaSys\ControlSet001\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f
reg add "HKLM\VistaSys\ControlSet001\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
reg add "HKLM\VistaSys\ControlSet001\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f
reg add "HKLM\VistaSys\ControlSet001\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 0 /f




:: ================================================
:: Отключение UAC
:: ================================================
echo [INFO] Отключение UAC...
:: EnableLUA = 0 отключает UAC
reg add "HKLM\OfflineSystem\ControlSet001\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f >nul
reg add "HKLM\OfflineSystem\ControlSet001\Control\UAC" /v EnableLUA /t REG_DWORD /d 0 /f
reg add "HKLM\OfflineSystem\ControlSet001\Control\UAC" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
reg add "HKLM\OfflineSystem\ControlSet001\Control\UAC" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f

:: Выгрузка куста реестра для сохранения изменений на диск
reg unload HKLM\OfflineSystem

echo [SUCCESS] Брандмауэр отключен, удаленный рабочий стол включен, UAC полностью отключен.
echo [INFO] Перезагрузите ПК для применения изменений.
pause