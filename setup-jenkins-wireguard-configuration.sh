#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

aws ssm put-parameter \
    --name "/jenkins/dev/wg0.conf" \
    --value "$(cat ${SCRIPT_DIR}/wireguard/jenkins-server.conf)" \
    --type "SecureString" \
    --tier "Standard" \
    --overwrite