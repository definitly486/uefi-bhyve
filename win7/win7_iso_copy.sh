mkdir -p ~/win7_iso_copy
sudo mkdir -p /mnt/win7_iso

# загрузить модуль udf (если ещё не загружен)
sudo kldload udf

# смонтировать ISO как memory disk
sudo mdconfig -a -t vnode -f /home/definitly/downloads/windows_iso/Windows7SurfacePro1.iso -u 0

# смонтировать UDF файловую систему
sudo mount -t udf /dev/md0 /mnt/win7_iso

# скопировать содержимое
cp -a /mnt/win7_iso/. ~/win7_iso_copy/

sudo umount /mnt/win7_iso
sudo mdconfig -d -u 0