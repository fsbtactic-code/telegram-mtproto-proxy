#!/bin/bash
# Скрипт для автоматической установки MTProto Proxy на Ubuntu/Debian

# Обновляем систему
sudo apt-get update
sudo apt-get upgrade -y

# Устанавливаем необходимые пакеты
sudo apt-get install -y curl wget git

# Устанавливаем Docker, если он не установлен
if ! command -v docker &> /dev/null
then
    echo "Docker не установлен. Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Устанавливаем Docker Compose, если он не установлен
if ! command -v docker-compose &> /dev/null
then
    echo "Устанавливаем docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Генерируем 32-значный секретный ключ (hex)
SECRET=$(hexdump -vn 16 -e '4/4 "%08x" 1 ""' /dev/urandom)
echo "Сгенерирован SECRET: $SECRET"

# Запрашиваем порт у пользователя
read -p "Укажите порт для прокси (по умолчанию 443): " PROXY_PORT
PROXY_PORT=${PROXY_PORT:-443}

# Запускаем прокси
echo "Запускаем MTProto Proxy на порту $PROXY_PORT..."
export SECRET=$SECRET
export PROXY_PORT=$PROXY_PORT
sudo -E docker-compose up -d

# Получаем внешний IP-адрес сервера
PUBLIC_IP=$(curl -s ifconfig.me)

# Выводим ссылку для подключения
echo ""
echo "========================================================="
echo "MTProto Proxy успешно запущен!"
echo "Ваш секрет (SECRET): $SECRET"
echo ""
echo "Ссылка для подключения в Telegram:"
echo "tg://proxy?server=$PUBLIC_IP&port=$PROXY_PORT&secret=$SECRET"
echo "Или прямая ссылка:"
echo "https://t.me/proxy?server=$PUBLIC_IP&port=$PROXY_PORT&secret=$SECRET"
echo "========================================================="
echo "ОБРАТИТЕ ВНИМАНИЕ: Не забудьте открыть TCP-порт $PROXY_PORT"
echo "в настройках Firewall вашей виртуальной машины Google Cloud!"
echo "========================================================="
