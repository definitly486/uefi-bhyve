@echo off
title Отключение служб Windows
color 0A

echo ============================================
echo   Отключение ненужных служб Windows
echo ============================================
echo.

:: Удаленный реестр
sc stop RemoteRegistry
sc config RemoteRegistry start= disabled

:: Смарт-карта
sc stop SCardSvr
sc config SCardSvr start= disabled

:: Диспетчер печати
sc stop Spooler
sc config Spooler start= disabled

:: Сервер
sc stop LanmanServer
sc config LanmanServer start= disabled

:: Браузер компьютеров
sc stop Browser
sc config Browser start= disabled

:: Поставщик домашних групп
sc stop HomeGroupProvider
sc config HomeGroupProvider start= disabled

:: Вторичный вход в систему
sc stop seclogon
sc config seclogon start= disabled

:: NetBIOS через TCP/IP
sc stop lmhosts
sc config lmhosts start= disabled

:: Центр обеспечения безопасности
sc stop wscsvc
sc config wscsvc start= disabled

:: Служба ввода планшетного ПК
sc stop TabletInputService
sc config TabletInputService start= disabled

:: Планировщик Windows Media Center
sc stop ehSched
sc config ehSched start= disabled

:: Защищенное хранилище
sc stop ProtectedStorage
sc config ProtectedStorage start= disabled

:: BitLocker
sc stop BDESVC
sc config BDESVC start= disabled

:: Bluetooth
sc stop bthserv
sc config bthserv start= disabled

:: Перечислитель переносных устройств
sc stop WPDBusEnum
sc config WPDBusEnum start= disabled

:: Windows Search
sc stop WSearch
sc config WSearch start= disabled

:: Факс
sc stop Fax
sc config Fax start= disabled

:: Архивация Windows
sc stop SDRSVC
sc config SDRSVC start= disabled

:: Центр обновления Windows
sc stop wuauserv
sc config wuauserv start= disabled

:: =========================
:: Отключение брандмауэра
:: =========================

:: Остановка службы брандмауэра
sc stop MpsSvc
sc config MpsSvc start= disabled

echo.
echo ============================================
echo     Готово. Рекомендуется перезагрузка.
echo ============================================

pause