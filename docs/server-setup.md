## Веб-сервер

- **Устанавливаемый пакет:** `nginx`
- **Путь к конфигурации ресурса:** `/etc/nginx/sites-available/devops-site`
- **Каталог ресурса:** `/var/www/devops-site`
  - Владелец: `devops:devops`
  - Права: `755` (для каталога), `644` (для файлов)
- **Пути к сертификату и ключу:**
  - Сертификат: `/etc/ssl/certs/devops.crt` (права `644`, владелец `root`)
  - Ключ: `/etc/ssl/private/devops.key` (права `600`, владелец `root`)
- **Команда формирования сертификата:**
  `sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"`
- **Срок действия сертификата:** 365 дней.

## 9. Контейнеризация

- **Установка Docker:** из официального репозитория `download.docker.com`.
- **Версия:** Docker Engine (версия уточняется командой `docker --version`).
- **Участники группы `docker`:** `devops`.
- **Расположение проекта на сервере:** `~/app`.
- **Файл `.env`:** расположен в `~/app/.env`, права `600`.
- **Публикуемые порты:** приложение доступно только на `127.0.0.1:5000` (через Nginx), порт СУБД `5432` не публикуется.
- **Именованные тома:** `app_db_data` (создаётся автоматически для сервиса `db`).
- **Обратный прокси-сервер:** Nginx проксирует запросы с `https://devops.local/app/` на `http://127.0.0.1:5000/`.