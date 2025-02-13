#!/bin/bash

GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

REG_TOKEN=$(curl -sX POST -H "X-GitHub-Api-Version: 2022-11-28" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GH_TOKEN}" https://api.github.com/orgs/${GH_OWNER}/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --unattended --url https://github.com/${GH_OWNER} --token ${REG_TOKEN} --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
