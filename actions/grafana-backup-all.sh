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



$SETCOLOR_NUMBERS
echo "|-------------------------------START COPY DASH---------------------------------|";
$SETCOLOR_NORMAL

curl -sS -k -H "Authorization: Bearer $KEY" $HOST/apis/dashboard.grafana.app/v1beta1/namespaces/default/dashboards  | jq . > $DASH_DIR/dash.json
$SETCOLOR_TITLE_GREEN
echo "|---------------------The dashboard has been exported---------------------------|"
$SETCOLOR_NORMAL



$SETCOLOR_NUMBERS
echo "|------------------------------START COPY ALERT---------------------------------|";
$SETCOLOR_NORMAL

curl -sS -k -H "Authorization: Bearer $KEY" $HOST/api/v1/provisioning/alert-rules/ | jq . > $ALERT_DIR/alert_rules.json
$SETCOLOR_TITLE_GREEN
echo "|---------------------The alert rules has been exported-------------------------|"
$SETCOLOR_NORMAL



$SETCOLOR_NUMBERS
echo "|--------------------------START COPY DATA SOURCES------------------------------|";
$SETCOLOR_NORMAL

curl -sS -k -H "Authorization: Bearer $KEY" $HOST/api/datasources/ | jq . > $DATA_DIR/data_sources.json
$SETCOLOR_TITLE_GREEN
echo "|---------------------The data sources has been exported------------------------|"
$SETCOLOR_NORMAL



$SETCOLOR_NUMBERS
echo "|-------------------------START COPY CONACT POINTS------------------------------|";
$SETCOLOR_NORMAL

curl -sS -k -H "Authorization: Bearer $KEY" $HOST/api/v1/provisioning/contact-points | jq . > $CONTACT_DIR/contact_points.json
$SETCOLOR_TITLE_GREEN
echo "|------------------The contact points hasnt been exported-----------------------|"
$SETCOLOR_NORMAL

if [ "$GIT_PUSH_ENABLED" = "true" ]; then
     cd /srv/grf_bkp

     СURRENT_REPO=$(git remote get-url origin 2>/dev/null)

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
