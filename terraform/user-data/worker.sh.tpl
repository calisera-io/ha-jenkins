#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="http://${jenkins_private_ip}:8080"

# === wait until jenkins server is healthy ===
until curl -s --head --fail --max-time 3 "$JENKINS_URL/login" > /dev/null; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') $JENKINS_URL is offline. Retrying in 5s..."
  sleep 3
done

# === add JENKINS_URL to service override configuration ===
OVERRIDE_CONF="/etc/systemd/system/jenkins-worker.service.d/override.conf"
echo "Environment=\"JENKINS_URL=$JENKINS_URL\"" >> "$OVERRIDE_CONF"
systemctl enable --now jenkins-worker.service
