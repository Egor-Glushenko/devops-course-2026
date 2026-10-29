#!/usr/bin/env bash

# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# 1. Проверка наличия файла index.html (Требование 4)
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html не найден!" >&2
    exit 1
fi

# 2. Проверка на незафиксированные изменения (Требование 5)
if [[ -n $(git status --porcelain) ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

echo "[4] Веб-сервер"
check "Конфигурация nginx корректна" "0" "$(sudo nginx -t > /dev/null 2>&1; echo $?)"

# Проверка срока действия сертификата (должен быть больше 30 дней)
CERT_END=$(sudo openssl x509 -enddate -noout -in /etc/ssl/certs/devops.crt | cut -d= -f2)
CERT_END_SEC=$(date -d "$CERT_END" +%s)
NOW_SEC=$(date +%s)
DAYS_LEFT=$(( (CERT_END_SEC - NOW_SEC) / 86400 ))
if [[ $DAYS_LEFT -gt 30 ]]; then
    echo " [OK]  Сертификат действителен ($DAYS_LEFT дней)"
    ((PASS++))
else
    echo " [FAIL] Сертификат истекает слишком скоро ($DAYS_LEFT дней)"
    ((FAIL++))
fi

# Проверка отсутствия файлов с правом записи для всех
W_WRITABLE=$(find /var/www/devops-site -perm -o+w | wc -l)
check "Нет файлов с правом записи для всех" "0" "$W_WRITABLE"

# Проверка прав ключа (должно быть 600)
KEY_PERMS=$(sudo stat -c '%a' /etc/ssl/private/devops.key)
check "Права ключа 600" "600" "$KEY_PERM"

# 3. Синхронизация (Требование 3 и 8)
RSYNC_OPTS=(-avz --delete --chmod=D755,F644 -e "ssh -o BatchMode=yes -o ConnectTimeout=5")
if [[ "${DRY_RUN}" == "true" ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

echo "Начинаем синхронизацию..."
rsync "${RSYNC_OPTS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "Режим --dry-run завершен. Изменения не вносились."
    exit 0
fi

# 4. Проверка доступности (Требование 6)
echo "Проверка доступности сайта..."
if ! curl -s --cacert "${CA_CERT}" -f "${SITE_URL}" > /dev/null; then
    echo "Ошибка: сайт недоступен после деплоя!" >&2
    exit 1
fi

# 5. Успешное завершение (Требование 7)
echo "Деплой успешно завершен. Коммит: $(git rev-parse --short HEAD)"
