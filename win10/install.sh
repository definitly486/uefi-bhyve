#!/bin/sh

for prog in 7z wimextract wimlib-imagex mkisofs cp mkdir ; do
    if ! command -v "$prog" >/dev/null 2>&1; then
        echo "Ошибка: программа '$prog' не найдена."
        exit 1
    fi
done


mkdir -p $HOME/win10_iso_copy
7z x /ntfs-2TB/vm/ISO/ru-ru_windows_10_enterprise_ltsc_2021_x64_dvd.iso -o/home/definitly/win10_iso_copy

cp -R /ntfs-2TB/vm/NVIDIA    $HOME/win10_iso_copy
cp -R /ntfs-2TB/vm/NetKVM    $HOME/win10_iso_copy
cp ../vista/MAS_AIO.cmd      $HOME/win10_iso_copy
cp autounattend.xml          $HOME/win10_iso_copy
cp installnvidia.cmd         $HOME/win10_iso_copy
cp setup.bat                 $HOME/win10_iso_copy
cp -R /ntfs-2TB/vm/app       $HOME/win10_iso_copy
cp shell.ps1                 $HOME/win10_iso_copy
cp firefox.ps1               $HOME/win10_iso_copy
wimextract $HOME/win10_iso_copy/sources/boot.wim 2  --dest-dir=/tmp/bootwim 
cp winpeshl.ini /tmp/bootwim/Windows/System32/


wimlib-imagex update $HOME/win10_iso_copy/sources/boot.wim 2 --command="add /tmp/bootwim/Windows/System32/winpeshl.ini /Windows/System32/winpeshl.ini"

mkisofs -V "Win10_Boot" -UDF -v \
  -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
  -eltorito-alt-boot \
  -eltorito-boot efi/microsoft/boot/efisys.bin -no-emul-boot \
  -o /ntfs-2TB/vm/ISO/win10_bootable.iso \
  /home/definitly/win10_iso_copy
