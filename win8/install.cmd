@echo off
setlocal enabledelayedexpansion




:: Проверка и автоматический запрос прав Администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)


bcdedit.exe -set testsigning on
bcdedit.exe -set loadoptions disable_integrity_checks

echo =====================================
echo NVIDIA & NetKVM driver install script
echo =====================================

set "DRIVER_DIR=D:\Graphics"
set "DRIVER_KVM_DIR=D:\NetKVM"
set "DRIVER_VBCABLE_DIR=D:\VBCABLE_Driver_Pack45"
set "SETUP_EXE=D:\VBCABLE_Driver_Pack45\VBCABLE_Setup_x64.exe"

echo Checking driver folders...
if not exist "%DRIVER_DIR%" (
    echo ERROR: Driver folder not found!
    echo Expected: %DRIVER_DIR%
    pause
    exit /b 1
)

echo.
echo Adding and installing clean NVIDIA display driver...
pnputil -i -a "%DRIVER_DIR%\igdlh64.inf"
set "NVIDIA_ERR=%errorlevel%"

:: Проверка результата
if "%NVIDIA_ERR%"=="0" (
    echo [УСПЕШНО] Видеодрайвер установлен без лишнего софта.
) else if "%NVIDIA_ERR%"=="3010" (
    echo [УСПЕШНО] Драйвер добавлен. Система требует перезагрузки.
) else (
    echo [ОШИБКА] Не удалось установить драйвер. Код: %NVIDIA_ERR%
)



echo.
echo Adding and installing NetKVM drivers...
if exist "%DRIVER_KVM_DIR%" (
   pnputil -i -a "%DRIVER_KVM_DIR%\netkvm.inf"
) else (
    echo WARNING: NetKVM folder not found. Skipping.
)

echo.
if %NVIDIA_ERR% neq 0 (
    echo WARNING: Some NVIDIA drivers were not installed.
) else (
    echo NVIDIA drivers installed successfully.
)


pnputil /add-driver "%DRIVER_VBCABLE_DIR%\vbMmeCable64_win10.inf" /install
"%SETUP_EXE%" -i -h



D:\OpenShellSetup_4_4_200.exe /qn ADDLOCAL=StartMenu

echo.
echo =====================================
echo Configuring Applications & Profiles
echo =====================================

:: Настройка PowerShell профиля
echo Setting up PowerShell profile...
mkdir "C:\Users\vcore\Documents\WindowsPowerShell" 2>nul
if exist "C:\Microsoft.PowerShell_profile.ps1" (
    copy /y "C:\Microsoft.PowerShell_profile.ps1" "C:\Users\vcore\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

echo.
echo =====================================
echo Configuring Network & Firewall
echo =====================================

:: Включение общего доступа
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="обнаружение сетевых устройств" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="общий доступ к файлам и принтерам" new enable=Yes >nul 2>&1

:: Разрешение небезопасных гостевых входов SMB
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul

:: Включение видимости сетевых дисков админа для обычного пользователя
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections /t REG_DWORD /d 1 /f >nul

echo Trying to mount network drive Z:...
net use Z: \\192.168.8.101\Share /persistent:yes >nul 2>&1

:: Отключить сетевой фильтр UAC

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "LocalAccountTokenFilterPolicy" /t REG_DWORD /d 1 /f

:: Отключение брандмауэра
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v EnableFirewall /t REG_DWORD /d 0 /f >nul
echo Firewall disabled in registry. Reboot required for full effect.



::Автологин


reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "vcore" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "639639" /f


::ОТКЛЮЧИТЬ МАГАЗИН


reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f

echo.
echo =====================================
echo Enabling Remote Desktop (RDP)...
echo =====================================

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul

sc config TermService start= auto >nul
sc start TermService >nul

netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="удаленный рабочий стол" new enable=Yes >nul 2>&1

:: [ДОБАВЛЕНО] Разрешение RemoteApp и регистрация Блокнота
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" /v fDisabledAllowList /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\notepad" /v Name /t REG_SZ /d "Notepad" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\notepad" /v Path /t REG_SZ /d "C:\Windows\System32\notepad.exe" /f >nul

echo Remote Desktop and RemoteApp for Notepad have been enabled.



echo === Настройка реестра для RemoteApp SDRSharp ===

:: 1. Включаем глобальную поддержку RemoteApp в системе
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" /v fDisabledAllowList /t REG_DWORD /d 1 /f

:: 2. Создаем ветку приложения и задаем путь к вашему батнику (измените путь, если он другой)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v Path /t REG_SZ /d "D:\app\sdrsharp-x64\run_sdr.bat" /f

:: 3. Задаем обязательные системные параметры для запуска
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v CommandLineSetting /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v IconIndex /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v ShowInTSWA /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v Name /t REG_SZ /d "SDRSharp.dotnet8" /f

echo === Проверка внесенных изменений ===
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp"

echo Настройка завершена. Теперь вы можете использовать APP_NAME="||SDRSharp" в xfreerdp.



set "KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\firefox"

echo Добавление Firefox Portable в RemoteApp...

reg add "%KEY%" /v "CommandLineSetting" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "IconIndex" /t REG_DWORD /d 0 /f
reg add "%KEY%" /v "IconPath" /t REG_SZ /d "" /f
reg add "%KEY%" /v "Name" /t REG_SZ /d "Firefox Portable" /f
reg add "%KEY%" /v "Path" /t REG_SZ /d "D:\app\Firefox Setup 152.0.2\core\portable.bat" /f
reg add "%KEY%" /v "ShowInTSWA" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "VPath" /t REG_SZ /d "" /f

echo.
echo [ГОТОВО] Настройки реестра успешно применены.


set "KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\OOSU10"

echo Добавление O&O ShutUp10 в RemoteApp...

reg add "%KEY%" /v "CommandLineSetting" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "IconIndex" /t REG_DWORD /d 0 /f
reg add "%KEY%" /v "IconPath" /t REG_SZ /d "D:\app\OOSU10\OOSU10.exe" /f
reg add "%KEY%" /v "Name" /t REG_SZ /d "O&O ShutUp10" /f
reg add "%KEY%" /v "Path" /t REG_SZ /d "D:\app\OOSU10\OOSU10.exe" /f
reg add "%KEY%" /v "ShowInTSWA" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "VPath" /t REG_SZ /d "" /f

echo.
echo [ГОТОВО] O&O ShutUp10 успешно добавлен в RemoteApp.

echo.
echo =====================================
echo Creating Desktop Shortcuts
echo =====================================

:: Генерация скрипта VBS для создания правильных .LNK ярлыков
(
  echo Set WshShell = CreateObject^("WScript.Shell"^)
  
  echo Set Sh1 = WshShell.CreateShortcut^("%userprofile%\Desktop\Firefox Portable.lnk"^)
  echo Sh1.TargetPath = "D:\app\firefox-151.0.2.en-US.win32.installer\core\portable.bat"
  echo Sh1.WorkingDirectory = "D:\app\firefox-151.0.2.en-US.win32.installer\core\"
  echo Sh1.IconLocation = "D:\app\firefox-151.0.2.en-US.win32.installer\core\firefox.exe, 0"
  echo Sh1.Save

  echo Set Sh21 = WshShell.CreateShortcut^("%userprofile%\Desktop\Mypal Portable.lnk"^)
  echo Sh21.TargetPath = "D:\app\mypal-78.0.3.en-US.win64\mypal\portable.bat"
  echo Sh21.WorkingDirectory = "D:\app\mypal-78.0.3.en-US.win64\mypal\"
  echo Sh21.IconLocation = "D:\app\mypal-78.0.3.en-US.win64\mypal\mypal.exe, 0"
  echo Sh21.Save

  echo Set Sh8 = WshShell.CreateShortcut^("%userprofile%\Desktop\Proxifier.lnk"^)
  echo Sh8.TargetPath = "D:\app\Proxifier\Proxifier.exe"
  echo Sh8.WorkingDirectory = "D:\app\Proxifier\"
  echo Sh8.Save

  echo Set Sh9 = WshShell.CreateShortcut^("%userprofile%\Desktop\Supermium.lnk"^)
  echo Sh9.TargetPath = "D:\app\Supermium\Supermium (Classic Portable).cmd"
  echo Sh9.WorkingDirectory = "D:\app\Supermium\"
  echo Sh9.IconLocation = "D:\app\Supermium\chrome.exe, 0"
  echo Sh9.Save

  echo Set Sh10 = WshShell.CreateShortcut^("%userprofile%\Desktop\retrobar.lnk"^)
  echo Sh10.TargetPath = "D:\app\RetroBar.Portable.64-bit\retrobar.bat"
  echo Sh10.WorkingDirectory = "D:\app\RetroBar.Portable.64-bit\"
  echo Sh10.IconLocation = "D:\app\RetroBar.Portable.64-bit\RetroBar.exe, 0"
  echo Sh10.Save

  echo Set Sh11 = WshShell.CreateShortcut^("%userprofile%\Desktop\avz.lnk"^)
  echo Sh11.TargetPath = "D:\app\avz5\avz5rn.exe"
  echo Sh11.WorkingDirectory = "D:\app\avz5\"
  echo Sh11.Save

  echo Set Sh12 = WshShell.CreateShortcut^("%userprofile%\Desktop\SDRSHARP.lnk"^)
  echo Sh12.TargetPath = "D:\app\sdrsharp-x64\run_sdr.bat"
  echo Sh12.WorkingDirectory = "D:\app\sdrsharp-x64\"
  echo Sh12.IconLocation = "D:\app\sdrsharp-x64\SDRSharp.dotnet8.exe, 0"
  echo Sh12.Save

  echo Set Sh13 = WshShell.CreateShortcut^("%userprofile%\Desktop\start_dsdplus.lnk"^)
  echo Sh13.TargetPath = "D:\app\DSDPlusFull\run.cmd"
  echo Sh13.WorkingDirectory = "D:\app\DSDPlusFull\"
  echo Sh13.Save

  echo Set Sh14 = WshShell.CreateShortcut^("%userprofile%\Desktop\SwitchToFreeBSD.lnk"^)
  echo Sh14.TargetPath = "D:\app\SwitchToFreeBSD.exe"
  echo Sh14.WorkingDirectory = "D:\app\"
  echo Sh14.Save

  echo Set Sh15 = WshShell.CreateShortcut^("%userprofile%\Desktop\TelegramDesktopPortable.lnk"^)
  echo Sh15.TargetPath = "D:\app\TelegramDesktopPortable\TelegramDesktopPortable.exe"
  echo Sh15.WorkingDirectory = "D:\app\TelegramDesktopPortable"
  echo Sh15.Save

  echo Set Sh16 = WshShell.CreateShortcut^("%userprofile%\Desktop\mc.lnk"^)
  echo Sh16.TargetPath = "D:\app\Midnight Commander\mc.exe"
  echo Sh16.WorkingDirectory = "D:\app\Midnight Commander\"
  echo Sh16.Save

) > "%temp%\make_lnk.vbs"

cscript //nologo "%temp%\make_lnk.vbs"
del "%temp%\make_lnk.vbs"
echo Shortcuts created successfully.

echo Adding portable.bat to Startup...

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

copy /Y "D:\app\Firefox Setup 152.0.2\core\portable.bat" "%STARTUP%\portable.bat"


:: Безопасное удаление временных папок с драйверами (в самом конце скрипта)
::echo.
::echo Cleaning up driver directories...
::timeout /t 3 /nobreak >nul
::rd /s /q "%DRIVER_DIR%"
::if exist "%DRIVER_KVM_DIR%" rd /s /q "%DRIVER_KVM_DIR%"

echo.
echo Done. All actions completed successfully.
echo.
endlocal
