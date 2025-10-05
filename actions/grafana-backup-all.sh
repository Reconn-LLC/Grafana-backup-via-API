if [ ! -f ".env" ]; then
    $SETCOLOR_FAILURE
    echo "ERROR: .env file not found!"
    echo "Please copy env.example to .env and configure your settings"
    $SETCOLOR_NORMAL
    exit 1
fi

source .env

if [ ! -d "$DASH_DIR" ]; then
     mkdir -p "$DASH_DIR"
else
     $SETCOLOR_TITLE_PURPLE
     echo "|----------------------A dash directory is already exist!-----------------------|";
     $SETCOLOR_NORMAL
fi

if [ ! -d "$ALERT_DIR" ]; then
     mkdir -p "$ALERT_DIR"
else
     $SETCOLOR_TITLE_PURPLE
     echo "|---------------------A alert directory is already exist!-----------------------|";
     $SETCOLOR_NORMAL
fi

if [ ! -d "$DATA_DIR" ]; then
     mkdir -p "$DATA_DIR"
else
     $SETCOLOR_TITLE_PURPLE
     echo "|------------------A data sources directory is already exist!-------------------|";
     $SETCOLOR_NORMAL
fi

if [ ! -d "$CONTACT_DIR" ]; then
     mkdir -p "$CONTACT_DIR"
else
     $SETCOLOR_TITLE_PURPLE
     echo "|----------------A contact points directory is already exist!-------------------|";
     $SETCOLOR_NORMAL
fi

# Функция для выполнения curl запросов с проверкой ошибок
make_curl_request() {
    local url=$1
    local output_file=$2
    local description=$3

    # Создаем временный файл для ответа
    local temp_file=$(mktemp)

    # Выполняем запрос и сохраняем HTTP статус
    http_code=$(curl -sS -k -w "%{http_code}" -H "Authorization: Bearer $KEY" "$url" -o "$temp_file")

    # Проверяем HTTP статус
    if [ "$http_code" -ne 200 ]; then
        $SETCOLOR_FAILURE
        echo "ERROR: HTTP $http_code - Failed to fetch $description"
        echo "URL: $url"
        echo "First few lines of response:"
        head -5 "$temp_file"
        $SETCOLOR_NORMAL
        rm "$temp_file"
        return 1
    fi

    # Пробуем обработать через jq
    if jq . "$temp_file" > "$output_file" 2>/dev/null; then
        rm "$temp_file"
        return 0
    else
        $SETCOLOR_FAILURE
        echo "ERROR: Invalid JSON response for $description"
        echo "URL: $url"
        echo "Raw response (first 200 chars):"
        head -c 200 "$temp_file"
        echo ""
        echo "Full response saved to ${output_file}.raw for debugging"
        cp "$temp_file" "${output_file}.raw"
        $SETCOLOR_NORMAL
        rm "$temp_file"
        return 1
    fi
}

# Функция для сохранения отдельных дашбордов
save_individual_dashboards() {
    local input_file="$1"
    local output_dir="$2"

    # Очищаем директорию перед сохранением
    rm -f "$output_dir"/*.json

    # Определяем формат (Kubernetes CR или стандартный)
    if jq -e '.kind == "DashboardList"' "$input_file" >/dev/null; then
        echo "Processing Kubernetes CR format..."
        total_dashboards=$(jq -r '.items | length' "$input_file")
        processed=0

        jq -c '.items[]' "$input_file" | while read -r dashboard; do
            processed=$((processed + 1))

            # Извлекаем имя и UID
            name=$(echo "$dashboard" | jq -r '.metadata.name // empty')
            uid=$(echo "$dashboard" | jq -r '.spec.uid // .uid // empty')
            title=$(echo "$dashboard" | jq -r '.spec.title // .title // "unnamed"')

            # Создаем безопасное имя файла
            if [ -n "$name" ]; then
                safe_name=$(echo "$name" | tr '/' '_' | tr ' ' '_')
                filename="${safe_name}.json"
            elif [ -n "$uid" ]; then
                filename="${uid}.json"
            else
                filename="dashboard_${processed}.json"
            fi

            output_file="$output_dir/$filename"

            echo "[$processed/$total_dashboards] Saving: $title -> $filename"
            echo "$dashboard" | jq '.' > "$output_file"
        done

    else
        echo "Processing standard Grafana format..."
        total_dashboards=$(jq -r 'length' "$input_file")
        processed=0

        jq -c '.[]' "$input_file" | while read -r dashboard; do
            processed=$((processed + 1))

            # Извлекаем UID и название
            uid=$(echo "$dashboard" | jq -r '.uid // empty')
            title=$(echo "$dashboard" | jq -r '.title // "unnamed"')

            # Создаем безопасное имя файла
            if [ -n "$uid" ]; then
                filename="${uid}.json"
            else
                safe_title=$(echo "$title" | tr '/' '_' | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                filename="${safe_title}.json"
            fi

            output_file="$output_dir/$filename"

            echo "[$processed/$total_dashboards] Saving: $title -> $filename"
            echo "$dashboard" | jq '.' > "$output_file"
        done
    fi
}

$SETCOLOR_NUMBERS
echo "|-------------------------------START COPY DASH---------------------------------|";
$SETCOLOR_NORMAL

rm -f "$DASH_DIR"/*.json

# Получаем список всех дашбордов из Grafana
DASH_LIST_FILE=$(mktemp)
make_curl_request "$HOST/api/search?query=" "$DASH_LIST_FILE" "dashboard list"

TOTAL_DASHES=$(jq -r '[.[] | select(.type == "dash-db")] | length' "$DASH_LIST_FILE")
if [ "$TOTAL_DASHES" -eq 0 ]; then
    $SETCOLOR_FAILURE
    echo "No dashboards found in Grafana instance at $HOST"
    $SETCOLOR_NORMAL
    rm -f "$DASH_LIST_FILE"
    exit 1
fi

$SETCOLOR_TITLE_PURPLE
echo "Found $TOTAL_DASHES dashboards — exporting..."
$SETCOLOR_NORMAL

COUNTER=0
jq -r '.[] | select(.type == "dash-db") | .uid' "$DASH_LIST_FILE" | while read -r DASH_UID; do
    if [ -z "$DASH_UID" ]; then
        continue
    fi

    COUNTER=$((COUNTER + 1))
    DASHBOARD_RAW=$(curl -sS -H "Authorization: Bearer $KEY" "$HOST/api/dashboards/uid/$DASH_UID")

    # Проверяем, что ответ корректный и содержит dashboard
    if ! echo "$DASHBOARD_RAW" | jq -e '.dashboard' >/dev/null; then
        echo "[$COUNTER/$TOTAL_DASHES] Skipping UID=$DASH_UID (invalid response)"
        continue
    fi

    TITLE=$(echo "$DASHBOARD_RAW" | jq -r '.dashboard.title // "unnamed"')
    SAFE_TITLE=$(echo "$TITLE" | tr ' /' '_' | tr '[:upper:]' '[:lower:]')
    OUTPUT_FILE="$DASH_DIR/$SAFE_TITLE.json"

    # Обновляем schemaVersion и исправляем thresholds
    DASHBOARD_FIXED=$(echo "$DASHBOARD_RAW" | jq '
        if .dashboard.schemaVersion < 41 then
            .dashboard.schemaVersion = 41
        else
            .
        end
        | .dashboard.panels |= (map(
            if .fieldConfig? and .fieldConfig.defaults? and .fieldConfig.defaults.thresholds? then
                .fieldConfig.defaults.thresholds.steps |= map(
                    if (.value == "") then .value = null else . end
                )
            else .
            end
        ) // .dashboard.panels)
    ')

    echo "[$COUNTER/$TOTAL_DASHES] Saving: $TITLE -> $SAFE_TITLE.json"
    echo "$DASHBOARD_FIXED" | jq '.dashboard' > "$OUTPUT_FILE"
done

rm -f "$DASH_LIST_FILE"

$SETCOLOR_TITLE_GREEN
echo "|---------------------Dashboards have been exported successfully----------------|"
$SETCOLOR_NORMAL


$SETCOLOR_NUMBERS
echo "|------------------------------START COPY ALERT---------------------------------|";
$SETCOLOR_NORMAL

if make_curl_request "$HOST/api/v1/provisioning/alert-rules/" "$ALERT_DIR/alert_rules.json" "alert rules"; then
    $SETCOLOR_TITLE_GREEN
    echo "|---------------------The alert rules has been exported-------------------------|"
    $SETCOLOR_NORMAL
else
    exit 1
fi

$SETCOLOR_NUMBERS
echo "|--------------------------START COPY DATA SOURCES------------------------------|";
$SETCOLOR_NORMAL

if make_curl_request "$HOST/api/datasources/" "$DATA_DIR/data_sources.json" "data sources"; then
    $SETCOLOR_TITLE_GREEN
    echo "|---------------------The data sources has been exported------------------------|"
    $SETCOLOR_NORMAL
else
    exit 1
fi

$SETCOLOR_NUMBERS
echo "|-------------------------START COPY CONTACT POINTS-----------------------------|";
$SETCOLOR_NORMAL

if make_curl_request "$HOST/api/v1/provisioning/contact-points" "$CONTACT_DIR/contact_points.json" "contact points"; then
    $SETCOLOR_TITLE_GREEN
    echo "|---------------------The contact points has been exported----------------------|"
    $SETCOLOR_NORMAL
else
    exit 1
fi

if [ "$GIT_PUSH_ENABLED" = "true" ]; then
     cd "$BCKP_PATH"

     CURRENT_REPO=$(git remote get-url origin 2>/dev/null)

     if [ "$CURRENT_REPO" = "$REPO_SSH" ] || [ "$CURRENT_REPO" = "$REPO_HTTPS" ]; then
          echo "please switch repo"
          exit 1
     else
          git add .
          git commit -m 'Update configs'
          git push
     fi
else
     echo "Skipping git operations."
fi

$SETCOLOR_TITLE
echo "|----------------------------------FINISHED-------------------------------------|";
$SETCOLOR_NORMAL