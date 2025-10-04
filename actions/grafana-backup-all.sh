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

$SETCOLOR_NUMBERS
echo "|-------------------------------START COPY DASH---------------------------------|";
$SETCOLOR_NORMAL

if make_curl_request "$HOST/apis/dashboard.grafana.app/v1beta1/namespaces/default/dashboards" "$DASH_DIR/dash.json" "dashboards"; then
    $SETCOLOR_TITLE_GREEN
    echo "|---------------------The dashboard has been exported---------------------------|"
    $SETCOLOR_NORMAL
else
    exit 1
fi

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