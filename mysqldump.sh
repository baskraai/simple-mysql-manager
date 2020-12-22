#!/bin/bash

# Get the credentials from the configfile.
MYSQL_HOST=$(jq '.mysql.host' < config.json)
MYSQL_USERNAME=$(jq '.mysql.username' < config.json)
MYSQL_PASSWORD=$(jq '.mysql.password' < config.json)

# Get the database and backupname
MYSQL_DATABASE="$1"
BACKUPNAME="$2"

# Set the PID-file
mkdir -p /tmp/mysqldump
touch /tmp/mysqldump/"$2.pid"

# Create the backup
mysqldump -h "${MYSQL_HOST}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" > "/tmp/mysqldump/${BACKUPNAME}.sql"

if [ ! $? -eq 0 ]; then
	rm -f /tmp/mysqldump/"$2.pid"
	rm -f /tmp/mysqldump/"${BACKUPNAME}.sql"
	touch /tmp/mysqldump/"$2.error"
else
	rm -f /tmp/mysqldump/"$2.pid"
fi
