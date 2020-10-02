#!/bin/bash

# configure vars

DB_USER="mmuser"
DB_NAME="mattermost"
DB_PASS=""
DB_HOST="db"
RETENTION="0"
DATA_PATH="/mattermost/data/"

# calculate epoch in milisec
delete_before=$(date  --date="$RETENTION day ago"  "+%s%3N")
#delete_before=$(date  "+%s%3N")
echo $(date  --date="$RETENTION day ago")
# run psql command do delete posts older than RETENTION var
export PGPASSWORD=$DB_PASS

# get list of files to be removed
psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select path from fileinfo where createat < $delete_before;" > /tmp/mattermost-paths.list
psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select thumbnailpath from fileinfo where createat < $delete_before;" >> /tmp/mattermost-paths.list
psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select previewpath from fileinfo where createat < $delete_before;" >> /tmp/mattermost-paths.list

# cleanup db 
psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "delete from posts where createat < $delete_before;"
psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "delete from fileinfo where createat < $delete_before;"

# delete files
while read -r fp; do
        if [ -n "$fp" ]; then
                echo "$DATA_PATH""$fp"
                shred -u "$DATA_PATH""$fp"
        fi
done < /tmp/mattermost-paths.list

#cleanup after yourself
rm /tmp/mattermost-paths.list

#cleanup empty data dirs
find $DATA_PATH -type d -empty -delete
exit 0

