#!/bin/sh
#doas X :1 &
#export DISPLAY=:1

IP=$(
    arp-scan --localnet 2>/dev/null |
    awk '/NetApp/ { print $1; exit }'
)

if [ -z "$IP" ]; then
    echo "NetApp не найден"
    exit 1
fi

echo "NetApp: $IP"

echo Y | xfreerdp /u:vcore  /p:639639 /w:1918 /h:1045  /v:$IP  /drive:home,/home/definitly  /sound +clipboard
