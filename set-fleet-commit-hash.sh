#!/usr/bin/env bash
## This script sets the fleet wide commit hash to a specified value.
## It is usually used after one has disabled rolling releases and allows one
## to set an entire fleet to any specific build in their list of builds for an App.

./check-configuration.sh || exit 1

# Make this be left to user to source to allow different folder
# source ./balena.env

COMMIT_HASH=$1
echo "setting APP: $APP_ID to COMMIT == $COMMIT_HASH"
curl -X PATCH "https://api.$BASE_URL/v4/application($APP_ID)" -H "Authorization: Bearer $BALENA_AUTH_TOKEN" -H "Content-Type: application/json" --data-binary '{"commit":"'$COMMIT_HASH'"}'
