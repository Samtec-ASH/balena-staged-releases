#!/usr/bin/env bash
# This file checks that the settings in resin.env are loaded and authenticating correctly

# Make this be left to user to source to allow different folder
# source ./resin.env

response=$(curl --silent "https://api.$BASE_URL/user/v1/whoami" -H "Authorization: Bearer $authToken")

if [ $? -ne 0 ]; then
    echo "Could not authenticate to '$BASE_URL', please check your configuration"
    exit 1
fi
