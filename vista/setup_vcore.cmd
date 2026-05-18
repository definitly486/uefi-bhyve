@echo off
:: -----------------------------
:: Скрипт для Windows PE
:: Создает пользователя vcore и настраивает авто-вход
:: -----------------------------

:: Установочный диск Vista
set INSTALL_DIR=C:\

echo Создаем пользователя vcore с паролем 639639...
net user vcore 639639 /add /y
net localgroup Administrators vcore /add

echo Настраиваем авто-вход для пользователя vcore...

:: Смонтируем ветку реестра SOFTWARE оффлайн
reg load HKLM\OFFSOFT "%INSTALL_DIR%Windows\System32\Config\SOFTWARE"

:: Включаем авто-вход
reg add "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d vcore /f
reg add "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d 639639 /f

:: Дополнительно можно задать имя компьютера
reg add "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner /t REG_SZ /d vcore /f
reg add "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization /t REG_SZ /d Vista /f

:: Размонтируем ветку реестра
reg unload HKLM\OFFSOFT

echo Пользователь vcore создан и авто-вход настроен.
pause