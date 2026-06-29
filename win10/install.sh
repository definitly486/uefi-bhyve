#!/bin/sh

ISO="tiny10x6423h2.iso"
SRC="/ntfs-2TB/vm/ISO/$ISO"
DEST="/ntfs-2TB/vm/ISO/win10_iso_copy"
ORIGINAL_ISO="/ntfs-2TB/vm/ISO/win10_bootable.iso"
VM_ISO="/ntfs-2TB/vm/win10/current_boot.iso"
MARKER="/ntfs-2TB/vm/win10/installed.flag"
VM_NAME="win10"


doas bhyvectl --destroy --vm="$VM_NAME"
rm $MARKER
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

# Копирование драйверов и скриптов автоматизации
echo "[*] Копирование дополнительных файлов..."
nice -n 15 cp -R /ntfs-2TB/vm/NVIDIA    "$DEST/"
nice -n 15 cp -R /ntfs-2TB/vm/NetKVM    "$DEST/"
nice -n 15 cp -R /ntfs-2TB/vm/app       "$DEST/"
cp ../vista/MAS_AIO.cmd                 "$DEST/"
cp autounattend.xml                     "$DEST/"
cp install.cmd                          "$DEST/"
cp setup.bat                            "$DEST/"
cp shell.cmd                            "$DEST/"
cp firefox.ps1                          "$DEST/"
cp Microsoft.PowerShell_profile.ps1     "$DEST/"
cp SwitchToFreeBSD.sh                   "$DEST/"
cp monitor.sh                           "$DEST/"

#отключение запроса "нажмите чтобы загрузиться с cd"
rm $DEST/efi/microsoft/boot/efisys.bin
cp  efisys.bin  $DEST/efi/microsoft/boot/efisys.bin

# Модификация Windows PE (boot.wim) напрямую через wimlib-imagex
echo "[*] Интеграция winpeshl.ini в boot.wim..."
wimlib-imagex update "$DEST/sources/boot.wim" 2 --command="add winpeshl.ini /Windows/System32/winpeshl.ini"

# Создание кастомного загрузочного ISO
echo "[*] Создание загрузочного ISO образа..."
mkisofs -V "Win10_Boot" -UDF -v \
  -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 \
  -eltorito-alt-boot \
  -eltorito-boot efi/microsoft/boot/efisys.bin -no-emul-boot \
  -o "$ORIGINAL_ISO" \
  "$DEST"

doas rm /ntfs-2TB/vm/win10/win10.img
truncate -s 55G /ntfs-2TB/vm/win10/win10.img

EMPTY_ISO="/ntfs-2TB/vm/win10/empty.iso"

touch "$EMPTY_ISO"

while true
do

if [ ! -f "$MARKER" ]; then
    echo "[!] Первый запуск. Подключаем установочный ISO..."
    ln -sfn "$ORIGINAL_ISO" "$VM_ISO"
else
    echo "[+] Windows установлена. Подключаем пустой ISO..."
    ln -sfn "$EMPTY_ISO" "$VM_ISO"
fi

# 2. Основной запуск bhyve
doas bhyve -A -H -P -S \
  -s 0:0,hostbridge \
  -s 1:0,lpc \
  -s 10:0,virtio-net,tap0 \
  -s 5,fbuf,tcp=0.0.0.0:5900,w=1918,h=1058 \
  -s 3:0,ahci-hd,/ntfs-2TB/vm/win10/win10.img \
  -s 3:1,ahci-cd,"$VM_ISO" \
  -l bootrom,/bhyve/win10/BHYVE_BHF_UEFI.fd \
  -c cpus=4,sockets=1,cores=4,threads=1 \
  -m 4G "$VM_NAME"


# bhyve приостанавливает выполнение скрипта, пока ВМ работает.
# Код ниже выполнится ТОЛЬКО после выключения или перезагрузки Windows.

# 3. Очистка ресурсов в памяти FreeBSD (Обязательно для bhyve)
echo "[*] Очистка ресурсов bhyve для машины $VM_NAME..."
RES=$?
doas bhyvectl --destroy --vm="$VM_NAME"
    if [ $RES -eq 1 ]
    then
        exit 1
    fi
    echo sleeping for 5 sec...
    sleep 5

# 4. Фиксация успешного первого запуска
if [ ! -f "$MARKER" ]; then
    echo "[+] Первая стадия установки завершена. Создаем маркер..."
    touch "$MARKER"
    echo "[*] Теперь Windows будет загружаться только с жесткого диска."
fi
done