#!/usr/bin/env bash
set -euo pipefail

/var/lib/jenkins/fetch-wireguard-configuration.sh
/var/lib/jenkins/fetch-admin-credentials.sh
/var/lib/jenkins/fetch-github-credentials.sh

systemctl daemon-reload
systemctl enable --now wg-quick@wg0
systemctl enable --now ping-loop.service
systemctl enable --now nginx.service
systemctl enable --now jenkins.service