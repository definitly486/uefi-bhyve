mkdir -p ~/xp_iso_copy
sudo mkdir -p /mnt/xp_iso

# загрузить модуль udf (если ещё не загружен)
sudo kldload udf

# смонтировать ISO как memory disk
sudo mdconfig -a -t vnode -f /home/definitly/downloads/windows_iso/WindowsXPSurfacePro1.iso -u 0

# смонтировать UDF файловую систему
sudo mount -t udf /dev/md0 /mnt/xp_iso

# скопировать содержимое
cp -a /mnt/xp_iso/. ~/xp_iso_copy/

sudo umount /mnt/xp_iso
sudo mdconfig -d -u 0