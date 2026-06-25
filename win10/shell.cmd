@echo off
chcp 65001 > nul

echo [1/3] Разрешаем выполнение скриптов в PowerShell...
powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"

echo [2/3] Проверяем и создаем профиль PowerShell, если его нет...
powershell -NoProfile -Command "if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }"

echo [3/3] Добавляем функции git и bash в профиль...
powershell -NoProfile -Command "$functions = 'function git { & ''C:\app\PortableGit-2.54.0-64-bit.7z\bin\git.exe'' @args }', 'function bash { & ''C:\app\PortableGit-2.54.0-64-bit.7z\bin\bash.exe'' @args }'; Add-Content -Path $PROFILE -Value $functions -Encoding utf8"

echo [4/4] Запуск PowerShell и применение профиля...
powershell -NoExit -Command ". $PROFILE"
