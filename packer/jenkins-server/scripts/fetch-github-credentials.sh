#!/usr/bin/env bash
set -euo pipefail

GITHUB_USERNAME=$(aws ssm get-parameter \
  --name "/jenkins/dev/github_username" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

GITHUB_TOKEN=$(aws ssm get-parameter \
  --name "/jenkins/dev/github_token" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

OVERRIDE_CONF="/etc/systemd/system/jenkins.service.d/override.conf"

cat <<EOF >> "$OVERRIDE_CONF"
Environment="GITHUB_USERNAME=${GITHUB_USERNAME}"
Environment="GITHUB_TOKEN=${GITHUB_TOKEN}"
EOF
