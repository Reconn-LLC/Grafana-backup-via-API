#!/bin/bash

if [ ! -f "./.env" ]; then
    $SETCOLOR_FAILURE
    echo "ERROR: .env file not found!"
    echo "Please copy env.example to .env and configure your settings"
    $SETCOLOR_NORMAL
    exit 1
fi

source $(pwd)/.env

$SETCOLOR_TITLE
echo "|-------------------------------START UPDATE------------------------------------|"
$SETCOLOR_NORMAL

$SETCOLOR_TITLE_PURPLE
echo "|-------------------------START UPDATE DATA SOURCES-----------------------------|"
$SETCOLOR_NORMAL
jq -c '.[]' $DATA_FILE | while read -r ds; do
    if [ -n "$ds" ]; then
        uid=$(echo "$ds" | jq -r '.uid // empty')
        if [ -n "$uid" ]; then
            curl -sS -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $KEY" \
                -d "$ds" \
                "$HOST/api/datasources/uid/$uid"
            echo
        else
            echo "Warning: No UID found in datasource entry"
        fi
    fi
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|"
$SETCOLOR_NORMAL

# ====================== UPDATE GRAFANA DASHBOARDS =========================

$SETCOLOR_NUMBERS
echo "|----------------------------START DASHBOARDS UPDATE----------------------------|";
$SETCOLOR_NORMAL

# Проверка директории с дашбордами
if [ ! -d "$DASH_DIR" ]; then
    $SETCOLOR_FAILURE
    echo "ERROR: Dashboards directory not found: $DASH_DIR"
    $SETCOLOR_NORMAL
    exit 1
fi

TOTAL=$(find "$DASH_DIR" -type f -name "*.json" | wc -l | tr -d ' ')
PROCESSED=0
SUCCESS=0
SKIPPED=0
FAILED=0

echo "Found $TOTAL dashboards — processing..."

for DASH_FILE in "$DASH_DIR"/*.json; do
    ((PROCESSED++))

    TITLE=$(jq -r '.dashboard.title // .title // "unnamed"' "$DASH_FILE" 2>/dev/null)
    DASH_UID=$(jq -r '.dashboard.uid // .uid // empty' "$DASH_FILE" 2>/dev/null)
    FOLDER_UID=$(jq -r '.meta.folderUid // .folderUid // ""' "$DASH_FILE" 2>/dev/null)

    if [ -z "$DASH_UID" ] || [ "$DASH_UID" = "null" ]; then
        $SETCOLOR_FAILURE
        echo "[$PROCESSED/$TOTAL] ERROR: UID missing in $DASH_FILE — skipping."
        $SETCOLOR_NORMAL
        ((FAILED++))
        continue
    fi

    # Проверка существования дашборда
    HTTP_CODE=$(curl -sS -k -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer $KEY" \
        "$HOST/api/dashboards/uid/$DASH_UID")

    if [ "$HTTP_CODE" -eq 200 ]; then
        $SETCOLOR_WARNING
        echo "[$PROCESSED/$TOTAL] Skipping existing dashboard: $TITLE (UID: $DASH_UID)"
        $SETCOLOR_NORMAL
        ((SKIPPED++))
        continue
    fi

    TMP_JSON=$(mktemp)
    jq --arg folderUid "$FOLDER_UID" '. + {folderUid: $folderUid}' "$DASH_FILE" > "$TMP_JSON"

    RESPONSE=$(curl -sS -k -X POST \
        -H "Authorization: Bearer $KEY" \
        -H "Content-Type: application/json" \
        -d @"$TMP_JSON" \
        "$HOST/api/dashboards/db")

    STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
    if [ "$STATUS" = "success" ]; then
        $SETCOLOR_TITLE_GREEN
        echo "[$PROCESSED/$TOTAL] Created dashboard: $TITLE (UID: $DASH_UID)"
        $SETCOLOR_NORMAL
        ((SUCCESS++))
    else
        $SETCOLOR_FAILURE
        echo "[$PROCESSED/$TOTAL] ERROR: Failed to create dashboard: $TITLE"
        echo "Response: $RESPONSE"
        $SETCOLOR_NORMAL
        ((FAILED++))
    fi

    rm -f "$TMP_JSON"
done

echo ""
$SETCOLOR_TITLE
echo "|----------------------------SUMMARY DASHBOARDS----------------------------------|"
$SETCOLOR_NORMAL
echo "Processed: $PROCESSED"
echo "  Created : $SUCCESS"
echo "  Skipped : $SKIPPED"
echo "  Failed  : $FAILED"

if [ "$FAILED" -eq 0 ]; then
    $SETCOLOR_TITLE_GREEN
    echo "✅ All dashboards processed successfully."
    $SETCOLOR_NORMAL
else
    $SETCOLOR_FAILURE
    echo "⚠️ Some dashboards failed to update. Check logs above."
    $SETCOLOR_NORMAL
fi

$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|"
$SETCOLOR_NORMAL

$SETCOLOR_TITLE_PURPLE
echo "|------------------------START UPDATE CONTACT POINTS----------------------------|"
$SETCOLOR_NORMAL
jq -c '.[]' $CONTACT_FILE | while read -r ds; do
    if [ -n "$ds" ]; then
        uid=$(echo "$ds" | jq -r '.uid // empty')
        if [ -n "$uid" ]; then
            curl -sS -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $KEY" \
                -d "$ds" \
                "$HOST/api/v1/provisioning/contact-points/$uid"
            echo
        else
            echo "Warning: No UID found in contact-point entry"
        fi
    fi
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|"
$SETCOLOR_NORMAL

$SETCOLOR_TITLE_PURPLE
echo "|--------------------------START UPDATE ALERT RULES-----------------------------|"
$SETCOLOR_NORMAL
jq -c '.[]' $ALERT_FILE | while read -r ds; do
    if [ -n "$ds" ]; then
        uid=$(echo "$ds" | jq -r '.uid // empty')
        if [ -n "$uid" ]; then
            curl -sS -X PUT \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $KEY" \
                -d "$ds" \
                "$HOST/api/v1/provisioning/alert-rules/$uid"
            echo
        else
            echo "Warning: No UID found in alert-rule entry"
        fi
    fi
done
$SETCOLOR_TITLE_GREEN
echo "|----------------------------------FINISHED-------------------------------------|"
$SETCOLOR_NORMAL

$SETCOLOR_TITLE
echo "|-------------------------------FINISHED UPDATE---------------------------------|"
$SETCOLOR_NORMAL
