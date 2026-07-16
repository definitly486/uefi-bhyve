#!/bin/sh


if test "$(id -u)" -ne 0; then
	printf "%s must be run as root\n" "${0##*/}"
	exit 1
fi

IMG="/bhyve/win10/app.img"
MNT="/mnt/app"

if [ -z "$IMG" ]; then
    echo "Usage: $0 image.img"
    exit 1
fi

mkdir -p "$MNT"

# Подключаем образ как md-устройство
MD=$(mdconfig -a -t vnode -f "$IMG")

echo "MD device: $MD"

# Если NTFS начинается не с первого сектора (есть MBR/GPT),
# ищем разделы
gpart recover "$MD" >/dev/null 2>&1
gpart show "$MD"

ntfsfix -d /dev/${MD}p1

# Обычно первый раздел будет ${MD}p1
ntfs-3g /dev/${MD}p1 "$MNT"

echo "Mounted at $MNT"
echo "Unmount:"
echo "doas  umount $MNT"
echo "doas  mdconfig -d -u ${MD#md}"