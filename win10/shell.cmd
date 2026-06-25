@echo off
chcp 65001 > nul

echo [1/4] Разрешаем выполнение скриптов в PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

echo [2/4] Проверяем и создаем профиль PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }"

echo [3/4] Добавляем функции git и bash в профиль...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $PROFILE -Value 'function git { & ''C:\app\PortableGit-2.54.0-64-bit.7z\bin\git.exe'' @args }'"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $PROFILE -Value 'function bash { & ''C:\app\PortableGit-2.54.0-64-bit.7z\bin\bash.exe'' @args }'"

echo [4/4] Запускаем PowerShell с вашим профилем...
powershell -NoExit -ExecutionPolicy Bypass

