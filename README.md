# Telegram MTProto Proxy на Google Cloud VM

Этот проект позволяет быстро и удобно развернуть официальный MTProto Proxy сервер для Telegram на виртуальной машине Google Cloud с помощью Docker и Docker Compose.

## 📌 Шаг 1: Подготовка Google Cloud VM
1. Перейдите в **Google Cloud Console**.
2. Создайте новый VM инстанс (Compute Engine -> VM instances -> Create Instance).
   * **ОС (Boot disk):** Рекомендуется выбрать **Ubuntu 22.04 LTS** (или 20.04 LTS).
   * **Тип машины:** Подойдет самый базовый (`e2-micro`, `f1-micro`), так как прокси не потребляет много ресурсов.
3. В разделе **Firewall** (Сетевые настройки) разрешите **HTTP** и **HTTPS** трафик.

### Важно: Настройка порта
По умолчанию MTProto Proxy использует порт `443` (самый надежный для обхода блокировок), но при установке скрипт предложит вам указать любой другой порт (например, `8443` или `8080`). Официальный образ внутри контейнера слушает **443**; в `docker-compose` ваш внешний порт пробрасывается на него (`844:443` и т.п.).
Вам нужно убедиться, что выбранный вами порт открыт в файрволе Google Cloud:
1. Перейдите в **VPC network** -> **Firewall**.
2. Нажмите **Create Firewall Rule**.
3. Укажите имя (например, `allow-mtproto`).
4. **Targets:** `All instances in the network`.
5. **Source IPv4 ranges:** `0.0.0.0/0`.
6. **Protocols and ports:** Выберите **tcp** и укажите ваш порт (например, `443` или `8443`).
7. Сохраните правило.

## 📌 Шаг 2: Установка на сервер
Подключитесь к вашему серверу через SSH. Вы можете сделать это прямо в браузере через Google Cloud Console, нажав кнопку `SSH` рядом с вашей виртуалкой, либо использовать ваш терминал.

На сервере выполните следующие команды:

1. Создайте папку для проекта и перейдите в нее:
   ```bash
   mkdir mtproto-proxy && cd mtproto-proxy
   ```

2. Создайте файл `docker-compose.yml` и скопируйте в него содержимое одноимённого файла из этого репозитория (или используйте `wget`/`curl`, если загрузили куда-то `docker-compose.yml` и `install.sh`). Вы можете просто создать файл `install.sh` и запустить его.

**Быстрый запуск:** 
Просто создайте на сервере файл `install.sh`, скопируйте в него код из файла в этой папке, сделайте его исполняемым и запустите:
```bash
nano install.sh
# (Вставьте содержимое install.sh)
# Сохраните: Ctrl+O, Enter, Ctrl+X

chmod +x install.sh
./install.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Сгенерирует случайный криптографический секрет (SECRET)
- Запустит Docker-контейнер
- Выдаст вам готовую `tg://proxy?...` ссылку для подключения.

## 📌 Полезные команды Docker

- Посмотреть логи прокси (чтобы увидеть подключения):
  ```bash
  sudo docker-compose logs -f mtproto-proxy
  ```
- Остановить прокси:
  ```bash
  sudo docker-compose down
  ```
- Перезапустить прокси:
  ```bash
  sudo docker-compose restart
  ```

## 📌 Второй прокси на своём домене

Официальный образ не требует отдельного SSL на сервере для обычного MTProto: в ссылке в поле **server** можно указать **домен**, если у него **A-запись** указывает на IP той же VM, где крутится второй контейнер.

1. В DNS у регистратора: **A** для поддомена (например `mt.example.com`) → **внешний IP** вашей VM.
2. В **Firewall** GCP: откройте **новый** TCP-порт (не тот, что у первого прокси), например `8443`.
3. На сервере в каталоге репозитория:
   ```bash
   git pull
   chmod +x install-domain.sh
   ./install-domain.sh
   ```
   Скрипт спросит домен и порт, поднимет контейнер `mtproto-proxy-domain` и выведет ссылки уже с `server=ваш_домен`.

Ручной запуск без скрипта:
```bash
export SECRET_DOMAIN=$(hexdump -vn 16 -e '4/4 "%08x" 1 ""' /dev/urandom)
export PROXY_PORT_DOMAIN=8443
sudo -E docker compose -f docker-compose.domain.yml up -d
```

Логи второго прокси: `sudo docker compose -f docker-compose.domain.yml logs -f mtproto-proxy-domain` (или `docker-compose` вместо `docker compose`).

## 🔒 Безопасность и DD 
Для защиты от DPI-блокировок часто используют «Fake TLS» прокси (секрет, начинающийся с букв `ee`). Эти скрипты генерируют обычный `hex` секрет.
Fake TLS — отдельная настройка; см. обсуждения вокруг MTProxy и клиентов Telegram.
Официальный образ: https://hub.docker.com/r/telegrammessenger/proxy
