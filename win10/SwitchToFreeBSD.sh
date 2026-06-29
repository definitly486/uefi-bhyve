#!/bin/sh
# Определение среды
if [ -n "$PSModulePath" ]; then
  ENV_TYPE="powershell"
elif [ "$MSYSTEM" = "MINGW64" ] || [ "$MSYSTEM" = "MINGW32" ]; then
  ENV_TYPE="mingw"
else
  ENV_TYPE="linux"
fi

echo "Detected environment: $ENV_TYPE"

# Выбор команды ssh
if [ "$ENV_TYPE" = "linux" ]; then
  IP=$(arp-scan --localnet 2>/dev/null | awk '/FreeBSD/ { print $1; exit }')
  SSH_CMD="sshpass -p 639639 ssh -T definitly@$IP"
else
  echo "sshpass disabled for $ENV_TYPE. Searching FreeBSD IP via PowerShell..."
  
  # Вызываем PowerShell. Поиск, фильтрация и очистка строки (.Trim()) происходят внутри .exe
  IP=$(powershell.exe -Command "(100..110 | ForEach-Object { \$ip='192.168.8.'+\$_; \$t=New-Object System.Net.Sockets.TcpClient; if(\$t.ConnectAsync(\$ip,22).Wait(150)){ \$s=\$t.GetStream(); \$b=New-Object byte[] 256; \$res=\$s.ReadAsync(\$b,0,256); if(\$res.Wait(200)){ \$banner=[System.Text.Encoding]::ASCII.GetString(\$b,0,\$res.Result).Trim(); if(\$banner -like '*FreeBSD*'){ [PSCustomObject]@{IP=\$ip} } } }; \$t.Close() } | Select-Object -ExpandProperty IP).Trim()")
  
  # Если IP успешно найден, формируем команду, иначе подставляем дефолтный IP
  if [ -n "$IP" ]; then
    echo "Found FreeBSD at: $IP"
    SSH_CMD="ssh -T definitly@$IP"
  else
    echo "FreeBSD not found in range, using fallback IP"
    SSH_CMD="ssh -T definitly@192.168.8.101"
  fi
fi

# Запуск удаленного скрипта на FreeBSD через Here-Doc
$SSH_CMD << 'EOF'
#!/bin/sh
doas switch_winvm_off
doas reboot

EOF

