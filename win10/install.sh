#!/bin/sh

mkdir -p $HOME/win10_iso_copy
7z x /ntfs-2TB/vm/ISO/ru-ru_windows_10_enterprise_ltsc_2021_x64_dvd.iso -o/home/definitly/win10_iso_copy

cp -R /ntfs-2TB/vm/NVIDIA    $HOME/win10_iso_copy
cp -R /ntfs-2TB/vm/NetKVM    $HOME/win10_iso_copy
cp ../vista/MAS_AIO.cmd      $HOME/win10_iso_copy
cp autounattend.xml          $HOME/win10_iso_copy
cp installnvidia.cmd         $HOME/win10_iso_copy
cp setup.bat                 $HOME/win10_iso_copy
cp -R /ntfs-2TB/vm/app       $HOME/win10_iso_copy
cp shell.cmd                 $HOME/win10_iso_copy
cp firefox.ps1               $HOME/win10_iso_copy
wimextract $HOME/win10_iso_copy/sources/boot.wim 2  --dest-dir=/tmp/bootwim 
cp winpeshl.ini /tmp/bootwim/Windows/System32/


wimlib-imagex update $HOME/win10_iso_copy/sources/boot.wim 2 --command="add /tmp/bootwim/Windows/System32/winpeshl.ini /Windows/System32/winpeshl.ini"

oscdimg -m -o -u2 \
  -b"Z:\home\definitly\win10_iso_copy\boot\etfsboot.com" \
  "-bootdata:2#p0,e,bZ:\home\definitly\win10_iso_copy\boot\etfsboot.com#pEF,e,bZ:\home\definitly\win10_iso_copy\efi\microsoft\boot\efisys.bin" \
  "Z:\home\definitly\win10_iso_copy" "Z:\ntfs-2TB\vm\ISO\win10_bootable.iso"