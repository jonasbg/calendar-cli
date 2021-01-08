#!/bin/sh

if [ "$(cat /data/FLAG)" == 0 ]; then echo "[EXIT] No change detected" && exit 0; fi

CALDAV_URL=$1
CALDAV_USER=$2
CALDAV_PASS=$3
CALDAV_CALENDAR_URL=$4
TODAY=$(date '+%F'  -d '-1 month')
CALENDAR="/data/calendar.json"
WORKBOOK="/data/workbook.json"
CALENDAR_CLI="/app/calendar-cli --timezone="Europe/Oslo" --caldav-url=$CALDAV_URL --caldav-user=$CALDAV_USER --caldav-pass=$CALDAV_PASS --calendar-url=$CALDAV_CALENDAR_URL"

validate_json() {
    if [ $(cat $1 | jq length) -gt 0 ]; 
    then 
        echo "$1 VALIDATED as JSON"
    else
        echo "$1 is not a valid JSON format"
        exit 1
    fi
} 

validate_json $CALENDAR
validate_json $WORKBOOK

echo "[INFO] Deleting old entries"
COUNTER=0
for uid in $($CALENDAR_CLI calendar agenda --from-time=$TODAY --agenda-days=180 --event-template='{uid}') ; do $CALENDAR_CLI calendar delete --event-uid=$uid && COUNTER=$((COUNTER + 1)); done
echo "[INFO] Deleted $COUNTER entries"

cat $CALENDAR | jq '.ShiftEvents | map(select(.WorkHours >= 2))' | jq -c '.[]'  | while read i; do
    fromDate=$(echo $i | jq '.From' | tr -d '"')
    hours=$(echo $i | jq '.WorkHours')
    toDate=$(echo $i | jq '.To' | tr -d '"')
    summary=$(echo $i | jq '.CategoryName' | tr -d '"')
    department=$(echo $i | jq '.DepartmentName' | tr -d '"')

    file="/tmp/events.tmp"
    echo "AVDELING: $department\n" > $file
    cat $WORKBOOK | jq '.[] | select(.AbsoluteFromTime=="'$fromDate'")' | jq -c | while read i; do
        fullName=$(echo $i | jq '.FullName'| tr -d '"')
        role=$(echo $i | jq '.Roles'| tr -d '"')
        initials=$(echo $i | jq '.Initials'| tr -d '"')
        avdeling=$(echo $i | jq '.GroupCode'| tr -d '"')
        if [ "$initials" = "IM6" ]; then
            sed -i "2i [$avdeling]\n$fullName\n$role\n" $file
        else
            echo "[$avdeling]\n$fullName\n$role\n" >> $file
        fi
    done
    $CALENDAR_CLI calendar add "${fromDate}+${hours}h" "$summary" "$(cat $file)"
done
echo "[FINISHED] Added entries to calendar"
echo 0 > /data/FLAG
