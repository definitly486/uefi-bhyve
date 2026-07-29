#!/bin/sh

ISO="Win8.1_Russian_x64.iso"
SRC="/ntfs-2TB/vm/ISO/$ISO"
DEST="/ntfs-2TB/vm/ISO/win8_iso_copy"
ORIGINAL_ISO="/ntfs-2TB/vm/ISO/win8_bootable.iso"
VM_ISO="/ntfs-2TB/vm/win8/current_boot.iso"
MARKER="/ntfs-2TB/vm/win8/installed.flag"
VM_NAME="win8"
WIM_PATH="$DEST/sources/boot.wim"
CMD_STR="add winpeshl.ini /Windows/System32/winpeshl.ini"
WIM_FILE="$DEST/sources/install.wim"

doas bhyvectl --destroy --vm="$VM_NAME"
rm $MARKER
rm -fr "$DEST"
rm  "$ORIGINAL_ISO"
mkdir -p "$DEST"



# Список пакетов FreeBSD для проверки (через пробел)
REQUIRED_PKGS="archivers/7-zip sysutils/wimlib sysutils/cdrtools"
MISSING_PKGS=""

# Цикл проверки установленных пакетов
for pkg in $REQUIRED_PKGS; do
    if ! pkg info --exists "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
done

# Если нашли отсутствующие пакеты
if [ -n "$MISSING_PKGS" ]; then
    echo "Ошибка: В системе не установлены необходимые пакеты:"
    for pkg in $MISSING_PKGS; do
        echo "  - $pkg"
    done
    echo ""
    echo "Для их установки выполните команду от root:"
    echo "pkg install$MISSING_PKGS"
    exit 1
fi

echo "Все необходимые пакеты установлены. Продолжение работы..."




if [ -f "$SRC" ]; then
    7z x "$SRC" -o"$DEST"
else
    echo "ISO файл не найден: $SRC"
    exit 1
fi

# Копирование драйверов и скриптов автоматизации
echo "[*] Копирование дополнительных файлов..."
#nice -n 15 cp -R /ntfs-2TB/vm/NVIDIA    "$DEST/"
#nice -n 15 cp -R /ntfs-2TB/vm/NetKVM    "$DEST/"
#nice -n 15 cp -R /ntfs-2TB/vm/app       "$DEST/"
cp ../vista/MAS_AIO.cmd                 "$DEST/"
cp autounattend.xml                     "$DEST/"
cp install.cmd                          "$DEST/"
cp setup.bat                            "$DEST/"
cp shell.cmd                            "$DEST/"
cp firefox.ps1                          "$DEST/"
cp Microsoft.PowerShell_profile.ps1     "$DEST/"
cp SwitchToFreeBSD.sh                   "$DEST/"
cp monitor.sh                           "$DEST/"
cp LayoutModification.xml               "$DEST/"
cp autologin.cmd                        "$DEST/"
cp PID.txt                              "$DEST/sources"
cp off_win.sh                           "$DEST/"

#отключение запроса "нажмите чтобы загрузиться с cd"
rm $DEST/efi/microsoft/boot/efisys.bin
cp  efisys_noprompt.bin  $DEST/efi/microsoft/boot/efisys.bin

# Модификация Windows PE (boot.wim) напрямую через wimlib-imagex
echo "[*] Интеграция winpeshl.ini в boot.wim..."
# Получаем общее количество индексов (изображений) внутри WIM
TOTAL_IMAGES=$(wimlib-imagex info "$WIM_PATH" | grep "Image Count:" | awk '{print $3}')

# Если общее число индексов меньше 2, принудительно используем индекс 1
if [ "$TOTAL_IMAGES" -lt 2 ]; then
    TARGET_INDEX=1
else
    TARGET_INDEX=2
fi

# Выполняем обновление выбранного индекса
wimlib-imagex update "$WIM_PATH" "$TARGET_INDEX" --command="$CMD_STR"

# Создание кастомного загрузочного ISO
echo "[*] Создание загрузочного ISO образа..."
if [ -f "$WIM_FILE" ] && [ "$(stat -f%z "$WIM_FILE")" -gt 4294967296 ]; then
    echo "[*] install.wim > 4GB, используем xorriso (UDF)..."

mkisofs -o "$ORIGINAL_ISO" \
  -v -V "Windows8.1" \
  -iso-level 3 \
  -UDF \
  -J \
  -joliet-long \
  -boot-load-size 1 \
  -no-emul-boot \
  -b efi/microsoft/boot/efisys.bin \
 "$DEST"


else
    echo "[*] install.wim <= 4GB, используем mkisofs..."

    mkisofs -V "Win8.1_Boot" -UDF -v \
      -b boot/etfsboot.com \
        -no-emul-boot -boot-load-size 8 \
      -eltorito-alt-boot \
      -eltorito-boot efi/microsoft/boot/efisys.bin \
        -no-emul-boot \
      -o "$ORIGINAL_ISO" \
      "$DEST"
fi

doas rm /ntfs-2TB/vm/win8/win8.img
truncate -s 55G /ntfs-2TB/vm/win8/win8.img

EMPTY_ISO="/ntfs-2TB/vm/win8/empty.iso"

touch "$EMPTY_ISO"

while true
do

if [ ! -f "$MARKER" ]; then
    echo "[!] Первый запуск. Подключаем установочный ISO..."
    ln -sfn "$ORIGINAL_ISO" "$VM_ISO"
else
    echo "[+] Windows установлена. Подключаем пустой ISO..."
    ln -sfn "$EMPTY_ISO" "$VM_ISO"
    APP_DISK="-s 3:1,ahci-hd,/bhyve/win10/app8.1.img"
fi

# 2. Основной запуск bhyve
doas bhyve -A -H -P -S \
  -s 0:0,hostbridge \
  -s 1:0,lpc \
  -s 10:0,virtio-net,tap0 \
  -s 5,fbuf,tcp=0.0.0.0:5900,w=1918,h=1058 \
  -s 3:0,ahci-hd,/ntfs-2TB/vm/win8/win8.img \
   $APP_DISK \
  -s 3:2,ahci-cd,"$VM_ISO" \
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