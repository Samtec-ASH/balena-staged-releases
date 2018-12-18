#!/usr/bin/env bash
## This script returns the `device_id` for a specific device on a resin.io application.
## usage: ./get-device-id.sh <DEVICE_UUID>

./check-configuration.sh || exit 1

DEVICE_UUID=$1

# Make this be left to user to source to allow different folder
# source ./balena.env

curl "https://api.$BASE_URL/v4/device?\$select=id,uuid&\$filter=uuid%20eq%20'$DEVICE_UUID'" -H "Authorization: Bearer $BALENA_AUTH_TOKEN" | jq '.d[0].id'
