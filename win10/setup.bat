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
echo Разворачивание образа Windows на C:\
dism /apply-image /imagefile:D:\sources\install.wim /index:1 /applydir:C:\
if %errorlevel% neq 0 (
    echo DISM не сработал, пробуем gimagex...
    D:\support\tools\gimagex\x64\gimagex.exe /apply D:\sources\install.wim 1 C:\
)


:: Копируем MAS_AIO.cmd

copy D:\MAS_AIO.cmd C:\


:: Создаем необходимую папку
md "C:\Windows\Panther" 2>nul

:: Копируем файл ответов (Windows сама подхватит его при первом запуске)
copy "D:\autounattend.xml" "C:\Windows\Panther\unattend.xml" /Y



:: Копируем installnvidia.cmd

copy D:\installnvidia.cmd  C:\
copy D:\shell.cmd          C:\
copy D:\firefox.ps1        C:\


:: Копируем apps

robocopy "D:\app" "C:\app" /E

robocopy "D:\NVIDIA" "C:\NVIDIA" /E

robocopy "D:\KVM" "C:\KVM" /E

:: -------------------------------
:: Шаг 3: Настройка загрузчика
:: -------------------------------
echo Настройка загрузки Windows на EFI раздел...
bcdboot C:\Windows /s W: /f UEFI
