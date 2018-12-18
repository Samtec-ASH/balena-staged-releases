#!/usr/bin/env bash
set -ex

function create_uuid() {
  echo $(python -c 'import sys,uuid; sys.stdout.write(uuid.uuid4().hex)')
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

./check-configuration.sh || exit 1

# source ./balena.env

# sudo balena util available-drives
APP_COMMIT=$1
DEVICE_UUID=${2:-$(create_uuid)}
SD_DRIVE_PATH=$3

BUILD_PATH="/tmp"
BALENA_CONFIG_PATH="$BUILD_PATH/config.json"
BALENA_IMG="${APP_NAME}_${APP_COMMIT}.img"
BALENA_IMG_CACHE_PATH="$BUILD_PATH/$BALENA_IMG.cache"
BALENA_IMG_PATH="$BUILD_PATH/$BALENA_IMG"

# Log into balena
balena login --token $BALENA_AUTH_TOKEN
echo "Logged into balena"

# Download app image from S3
# TODO: check if file exists locally already
aws s3 cp s3://$S3_BUCKET/$APP_NAME/$BALENA_IMG $BALENA_IMG_CACHE_PATH
cp $BALENA_IMG_CACHE_PATH $BALENA_IMG_PATH

# Register device
balena device register $APP_NAME --uuid $DEVICE_UUID
echo "Registered device $DEVICE_UUID"

# Pin the new device to this commit
./set-device-to-a-release.sh $DEVICE_UUID $APP_COMMIT
echo "Pinned device $DEVICE_UUID to commit $APP_COMMIT"

# Generate device config
balena config generate --application $APP_NAME --device $DEVICE_UUID --network ethernet --appUpdatePollInterval 10 --version $APP_OS_VERSION --output $BALENA_CONFIG_PATH
echo "Generated config for device $DEVICE_UUID"

# Configure OS image for new device with
balena os configure $BALENA_IMG_PATH --device $DEVICE_UUID --config $BALENA_CONFIG_PATH

# Load image onto disk
sudo balena local flash $BALENA_IMG_PATH --drive $SD_DRIVE_PATH --yes
