# Настройка сервера devops-vm

Документ описывает целевое состояние учебной ВМ и порядок его достижения.

## 10. Ansible

### 10.1 Расположение проекта

```
ansible/
├── ansible.cfg            # inventory=prod.ini, force_handlers=True, pipelining
├── requirements.yml       # ansible.posix 1.6.2, community.docker 4.5.0, community.general 9.5.0
├── inventory/
│   ├── bootstrap.ini      # первичный запуск: student по паролю
│   └── prod.ini           # последующие запуски: devops по ключу
├── group_vars/all.yml     # образ GHCR, тег SHA, имя контейнера, порты
├── site.yml               # роли base, ssh, nginx, app
├── verify.yml             # read-only аудит результата
└── roles/
    ├── base/              # проверка ОС, пакеты, репозиторий и служба Docker
    ├── ssh/               # пользователь devops, ключ, sudo, hardening, UFW
    ├── nginx/             # установка, reverse proxy, handlers
    └── app/               # загрузка образа, контейнер, health-check
```

### 10.2 Управляющий и управляемый узлы

| Роль | Узел | Доступ |
|---|---|---|
| Управляющий | `devops-vm` (Ubuntu 26.04), каталог `~/devops-course-2026/ansible` | локальный запуск `ansible-playbook` |
| Управляемый | та же ВМ, `192.168.56.101` | SSH, порт 2222 |

Особенность стенда: ВМ уже прошла hardening в работах № 5–7, SSH перенесён на порт 2222,
поэтому `ansible_port=2222` задан в обоих inventory. Управляющий узел размещён на самой ВМ,
так как WSL хостовой системы не имеет маршрута в Host-only сеть VirtualBox.

### 10.3 Учётные записи

| Этап | Учётная запись | Аутентификация |
|---|---|---|
| bootstrap | `student` | пароль (SSH-пароль запрашивается `--ask-pass`) |
| prod | `devops` | ключ `~/.ssh/devops_vm`, sudo без пароля (`/etc/sudoers.d/devops`) |

### 10.4 Роли и их ответственность

- `base` — проверка платформы (Ubuntu ≥ 24.04, x86_64), базовые пакеты (`python3-requests`,
  `python3-debian`), официальный репозиторий Docker (`deb822_repository`), `docker-ce`, служба Docker;
- `ssh` — пользователь `devops`, каталог `~/.ssh` (0700), открытый ключ, `NOPASSWD`,
  hardening `sshd` (файл `00-ansible-hardening.conf`), UFW (22, 2222, 80; deny incoming);
- `nginx` — пакет, шаблон reverse proxy `devops-ci-app.conf.j2`, отключение default site,
  симлинк в `sites-enabled`, handlers `nginx -t` + reload;
- `app` — загрузка образа GHCR по тегу SHA, контейнер `devops-ci-app`, публикация
  `127.0.0.1:5000`, health-check через `uri` с 15 попытками.

### 10.5 Параметры приложения

| Параметр | Значение |
|---|---|
| Образ | `ghcr.io/egor-glushenko/devops-ci-app` |
| Тег (полный SHA) | `dbce45a52c811ba49c02fb88ba2adcbb59c33d09` |
| Контейнер | `devops-ci-app` |
| Порт публикации | `127.0.0.1:5000` (наружу не публикуется) |
| Health endpoint | `GET /health` → `{"status": "ok"}` |
| Внешний вход | `http://192.168.56.101/` через Nginx |

Пакет GHCR оставлен приватным, поэтому на ВМ настроена аутентификация чтения:
`docker login ghcr.io` с токеном, имеющим доступ к пакету. Токен в репозиторий и в документ
не включается.

### 10.6 Команды

Первичный запуск (bootstrap):

```
cd ~/devops-course-2026/ansible
ansible-inventory -i inventory/bootstrap.ini --graph
ansible-playbook -i inventory/bootstrap.ini site.yml --syntax-check
ansible-playbook -i inventory/bootstrap.ini site.yml --ask-pass
```

Повторные запуски (prod, без интерактивного ввода):

```
cd ~/devops-course-2026/ansible
ansible-inventory --graph
ansible-playbook site.yml
```

Аудит результата (не изменяет конфигурацию):

```
cd ~/devops-course-2026/ansible
ansible-playbook verify.yml
```

Проверка извне:

```
curl --fail http://192.168.56.101/health
curl --fail http://192.168.56.101/
```

### 10.7 Ожидаемые результаты

- первый запуск: `failed=0`, handlers `Restart SSH` и `Reload Nginx` выполнены;
- повторный запуск `site.yml`: `changed=0`, `failed=0`;
- `verify.yml`: `changed=0`, все утверждения пройдены;
- порт 5000 привязан к `127.0.0.1`, наружу открыты только 80 и 2222 (SSH);
- при несуществующем теге образа плейбук завершается ошибкой на задаче загрузки,
  ранее запущенный контейнер продолжает работать.

Пароли, закрытые ключи и токены в документ не включаются.
