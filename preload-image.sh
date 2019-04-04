#!/usr/bin/env bash
set -ex

# env vars from balena.env:
# APP_NAME
# APP_ID
# APP_DEVICE_TYPE

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

./check-configuration.sh || exit 1

APP_COMMIT=${1:-$APP_COMMIT}
APP_VERSION=${2:-$APP_VERSION}
APP_API_KEY=${3:-$APP_API_KEY}
APP_OS_VERSION=${4:-APP_OS_VERSION}
S3_BUCKET=${5:-S3_BUCKET}

if [ -z "$APP_COMMIT" ]; then echo "Error: APP_COMMIT isnt set"; exit 1; fi 
if [ -z "$APP_VERSION" ]; then echo "Error: APP_VERSION isnt set"; exit 1; fi 
if [ -z "$APP_API_KEY" ]; then echo "Error: APP_API_KEY isnt set"; exit 1; fi 
if [ -z "$APP_OS_VERSION" ]; then echo "Error: APP_OS_VERSION isnt set"; exit 1; fi 
if [ -z "$S3_BUCKET" ]; then echo "Error: S3_BUCKET isnt set"; exit 1; fi 

BUILD_PATH="/tmp"
APP_IMG="${APP_NAME}_${APP_DEVICE_TYPE}_v${APP_VERSION}_${APP_COMMIT_TAG}.img"
APP_IMG_ZIP="${APP_NAME}_${APP_DEVICE_TYPE}_v${APP_VERSION}_${APP_COMMIT_TAG}.zip"
APP_IMG_PATH="$BUILD_PATH/$APP_IMG"
APP_IMG_ZIP_PATH="$BUILD_PATH/$APP_IMG_ZIP"
APP_CONFIG_PATH="$BUILD_PATH/config.json"

# Download Balena OS
echo "Downloading image version $APP_OS_VERSION for device type $APP_DEVICE_TYPE"
balena os download $APP_DEVICE_TYPE \
    --output $APP_IMG_PATH \
    --version $APP_OS_VERSION

# Load app onto image
balena preload $APP_IMG_PATH \
    --app $APP_ID \
    --commit $APP_COMMIT \
    --pin-device-to-release

echo "{\"apiKey\": \"$APP_API_KEY\"}" > $APP_CONFIG_PATH

# Load config into app image
# --deviceApiKey $APP_API_KEY
balena os configure $APP_IMG_PATH \
    --app $APP_NAME \
    --version $APP_OS_VERSION \
    --config $APP_CONFIG_PATH
 
zip -j $APP_IMG_ZIP_PATH $APP_IMG_PATH

aws s3 cp $APP_IMG_ZIP_PATH s3://$S3_BUCKET/$APP_NAME/"v${APP_VERSION}"/$APP_IMG_ZIP