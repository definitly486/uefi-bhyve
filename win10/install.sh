#!/bin/sh

ISO="tiny10x6423h2.iso"
SRC="/ntfs-2TB/vm/ISO/$ISO"
DEST="$HOME/win10_iso_copy"

mkdir -p "$DEST"


for prog in 7z wimextract wimlib-imagex mkisofs cp mkdir ; do
    if ! command -v "$prog" >/dev/null 2>&1; then
        echo "Ошибка: программа '$prog' не найдена."
        exit 1
    fi
done


if [ -f "$SRC" ]; then
    7z x "$SRC" -o"$DEST"
else
    echo "ISO файл не найден: $SRC"
    exit 1
fi




nice -n 15  cp -R /ntfs-2TB/vm/NVIDIA    $HOME/win10_iso_copy
nice -n 15  cp -R /ntfs-2TB/vm/NetKVM    $HOME/win10_iso_copy
cp ../vista/MAS_AIO.cmd      $HOME/win10_iso_copy
cp autounattend.xml          $HOME/win10_iso_copy
cp install.cmd         $HOME/win10_iso_copy
cp setup.bat                 $HOME/win10_iso_copy
nice -n 15  cp -R /ntfs-2TB/vm/app       $HOME/win10_iso_copy
cp shell.cmd                 $HOME/win10_iso_copy
cp firefox.ps1               $HOME/win10_iso_copy
cp Microsoft.PowerShell_profile.ps1               $HOME/win10_iso_copy
wimextract $HOME/win10_iso_copy/sources/boot.wim 2  --dest-dir=/tmp/bootwim 
cp winpeshl.ini /tmp/bootwim/Windows/System32/


wimlib-imagex update $HOME/win10_iso_copy/sources/boot.wim 2 --command="add /tmp/bootwim/Windows/System32/winpeshl.ini /Windows/System32/winpeshl.ini"

mkisofs -V "Win10_Boot" -UDF -v \
  -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
  -eltorito-alt-boot \
  -eltorito-boot efi/microsoft/boot/efisys.bin -no-emul-boot \
  -o /ntfs-2TB/vm/ISO/win10_bootable.iso \
  /home/definitly/win10_iso_copy

doas rm /ntfs-2TB/vm/win10/win10.img
truncate -s 55G /ntfs-2TB/vm/win10/win10.img

doas bhyve -A -H -P -S -s 0:0,hostbridge \
           -s 1:0,lpc \
           -s 10:0,virtio-net,tap0 \
           -s 5,fbuf,tcp=0.0.0.0:5900,"w=1918,h=1058" \
           -s 3:0,ahci-hd,/ntfs-2TB/vm/win10/win10.img  \
           -s 4,ahci-cd,/ntfs-2TB/vm/ISO/win10_bootable.iso,bootindex=1 \
           -l bootrom,/bhyve/win10/BHYVE_BHF_UEFI.fd \
           -c cpus=4,sockets=1,cores=4,threads=1  -m 4G win