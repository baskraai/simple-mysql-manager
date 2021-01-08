#!/bin/bash

# Get the credentials from the configfile.
MYSQL_HOST=$(jq '.mysql.host' < config.json)
MYSQL_HOST=${MYSQL_HOST%\"}
MYSQL_HOST=${MYSQL_HOST#\"}
MYSQL_USERNAME=$(jq '.mysql.username' < config.json)
MYSQL_USERNAME=${MYSQL_USERNAME%\"}
MYSQL_USERNAME=${MYSQL_USERNAME#\"}
MYSQL_PASSWORD=$(jq '.mysql.password' < config.json)
MYSQL_PASSWORD=${MYSQL_PASSWORD%\"}
MYSQL_PASSWORD=${MYSQL_PASSWORD#\"}
BUCKET_HOST=$(jq '.bucket.host' < config.json)
BUCKET_HOST=${BUCKET_HOST%\"}
BUCKET_HOST=${BUCKET_HOST#\"}
BUCKET_NAME=$(jq '.bucket.name' < config.json)
BUCKET_NAME=${BUCKET_NAME%\"}
BUCKET_NAME=${BUCKET_NAME#\"}

# Get the database and backupname
MYSQL_DATABASE="$1"
BACKUPNAME="$2"

# Set the PID-file
mkdir -p /tmp/mysqldump
touch /tmp/mysqldump/"$2.pid"

# Create the backup
if [ "${MYSQL_PASSWORD}" == "" ]; then
	mysqldump -h "${MYSQL_HOST}" -u "${MYSQL_USERNAME}" "${MYSQL_DATABASE}" > "/tmp/mysqldump/${BACKUPNAME}.sql"
else
	mysqldump -h "${MYSQL_HOST}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" > "/tmp/mysqldump/${BACKUPNAME}.sql"
fi

if [ ! $? -eq 0 ]; then
	rm -f /tmp/mysqldump/"$2.pid"
	rm -f /tmp/mysqldump/"${BACKUPNAME}.sql"
	echo "MySQL Dump failed" > /tmp/mysqldump/"$2.error"
	xit 1
fi

# Copy the sql-file to the bucket
mc cp /tmp/mysqldump/"${BACKUPNAME}.sql" "${BUCKET_HOST}"/"${BUCKET_NAME}"

if [ ! $? -eq 0 ]; then
	rm -f /tmp/mysqldump/"$2.pid"
	rm -f /tmp/mysqldump/"${BACKUPNAME}.sql"
	echo "Minio place failed" > /tmp/mysqldump/"$2.error"
	exit 1
else
	rm -f /tmp/mysqldump/"${BACKUPNAME}.pid"
	rm -f /tmp/mysqldump/"${BACKUPNAME}.sql"
	touch /tmp/mysqldump/"${BACKUPNAME}.succesful"
fi
