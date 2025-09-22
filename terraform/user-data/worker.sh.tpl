#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="http://${jenkins_private_ip}:8080"

/var/lib/jenkins/fetch-jenkins-secrets.sh

# === add JENKINS_URL to service override configuration ===
OVERRIDE_CONF="/etc/systemd/system/jenkins-worker.service.d/override.conf"
echo "Environment=\"JENKINS_URL=$JENKINS_URL\"" >> "$OVERRIDE_CONF"

systemctl daemon-reload
systemctl enable --now jenkins-worker.service
