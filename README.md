# Mattermost data cleanup/retention
Free version of mattermost doesn't provide any message/attachment retention settings so this simple script cleans up posts and attachments 
# Usage
Script can work on standalone or dockerized deployment, however in the case of docker you must run it on application container (otherwise it wont be able to delete the files from the system. It was tested with official mattermost docker deployment. 
# Note
This script currently supports mattermost instances using both mysql or postgres database.  
Just specify `mysql` or `postgres` on the [DB_DRIVE](https://github.com/aljazceru/mattermost-retention/blob/master/mattermost-retention.sh#L26) variable.
