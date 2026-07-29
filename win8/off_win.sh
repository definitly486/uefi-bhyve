#!/bin/sh
ssh definitly@192.168.8.101 'cat >/tmp/off.sh <<'\''EOF'\''
#!/bin/sh

VM="win8"

PPT_DEVICES="
pci0:0:2:0
pci0:0:20:0
pci0:0:31:3
"

nohup atexec.py vcore:639639@192.168.8.104 "shutdown /s /f /t 0" >/dev/null 2>&1 &

sleep 1

for dev in $PPT_DEVICES; do
    echo "Release $dev"
    doas devctl clear driver -f "$dev"
    doas devctl set driver "$dev" none
done

echo "Finished."
EOF
chmod +x /tmp/off.sh
nohup /tmp/off.sh >/tmp/off.log 2>&1 &
'