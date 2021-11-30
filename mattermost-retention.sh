#!/bin/bash

###
# configure vars
####

# Database user name
DB_USER="mmuser"

# Database name
DB_NAME="mattermost"

# Database password
DB_PASS=""

# Database hostname
DB_HOST="127.0.0.1"

# How many days to keep of messages/files?
RETENTION="30"

# Mattermost data directory
DATA_PATH="/opt/mattermost/data/"

# Database drive (postgres OR mysql)
DB_DRIVE="mysql"

###
# calculate epoch in milisec
###
delete_before=$(date  --date="$RETENTION day ago"  "+%s%3N")
echo $(date  --date="$RETENTION day ago")

case $DB_DRIVE in

  postgres)
        echo "Using postgres database."
        export PGPASSWORD=$DB_PASS

        ###
        # get list of files to be removed
        ###
        psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select path from fileinfo where createat < $delete_before;" > /tmp/mattermost-paths.list
        psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select thumbnailpath from fileinfo where createat < $delete_before;" >> /tmp/mattermost-paths.list
        psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "select previewpath from fileinfo where createat < $delete_before;" >> /tmp/mattermost-paths.list

        ###
        # cleanup db
        ###
        psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "delete from posts where createat < $delete_before;"
        psql -h "$DB_HOST" -U"$DB_USER" "$DB_NAME" -t -c "delete from fileinfo where createat < $delete_before;"
    ;;

  mysql)
        echo "Using mysql database."

        ###
        # get list of files to be removed
        ###
        mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="select path from FileInfo where createat < $delete_before;" > /tmp/mattermost-paths.list
        mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="select thumbnailpath from FileInfo where createat < $delete_before;" >> /tmp/mattermost-paths.list
        mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="select previewpath from FileInfo where createat < $delete_before;" >> /tmp/mattermost-paths.list

        ###
        # cleanup db
        ###
        mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="delete from Posts where createat < $delete_before;"
        mysql --password=$DB_PASS --user=$DB_USER --host=$DB_HOST --database=$DB_NAME --execute="delete from FileInfo where createat < $delete_before;"
    ;;
  *)
        echo "Unknown DB_DRIVE option. Currently ONLY mysql AND postgres are available."
        exit 1
    ;;
esac

###
# delete files
###
while read -r fp; do
        if [ -n "$fp" ]; then
                echo "$DATA_PATH""$fp"
                shred -u "$DATA_PATH""$fp"
        fi
done < /tmp/mattermost-paths.list

###
# cleanup after script execution
###
rm /tmp/mattermost-paths.list

###
# cleanup empty data dirs
###
find $DATA_PATH -type d -empty -delete
exit 0
