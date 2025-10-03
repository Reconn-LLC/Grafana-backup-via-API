# Grafana-backup-via-API

## Описание
* Проект предоставляет два основных скрипта для работы с Grafana API:

* Бэкап - сохранение дашбордов, алертов, источников данных и контактных точек

* Восстановление - обновление конфигураций Grafana из бэкапов

## Функциональности

* Бэкап дашбордов Grafana

* Бэкап правил оповещений (alert rules)

* Бэкап источников данных (data sources)

* Бэкап контактных точек (contact points)

* Восстановление всех конфигураций

* Цветное логирование процесса

* Автоматическое создание директорий

## Требования
* Bash 4.0+

* cURL для HTTP запросов

* jq для работы с JSON

* Grafana 8.0+ (для некоторых функций требуется 9.0+)

* API ключ с правами администратора в Grafana

## Установка
### Клонирование репозитория
```bash
git clone https://github.com/Reconn-LLC/Grafana-backup-via-API.git
cd Grafana-backup-via-API
```
### Установка зависимостей

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install jq curl git

# CentOS/RHEL
sudo yum install jq curl git-all
```



### Настройка прав доступа
```bash
chmod +x grafana-*.sh
```

## Конфигурация
### Основные переменные
Перед использованием отредактируйте переменные в env.example:

```bash
# API ключ Grafana (Admin -> API Keys)
KEY="youre key"

# URL Grafana сервера
HOST="https://your-grafana.example.com"

# Директории для бэкапов
DASH_DIR="/srv/grf_bkp/grafana-dashboards-backup/"
ALERT_DIR="/srv/grf_bkp/grafana-alerts-backup/"
DATA_DIR="/srv/grf_bkp/grafana-data-sources-backup/"
CONTACT_DIR="/srv/grf_bkp/grafana-contact-points-sources-backup/"
```

После переименуйте файл env.example в .env

### Создание API ключа

1. Откройте Grafana UI

2. Перейдите в Administration -> API Keys

3. Создайте новый ключ с правами Admin

4. Скопируйте ключ в переменную KEY

## Использование

Перед использованием инициализируйте дирректорию и подключите её к вашему удалённому репозиторию для выгрузки бекапов.
По умолчанию это дирректория - /srv/grf_bkp/ 

### Бэкап конфигураций
```bash
./grafana-dashboards-backup-new-test.sh
```
Результат:

* Создаются JSON файлы в указанных директориях

* Сохраняются все текущие конфигурации

* Выводится цветной статус выполнения



### Восстановление конфигураций
```bash
./grafana-update-all.sh
```

Результат:

* Обновляются дашборды через API

* Восстанавливаются правила оповещений

* Обновляются источники данных

* Восстанавливаются контактные точки

Структура файлов
```text
/srv/grf_bkp/
├── grafana-dashboards-backup/
│   └── dash.json
├── grafana-alerts-backup/
│   └── alert_rules.json
├── grafana-data-sources-backup/
│   └── data_sources.json
└── grafana-contact-points-sources-backup/
    └── contact_points.json
```
## Устранение неполадок

### Ошибка аутентификации:

``` bash
# Проверить API ключ
curl -H "Authorization: Bearer $KEY" $HOST/api/dashboards/search
```
Ошибка прав доступа:

```bash
# Проверить права на директории
ls -la /srv/grf_bkp/
```
