#!/bin/bash

echo "Downloading the newest GeneBe Client JAR"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/pstawinski/genebe-cli/releases/latest)
JAR_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
GENEBE_CLIENT_JAR="genebe-cli-latest.jar"

if [[ -n "$JAR_URL" ]]; then
    echo "Downloading: $JAR_URL"
    curl -L -o $GENEBE_CLIENT_JAR "$JAR_URL"
else
    echo "No JAR file found in the latest release."
    exit 1
fi
