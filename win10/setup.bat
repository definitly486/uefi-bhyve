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
@echo off
setlocal enabledelayedexpansion

:: Список всех возможных букв дисков
set "DRIVES=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
set "SOURCE_DRIVE="
set "IMAGE="

:: Перебираем диски в поисках папки sources и файлов образов
for %%D in (%DRIVES%) do (
    if exist "%%D:\sources" (
        if exist "%%D:\sources\install.wim" (
            set "SOURCE_DRIVE=%%D:"
            set "IMAGE=install.wim"
            goto :FOUND
        ) else if exist "%%D:\sources\install.esd" (
            set "SOURCE_DRIVE=%%D:"
            set "IMAGE=install.esd"
            goto :FOUND
        )
    )
)

:NOT_FOUND
echo Не найден образ (install.wim/install.esd) в папке \sources ни на одном диске^^!
pause
exit /b 1

:FOUND
:: Переходим в целевую папку, как в вашей исходной логике
cd /d "!SOURCE_DRIVE!\sources"

echo Найден образ !IMAGE! на диске !SOURCE_DRIVE!
echo Разворачивание образа !IMAGE! на C:\
dism /apply-image /imagefile="!SOURCE_DRIVE!\sources\!IMAGE!" /index:1 /applydir:C:\

:: Проверка кода ошибки DISM через отложенное расширение
if !errorlevel! neq 0 (
    echo DISM не сработал, пробуем GImageX...
    "D:\support\tools\gimagex\x64\gimagex.exe" /apply "!SOURCE_DRIVE!\sources\!IMAGE!" 1 C:\
)

endlocal


:: Копируем MAS_AIO.cmd

copy D:\MAS_AIO.cmd C:\


::копируем LayoutModification.xml

md "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell" 2>nul
copy "D:\LayoutModification.xml" "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\" /Y

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
