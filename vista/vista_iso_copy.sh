mkdir -p ~/vista_iso_copy
sudo mkdir -p /mnt/vista_iso

# загрузить модуль udf (если ещё не загружен)
sudo kldload udf

# смонтировать ISO как memory disk
sudo mdconfig -a -t vnode -f /home/definitly/downloads/windows_iso/WindowsVistaSurfacePro1.iso -u 0

# смонтировать UDF файловую систему
sudo mount -t udf /dev/md0 /mnt/vista_iso

# скопировать содержимое
cp -a /mnt/vista_iso/. ~/vista_iso_copy/

sudo umount /mnt/vista_iso
sudo mdconfig -d -u 0