#!/bin/bash

# Container name
CONTAINER_NAME="mydb"

# Container port
CONTAINER_PORT=5435

# Define database credentials
DB_USER="myuser"
DB_PASSWORD="myuserpassword"
DB_NAME="mydb"
BACKUP_DIR="/root/backups"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Define dump file name
DUMP_FILE="${DB_NAME}_backup_${TIMESTAMP}.sql"

# Execute pg_dump inside the container and save dump to a file, port on which db container is running
docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER -d $DB_NAME -p $CONTAINER_PORT > $BACKUP_DIR/$DUMP_FILE

# RETENTION POLCIY
RETENTION_DAYS=7
find $BACKUP_DIR -name "${DB_NAME}_backup_*.sql" -mtime +$RETENTION_DAYS -exec rm {} \;

echo "Script Executed Successfully"


# RESTORING BACKUP IN LOCAL PGADMIN
# 1. create a new database where you want to restore 
# 2. right click on the database and open psql tool
# 4. run this command -  \i '<BACKUP-PATH>'    example: \i 'E:/BACKUPS/mydb_backup_20241022010002.sql'
