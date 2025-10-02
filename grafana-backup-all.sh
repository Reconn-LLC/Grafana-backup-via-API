SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

SETCOLOR_TITLE="echo -en \\033[1;36m" #Fuscia
SETCOLOR_TITLE_GREEN="echo -en \\033[0;32m" #green
SETCOLOR_TITLE_PURPLE="echo -en \\033[0;35m" #purple
SETCOLOR_NUMBERS="echo -en \\033[0;34m" #BLUE

KEY="youre_key"
HOST="youre_host"
DASH_DIR="/srv/grf_bkp/grafana-dashboards-backup/"
ALERT_DIR="/srv/grf_bkp/grafana-alerts-backup/"
DATA_DIR="/srv/grf_bkp/grafana-data-sources-backup/"
CONTACT_DIR="/srv/grf_bkp/grafana-contact-points-sources-backup/"

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


$SETCOLOR_TITLE
echo "|----------------------------------FINISHED-------------------------------------|";
$SETCOLOR_NORMAL


cd /srv/grf_bkp
git add .
git commit -m 'Update configs'
git push
