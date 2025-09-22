#!/usr/bin/env bash
set -euo pipefail

JENKINS_ADMIN_ID=$(aws ssm get-parameter \
  --name "/jenkins/dev/jenkins_admin_id" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

JENKINS_ADMIN_PASSWORD=$(aws ssm get-parameter \
  --name "/jenkins/dev/jenkins_admin_password" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

OVERRIDE_CONF="/etc/systemd/system/jenkins.service.d/override.conf"

cat <<EOF >> "$OVERRIDE_CONF"
Environment="JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}"
Environment="JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}"
EOF
