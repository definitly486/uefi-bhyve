#!/bin/sh

# === НАСТРОЙКИ ПОДКЛЮЧЕНИЯ ===
WIN_USER="vcore"
WIN_PASS="639639"

# Используем зарегистрированный в реестре Windows псевдоним (алиас)
APP_NAME="||SDRSharp"

RDP_LOG="$HOME/xfreerdp_sdrsharp.log"

# === ПРОВЕРКА ЗАВИСИМОСТЕЙ ===
if ! command -v xfreerdp >/dev/null 2>&1; then
    echo "Ошибка: freerdp не установлен. Выполните: pkg install freerdp" >&2
    exit 1
fi

if ! command -v arp-scan >/dev/null 2>&1; then
    echo "Ошибка: arp-scan не установлен. Выполните: pkg install arp-scan" >&2
    exit 1
fi

# === ОПРЕДЕЛЕНИЕ IP ЧЕРЕЗ ARP-SCAN ===
echo "Поиск IP-адреса Windows ВМ в локальной сети..."
WIN_IP=$(arp-scan --localnet 2>/dev/null | awk '/NetApp/ { print $1; exit }')

if [ -z "$WIN_IP" ]; then
    echo "Ошибка: Не удалось определить IP-адрес ВМ (NetApp не найден)." >&2
    exit 2
fi

echo "Найден IP-адрес: $WIN_IP"

# === ПРОВЕРКА СЕТИ (ПИНГ ВМ) ===
echo "Проверка доступности Windows ВМ ($WIN_IP)..."
if ! ping -c 1 -W 3 "$WIN_IP" >/dev/null 2>&1; then
    echo "Ошибка: ВМ найдена, но не отвечает на пинг." >&2
    exit 3
fi

# === ЗАПУСК ПРИЛОЖЕНИЯ ===
echo "Запуск SDRSharp через зарегистрированный RemoteApp..."
echo "--- Старт сессии $(date) ---" > "$RDP_LOG"

# Оптимизированные флаги xfreerdp для мультимедиа и SDR:
# /sound:sys:pulse       - Проброс звука на ваш Linux (измените pulse на alsa, если используете чистый ALSA)
# /microphone:sys:pulse  - Проброс микрофона/IQ-входа, если планируете передавать аудио обратно в ВМ
# /network:lan           - Отключает лишнее сжатие графики для плавной отрисовки водопада SDR
xfreerdp /v:$WIN_IP \
         /u:$WIN_USER \
         /p:$WIN_PASS \
         /app:"$APP_NAME" \
         /sound:sys:oss \
         /microphone:sys:oss \
         /network:lan \
         /workarea \
         /dynamic-resolution \
         /cert:ignore >> "$RDP_LOG" 2>&1 &

echo "Запрос на запуск SDRSharp отправлен в фоновом режиме."
echo "Лог работы доступен здесь: $RDP_LOG"

