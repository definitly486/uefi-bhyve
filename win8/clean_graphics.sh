#!/bin/sh
#
# clean_graphics.sh
#
# Удаляет из папки с драйвером Intel Graphics (igdlh64.inf) все файлы,
# которые больше не нужны после урезания inf (без Control Panel/трея,
# Vulkan, OpenCL, WiDi/Miracast, кодеков Media SDK, HDCP/HECI-служб,
# мобильных вариантов OpenGL и демо-роликов).
#
# По умолчанию скрипт работает в режиме dry-run — только показывает,
# что было бы удалено, ничего не трогая. Чтобы реально удалить файлы,
# запустите с ключом -d.
#
# Использование:
#   ./clean_graphics.sh /path/to/Graphics
#   ./clean_graphics.sh -d /path/to/Graphics
#
# Написан на чистом POSIX sh, зависимостей кроме find/grep нет.

set -eu

DELETE=0

while getopts "d" opt; do
    case "$opt" in
        d) DELETE=1 ;;
        *) echo "Использование: $0 [-d] <папка>" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

DIR="${1:-}"
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
    echo "Укажите существующую папку: $0 [-d] <папка>" >&2
    exit 1
fi

# Файлы, необходимые урезанному igdlh64.inf (ядро драйвера + coinstaller +
# базовый OpenGL), плюс сам inf и каталог подписи. Сравнение без учёта регистра.
KEEP_LIST="
igdlh64.inf
igdlh.cat
difx64.exe
displayaudiox64.cab
ig9icd32.dll
ig9icd64.dll
iga32.dll
iga64.dll
igc32.dll
igc64.dll
igd10idpp32.dll
igd10idpp64.dll
igd10iumd32.dll
igd10iumd64.dll
igd11dxva32.dll
igd11dxva64.dll
igd12umd32.dll
igd12umd64.dll
igdail32.dll
igdail64.dll
igdde32.dll
igdde64.dll
igdkmd64.sys
igdmd32.dll
igdmd64.dll
igdumdim32.dll
igdumdim64.dll
igdusc32.dll
igdusc64.dll
igfx11cmrt32.dll
igfx11cmrt64.dll
igfxcmjit32.dll
igfxcmjit64.dll
igfxcmrt32.dll
igfxcmrt64.dll
iglhcp32.dll
iglhsip32.dll
igxpco64.dll
igxpun.exe
intelcphdcpsvc.exe
intelcphecisvc.exe
"

is_kept() {
    name_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    for keep in $KEEP_LIST; do
        if [ "$name_lower" = "$keep" ]; then
            return 0
        fi
    done
    return 1
}

echo "Папка: $DIR"

count_delete=0
count_keep=0

# Только файлы в самой папке (без рекурсии в подпапки, кроме Lang отдельно)
find "$DIR" -maxdepth 1 -type f | while IFS= read -r f; do
    base=$(basename "$f")
    if is_kept "$base"; then
        count_keep=$((count_keep + 1))
        continue
    fi
    count_delete=$((count_delete + 1))
    if [ "$DELETE" -eq 1 ]; then
        rm -f -- "$f"
        echo "Удалён: $base"
    else
        echo "Будет удалён: $base"
    fi
done

# Папка Lang (локализация панели управления, которую мы вырезали) - целиком
LANG_DIR="$DIR/Lang"
if [ -d "$LANG_DIR" ]; then
    if [ "$DELETE" -eq 1 ]; then
        rm -rf -- "$LANG_DIR"
        echo "Удалена папка: Lang"
    else
        echo "Будет удалена папка: Lang"
    fi
fi

if [ "$DELETE" -eq 0 ]; then
    echo ""
    echo "Это был просмотр (dry-run). Чтобы реально удалить файлы, запустите:"
    echo "    $0 -d \"$DIR\""
fi
