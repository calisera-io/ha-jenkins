#!/usr/bin/env bash
set -euo pipefail

OVERRIDE_CONF="/etc/systemd/system/jenkins-worker.service.d/override.conf"
echo "Environment=\"JENKINS_URL=http://${jenkins_private_ip}:8080\"" >> "$OVERRIDE_CONF"
systemctl start jenkins-worker.service
