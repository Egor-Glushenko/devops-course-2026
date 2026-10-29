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
