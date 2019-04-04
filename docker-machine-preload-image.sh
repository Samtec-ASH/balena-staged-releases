#!/usr/bin/env bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

APP_COMMIT=$1
APP_OS_VERSION=$2
HOST_BUILD_PATH=$3

./check-configuration.sh || exit 1
# source ./balena.env
# BALENA_AUTH_TOKEN
# APP_NAME
# APP_ID
# APP_DEVICE_TYPE


BALENA_CLI="v9.12.0"
MACHINE_NAME="samtec-ash"
# HOST_BUILD_PATH="$DIR/../images"
MACHINE_BUILD_PATH="/tmp"
BALENA_IMG="${APP_NAME}_${APP_COMMIT}.img"
MACHINE_BALENA_IMG_PATH="$MACHINE_BUILD_PATH/$BALENA_IMG"
HOST_BALENA_IMG_PATH="$HOST_BUILD_PATH/$BALENA_IMG"

docker-machine ls | grep -q $MACHINE_NAME
if [[ $? -ne 0 ]]; then
  docker-machine create --driver virtualbox --virtualbox-memory 8192 --engine-storage-driver aufs $MACHINE_NAME
  echo "Created docker machine $MACHINE_NAME"
else
  docker-machine start $MACHINE_NAME
  echo "Using existing docker machine $MACHINE_NAME"
fi

docker-machine ssh $MACHINE_NAME "which balena"
if [[ $? -ne 0 ]]; then
  docker-machine ssh $MACHINE_NAME "tce-load -wi bash && \
    wget -q https://github.com/balena-io/balena-cli/releases/download/$BALENA_CLI/balena-cli-$BALENA_CLI-linux-x64.zip -O /tmp/balena-cli-linux-x64.zip && \
    cd /tmp && \
    unzip balena-cli-linux-x64.zip && \
    sudo chmod +x ./balena-cli/balena && \
    sudo rm -rf /usr/local/balena-cli && \
    sudo mv ./balena-cli /usr/local/balena-cli && \
    sudo ln -fs /usr/local/balena-cli/balena /usr/bin/balena && \
    rm -f balena-cli-linux-x64.zip && \
    sudo mkdir -p ~/.balena"
  echo "Configured docker machine with balena $MACHINE_NAME"
else
  echo "Docker machine $MACHINE_NAME already configured"
fi

docker-machine ssh $MACHINE_NAME "cd /tmp && \
  echo $MACHINE_BALENA_IMG_PATH && \
  sudo balena login --token $BALENA_AUTH_TOKEN && \
  sudo balena os download $APP_DEVICE_TYPE -o $MACHINE_BALENA_IMG_PATH --version $APP_OS_VERSION && \
  sudo balena preload $MACHINE_BALENA_IMG_PATH --app $APP_ID --commit $APP_COMMIT --pin-device-to-release"
echo "Done"

mkdir -p $HOST_BUILD_PATH
docker-machine scp $MACHINE_NAME:$MACHINE_BALENA_IMG_PATH $HOST_BALENA_IMG_PATH

# aws s3 cp $HOST_BALENA_IMG_PATH s3://$S3_BUCKET/$APP_NAME/$BALENA_IMG
