#!/bin/bash -x
set -e

# Check for the required variables to make the user.
if [ -z "${MYSQL_HOST}" ]; then
	echo "! Error, no MYSQL_HOST variable specified !"
	exit 1
elif [ -z "${MYSQL_USERNAME}" ]; then
	echo "! Error, no MYSQL_USERNAME variable specified !"
	exit 1
elif [ -z "${MYSQL_PASSWORD}" ]; then
	echo "! Error, no MYSQL_PASSWORD variable specified !"
	exit 1
elif [ -z "${BUCKET_HOST}" ]; then
	echo "! Error, no BUCKET_HOST variable specified !"
	exit 1
elif [ -z "${BUCKET_NAME}" ]; then
	echo "! Error, no BUCKET_NAME variable specified !"
	exit 1
elif [ -z "${BUCKET_URL}" ]; then
	echo "! Error, no BUCKET_ACCESSKEY variable specified !"
	exit 1
elif [ -z "${BUCKET_ACCESSKEY}" ]; then
	echo "! Error, no BUCKET_ACCESSKEY variable specified !"
	exit 1
elif [ -z "${BUCKET_SECRET}" ]; then
	echo "! Error, no BUCKET_SECRET variable specified !"
	exit 1
fi

# Create the config
mv config.json.template config.json
sed -i "s/##MYSQL_HOST##/${MYSQL_HOST}/g" config.json
sed -i "s/##MYSQL_USERNAME##/${MYSQL_USERNAME}/g" config.json
sed -i "s/##MYSQL_PASSWORD##/${MYSQL_PASSWORD}/g" config.json
sed -i "s/##BUCKET_HOST##/${BUCKET_HOST}/g" config.json
sed -i "s/##BUCKET_NAME##/${BUCKET_NAME}/g" config.json

# Minio client login
mc alias set "${BUCKET_HOST}" "${BUCKET_URL}" "${BUCKET_ACCESSKEY}" "${BUCKET_SECRET}"

# Start the webserver
gunicorn --bind 0.0.0.0:5000 webserver:api
