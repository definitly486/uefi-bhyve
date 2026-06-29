@echo off
chcp 1251 >nul
:: ===========================================================
:: Полностью автоматизированная установка Windows с USB
:: + Копирование BCD на раздел Vista
:: ===========================================================

echo ВНИМАНИЕ! ВСЕ ДАННЫЕ НА ДИСКЕ 0 БУДУТ УДАЛЕНЫ!


:: -------------------------------
:: Шаг 1: Создаем разделы через diskpart
:: -------------------------------
echo Создание разделов на диске 0...
(
echo select disk 0
echo clean
echo convert gpt
echo create partition efi size=100
echo format quick fs=fat32 label="System"
echo assign letter=W
echo create partition primary
echo format quick fs=ntfs label="Windows"
echo assign letter=C
echo exit
) | diskpart

:: -------------------------------
:: Шаг 2: Разворачиваем образ Windows
:: -------------------------------
cd /d D:\sources

if exist install.wim (
    set IMAGE=install.wim
) else if exist install.esd (
    set IMAGE=install.esd
) else (
    echo Не найден ни install.wim, ни install.esd!
    pause
    exit /b 1
)

echo Разворачивание образа %IMAGE% на C:\
dism /apply-image /imagefile:D:\sources\%IMAGE% /index:1 /applydir:C:\

if %errorlevel% neq 0 (
    echo DISM не сработал, пробуем GImageX...
    D:\support\tools\gimagex\x64\gimagex.exe /apply D:\sources\%IMAGE% 1 C:\
)


:: Копируем MAS_AIO.cmd

copy D:\MAS_AIO.cmd C:\


:: Создаем необходимую папку
md "C:\Windows\Panther" 2>nul

:: Копируем файл ответов (Windows сама подхватит его при первом запуске)
copy "D:\autounattend.xml" "C:\Windows\Panther\unattend.xml" /Y



:: Копируем installnvidia.cmd

copy D:\install.cmd  C:\
copy D:\shell.cmd          C:\
copy D:\firefox.ps1        C:\
copy D:\Microsoft.PowerShell_profile.ps1       C:\
copy D:\SwitchToFreeBSD.sh       C:\
copy D:\monitor.sh       C:\

:: Копируем apps

robocopy "D:\app" "C:\app" /E

robocopy "D:\NVIDIA" "C:\NVIDIA" /E

robocopy "D:\NetKVM" "C:\NetKVM" /E

:: -------------------------------
:: Шаг 3: Настройка загрузчика
:: -------------------------------
echo Настройка загрузки Windows на EFI раздел...
bcdboot C:\Windows /s W: /f UEFI
