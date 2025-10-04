if [ ! -f ".env" ]; then
    $SETCOLOR_FAILURE
    echo "ERROR: .env file not found!"
    echo "Please copy env.example to .env and configure your settings"
    $SETCOLOR_NORMAL
    exit 1
fi

source .env

$SETCOLOR_TITLE # задаём цвет
echo "|-------------------------------START UPDATE------------------------------------|"; # говорим о старте програмы
$SETCOLOR_NORMAL # возвращаем цвет

$SETCOLOR_TITLE_PURPLE # задаём другой цвет 
echo "|-------------------------START UPDATE DATA SOURCES-----------------------------|"; # говорим о начале апдейта 
$SETCOLOR_NORMAL # вовзращаем цвет
jq -c '.[]' $DATA_FILE.json | while read -r ds; do # парсим файл и посторочно передаём его в ds
    #тут мы задаём бесшумный режим, метод PUT, заголовки, ключ, и тело в виде перемноо ds, путь куда это отдаём, и uid через распарсивание файла
    curl -sS -X PUT \ 
        -H "Content-Type: application/json" \ 
        -H "Authorization: Bearer $KEY" \
        -d "$ds" \
        "$HOST/api/datasources/uid/$(echo "$ds" | jq -r '.uid')"
    echo
done
$SETCOLOR_TITLE_GREEN # меняем цвет
echo "|----------------------------------FINISHED-------------------------------------|"; # говорим, что закончили апдейт дашбордов
$SETCOLOR_NORMAL # возвращаем цвет
# колесо сансары дало оборот

$SETCOLOR_TITLE_PURPLE
echo "|--------------------------START UPDATE DASHBOARDS------------------------------|";
$SETCOLOR_NORMAL
jq -c '.[]' $DASH_FILE.json | while read -r ds; do
    curl -sS -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $KEY" \
        -d "$ds" \
        "$HOST/apis/dashboard.grafana.app/v1beta1/namespaces/default/dashboards/$(echo "$ds" | jq -r '.uid')"
    echo
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|";
$SETCOLOR_NORMAL

$SETCOLOR_TITLE_PURPLE
echo "|------------------------START UPDATE CONTACT POINTS----------------------------|";
$SETCOLOR_NORMAL
jq -c '.[]' $CONTACT_FILE.json | while read -r ds; do
    curl -sS -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $KEY" \
        -d "$ds" \
        "$HOST/api/v1/provisioning/contact-points/$(echo "$ds" | jq -r '.uid')"
    echo
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|";
$SETCOLOR_NORMAL

$SETCOLOR_TITLE_PURPLE
echo "|--------------------------START UPDATE ALERT RULES-----------------------------|";
$SETCOLOR_NORMAL
jq -c '.[]' $ALERT_FILE.json | while read -r ds; do
    curl -sS -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $KEY" \
        -d "$ds" \
        "$HOST/api/v1/provisioning/alert-rules/$(echo "$ds" | jq -r '.uid')"
    echo
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|";
$SETCOLOR_NORMAL


$SETCOLOR_TITLE
echo "|-------------------------------FINISHED UPDATE---------------------------------|";
$SETCOLOR_NORMAL
