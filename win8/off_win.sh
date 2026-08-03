#!/bin/sh
ssh definitly@192.168.8.101 'cat >/tmp/off.sh <<'\''EOF'\''
#!/bin/sh

VM="win8"

PPT_DEVICES="
pci0:0:2:0
pci0:0:20:0
pci0:0:31:3
"
IP=$(
    arp-scan --localnet 2>/dev/null |
    awk '/NetApp/ { print $1; exit }'
)

if [ -z "$IP" ]; then
    echo "NetApp не найден"
    exit 1
fi

echo "NetApp: $IP"

echo "Sending shutdown to Windows..."
nohup atexec.py vcore:639639@$IP "shutdown /s /f /t 0" >/dev/null 2>&1 &

echo "Waiting for VM shutdown..."

while pgrep -f "bhyve.*$VM" >/dev/null 2>&1; do
    sleep 1
done

echo "VM stopped. Releasing PCI devices..."

for dev in $PPT_DEVICES; do
    echo "Release $dev"

    doas devctl clear driver -f "$dev"
    sleep 1

    doas devctl set driver "$dev" none
done

echo "Finished."
EOF
chmod +x /tmp/off.sh
nohup /tmp/off.sh >/tmp/off.log 2>&1 &
'