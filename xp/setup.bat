@echo off
chcp 1251 >nul
:: ===========================================================
:: Полностью автоматизированная установка Windows с USB
:: + Копирование BCD на раздел Vista
:: ===========================================================

echo ВНИМАНИЕ! ВСЕ ДАННЫЕ НА ДИСКЕ 0 БУДУТ УДАЛЕНЫ!
pause

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

:: -------------------------------
:: Шаг 4: Копирование папки EFI с USB (FlashBootPro)
:: -------------------------------
echo Копируем папку EFI с USB...
xcopy "D:\EFI partition\EFI" "W:\EFI\" /E /I /H /Y


(
echo sel dis 0
echo sel vol W
echo set id=ebd0a0a2-b9e5-4433-87c0-68b6b72699c7
echo exit
) | diskpart
echo D:\support\tools\Bootice\BOOTICEx64.exe




:: -------------------------------
:: Шаг 6: Готово
:: -------------------------------
echo ===========================================================
echo Установка завершена! Перезагрузите компьютер для загрузки.
pause
exit