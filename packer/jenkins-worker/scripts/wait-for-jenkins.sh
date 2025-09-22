#!/usr/bin/env bash
set -euo pipefail

until curl -s --head --fail --max-time 3 "$JENKINS_URL/login" > /dev/null; do 
  echo "$(date "+%%Y-%%m-%%d %%H:%%M:%%S") $JENKINS_URL is offline. Retrying in 3s..."; 
  sleep 3;
done