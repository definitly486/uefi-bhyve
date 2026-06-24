#!/bin/sh

wimextract $HOME/win10_iso_copy/sources/boot.wim 2  --dest-dir=/tmp/bootwim 
cp winpeshl.ini /tmp/bootwim/Windows/System32/
cp setup.bat $HOME/win10_iso_copy
wimlib-imagex update $HOME/win10_iso_copy/sources/boot.wim 2 --command="add /tmp/bootwim/Windows/System32/winpeshl.ini /Windows/System32/winpeshl.ini"

oscdimg -m -o -u2 \
  -b"Z:\home\definitly\win10_iso_copy\boot\etfsboot.com" \
  "-bootdata:2#p0,e,bZ:\home\definitly\win10_iso_copy\boot\etfsboot.com#pEF,e,bZ:\home\definitly\win10_iso_copy\efi\microsoft\boot\efisys.bin" \
  "Z:\home\definitly\win10_iso_copy" "Z:\ntfs-2TB\vm\ISO\win10_bootable.iso"