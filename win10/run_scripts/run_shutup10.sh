#!/bin/sh

# === НАСТРОЙКИ ПОДКЛЮЧЕНИЯ ===
WIN_USER="vcore"
WIN_PASS="639639"
APP_NAME="||OOSU10"
RDP_LOG="$HOME/xfreerdp_remoteapp.log"

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
echo "Запуск O&O ShutUp10 через зарегистрированный RemoteApp..."
echo "--- Старт сессии $(date) ---" > "$RDP_LOG"

# Используем проверенный монолитный синтаксис запуска
xfreerdp /v:$WIN_IP /u:$WIN_USER /p:$WIN_PASS /app:"$APP_NAME" /workarea /dynamic-resolution /cert:ignore >> "$RDP_LOG" 2>&1 &

echo "Запрос на запуск отправлен в фоновом режиме."
echo "Лог работы доступен здесь: $RDP_LOG"
