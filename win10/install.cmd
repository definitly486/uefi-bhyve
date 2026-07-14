@echo off
setlocal enabledelayedexpansion

:: Проверка и автоматический запрос прав Администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo =====================================
echo NVIDIA & NetKVM driver install script
echo =====================================

set "DRIVER_DIR=D:\NVIDIA"
set "DRIVER_KVM_DIR=D:\NetKVM"

echo Checking driver folders...
if not exist "%DRIVER_DIR%" (
    echo ERROR: Driver folder not found!
    echo Expected: %DRIVER_DIR%
    pause
    exit /b 1
)

echo.
echo Adding and installing NVIDIA drivers to Driver Store...
pnputil /add-driver "%DRIVER_DIR%\nv_dispi.inf" /subdirs /install
set "NVIDIA_ERR=%errorlevel%"

echo.
echo Adding and installing NetKVM drivers...
if exist "%DRIVER_KVM_DIR%" (
    pnputil /add-driver "%DRIVER_KVM_DIR%\netkvm.inf" /subdirs /install
) else (
    echo WARNING: NetKVM folder not found. Skipping.
)

echo.
if %NVIDIA_ERR% neq 0 (
    echo WARNING: Some NVIDIA drivers were not installed.
) else (
    echo NVIDIA drivers installed successfully.
)

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
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\SDRSharp" /v Path /t REG_SZ /d "C:\app\sdrsharp-x64\run_sdr.bat" /f

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
reg add "%KEY%" /v "Path" /t REG_SZ /d "C:\app\Firefox Setup 152.0.2\core\portable.bat" /f
reg add "%KEY%" /v "ShowInTSWA" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "VPath" /t REG_SZ /d "" /f

echo.
echo [ГОТОВО] Настройки реестра успешно применены.


set "KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList\Applications\OOSU10"

echo Добавление O&O ShutUp10 в RemoteApp...

reg add "%KEY%" /v "CommandLineSetting" /t REG_DWORD /d 1 /f
reg add "%KEY%" /v "IconIndex" /t REG_DWORD /d 0 /f
reg add "%KEY%" /v "IconPath" /t REG_SZ /d "C:\app\OOSU10\OOSU10.exe" /f
reg add "%KEY%" /v "Name" /t REG_SZ /d "O&O ShutUp10" /f
reg add "%KEY%" /v "Path" /t REG_SZ /d "C:\app\OOSU10\OOSU10.exe" /f
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
  echo Sh1.TargetPath = "D:\app\Firefox Setup 152.0.2\core\portable.bat"
  echo Sh1.WorkingDirectory = "D:\app\Firefox Setup 152.0.2\core\"
  echo Sh1.IconLocation = "D:\app\Firefox Setup 152.0.2\core\firefox.exe, 0"
  echo Sh1.Save

  echo Set Sh3 = WshShell.CreateShortcut^("%userprofile%\Desktop\start_vpn.lnk"^)
  echo Sh3.TargetPath = "D:\app\AmneziaVPN_4.8.19.0_x64\start_vpn.cmd"
  echo Sh3.WorkingDirectory = "D:\app\AmneziaVPN_4.8.19.0_x64\"
  echo Sh3.Save

  echo Set Sh4 = WshShell.CreateShortcut^("%userprofile%\Desktop\AmneziaVPN.lnk"^)
  echo Sh4.TargetPath = "D:\app\AmneziaVPN_4.8.19.0_x64\AmneziaVPN.exe"
  echo Sh4.WorkingDirectory = "D:\app\AmneziaVPN_4.8.19.0_x64\"
  echo Sh4.Save

  echo Set Sh5 = WshShell.CreateShortcut^("%userprofile%\Desktop\FreeTube.lnk"^)
  echo Sh5.TargetPath = "D:\app\freetube-0.24.1-beta-win-x64-portable\FreeTube.exe"
  echo Sh5.WorkingDirectory = "D:\app\freetube-0.24.1-beta-win-x64-portable\"
  echo Sh5.Save

  echo Set Sh6 = WshShell.CreateShortcut^("%userprofile%\Desktop\GTweak.lnk"^)
  echo Sh6.TargetPath = "D:\app\GTweak\GTweak.exe"
  echo Sh6.WorkingDirectory = "D:\app\GTweak\"
  echo Sh6.Save

  echo Set Sh7 = WshShell.CreateShortcut^("%userprofile%\Desktop\OOSU10.lnk"^)
  echo Sh7.TargetPath = "D:\app\OOSU10\OOSU10.exe"
  echo Sh7.WorkingDirectory = "D:\app\OOSU10\"
  echo Sh7.Save

  echo Set Sh8 = WshShell.CreateShortcut^("%userprofile%\Desktop\chrome.lnk"^)
  echo Sh8.TargetPath = "D:\app\Chrome-bin\chrome.exe"
  echo Sh8.WorkingDirectory = "D:\app\Chrome-bin\"
  echo Sh8.Save

  echo Set Sh9 = WshShell.CreateShortcut^("%userprofile%\Desktop\chrome.lnk"^)
  echo Sh9.TargetPath = "D:\app\Brave\Brave.exe"
  echo Sh9.WorkingDirectory = "D:\app\Brave\"
  echo Sh9.Save

  echo Set Sh10 = WshShell.CreateShortcut^("%userprofile%\Desktop\retrobar.lnk"^)
  echo Sh10.TargetPath = "D:\app\RetroBar.Portable.64-bit\retrobar.bat"
  echo Sh10.WorkingDirectory = "D:\app\RetroBar.Portable.64-bit\"
  echo Sh10.IconLocation = "D:\app\RetroBar.Portable.64-bit\RetroBar.exe, 0"
  echo Sh10.Save
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
