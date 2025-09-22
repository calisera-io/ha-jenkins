#!/usr/bin/env bash
set -euo pipefail

aws ssm get-parameter \
    --name "/jenkins/dev/wg0.conf" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text \
    > /etc/wireguard/wg0.conf

chmod 600 /etc/wireguard/wg0.conf