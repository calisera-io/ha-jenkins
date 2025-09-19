#!/usr/bin/env bash
set -euo pipefail

source /tmp/shared-scripts/functions.sh
rm -rf /tmp/shared-scripts

check_override_conf() {
  local FILE="$1"
  if ! grep -qE '^Environment="JENKINS_ADMIN_ID=' "$FILE"; then
    return 1
  fi
  if ! grep -qE '^Environment="JENKINS_ADMIN_PASSWORD=' "$FILE"; then
    return 1
  fi
  if ! grep -qE '^Environment="JENKINS_HOME=' "$FILE"; then
    return 1
  fi
  return 0
}

JENKINS_USER=${JENKINS_USER:-jenkins}

JENKINS_HOME="/var/lib/$JENKINS_USER" 
OVERRIDE_CONF="/etc/systemd/system/jenkins-worker.service.d/override.conf"

errors=0

# === check environment configuration provided by override configuration ===
if ! check_override_conf "$OVERRIDE_CONF"; then
  echo "ERROR: Environment configuration missing"
  ((errors++))
fi

# === check SSH configuration ===
if [ -d "$JENKINS_HOME/.ssh" ]; then
  if [ -f "$JENKINS_HOME/.ssh/authorized_keys" ]; then
    if ! check_file_perms "$JENKINS_HOME/.ssh" "700"; then
      echo "ERROR: Incorrect permissions for .ssh directory"
      ((errors++))
    fi
    if ! check_file_perms "$JENKINS_HOME/.ssh/authorized_keys" "600"; then
      echo "ERROR: Incorrect permissions for authorized keys file"
      ((errors++))
    fi
    if ! check_authorized_keys_format "$JENKINS_HOME/.ssh/authorized_keys"; then
      echo "ERROR: Invalid authorized keys format"
      ((errors++))
    fi
  else
    echo "ERROR: Authorized keys file not found at $JENKINS_HOME/.ssh/authorized_keys"
    ((errors++))
  fi
else
  echo "ERROR: SSH directory not found at $JENKINS_HOME/.ssh"
  ((errors++))
fi

if [ $errors -gt 0 ]; then
  echo "Found $errors error(s)"
  exit 1
else
  echo "All checks passed"
  exit 0
fi