#!/bin/bash
# Второй MTProto-прокси под ваш домен (в ссылке server=домен, на DNS — A-запись на IP этой машины).

set -e

cd "$(dirname "$0")"

SECRET_DOMAIN=$(hexdump -vn 16 -e '4/4 "%08x" 1 ""' /dev/urandom)
echo "Сгенерирован SECRET_DOMAIN: $SECRET_DOMAIN"

read -p "Домен или поддомен для прокси (например mt.example.com): " PROXY_DOMAIN
read -p "Внешний порт на сервере (не должен совпадать с первым прокси, по умолчанию 8443): " PROXY_PORT_DOMAIN
PROXY_PORT_DOMAIN=${PROXY_PORT_DOMAIN:-8443}

export SECRET_DOMAIN
export PROXY_PORT_DOMAIN
echo "Запуск второго прокси (доменный) на порту $PROXY_PORT_DOMAIN..."
sudo -E docker compose -f docker-compose.domain.yml up -d 2>/dev/null \
  || sudo -E docker-compose -f docker-compose.domain.yml up -d

echo ""
echo "========================================================="
echo "Второй прокси запущен."
echo "SECRET (hex): $SECRET_DOMAIN"
echo ""
echo "DNS: создайте A-запись  $PROXY_DOMAIN  →  IP этой VM"
echo "GCP Firewall: откройте TCP $PROXY_PORT_DOMAIN"
echo ""
echo "Ссылка для Telegram:"
echo "tg://proxy?server=${PROXY_DOMAIN}&port=${PROXY_PORT_DOMAIN}&secret=${SECRET_DOMAIN}"
echo "https://t.me/proxy?server=${PROXY_DOMAIN}&port=${PROXY_PORT_DOMAIN}&secret=${SECRET_DOMAIN}"
echo "========================================================="
