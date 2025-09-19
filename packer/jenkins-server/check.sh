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
  if ! grep -qE '^Environment="JAVA_OPTS=' "$FILE"; then
    return 1
  fi
  return 0
}

JENKINS_USER=${JENKINS_USER:-jenkins}

JENKINS_HOME="/var/lib/$JENKINS_USER" 
OVERRIDE_CONF="/etc/systemd/system/${JENKINS_USER}.service.d/override.conf"

errors=0

# === check environment configuration provided by override configuration ===
if ! check_override_conf "$OVERRIDE_CONF"; then
  echo "ERROR: Environment configuration missing"
  ((errors++))
fi

# === check Jenkins home directory ===
if [ ! -d "$JENKINS_HOME" ]; then
  echo "ERROR: Jenkins home directory not found at $JENKINS_HOME"
  ((errors++))
fi

# === check SSH configuration ===
if [ -d "$JENKINS_HOME/.ssh" ]; then
  if [ -f "$JENKINS_HOME/.ssh/jenkins_id_rsa" ]; then
    if ! check_file_perms "$JENKINS_HOME/.ssh" "700"; then
      echo "ERROR: Incorrect permissions for .ssh directory"
      ((errors++))
    fi
    if ! check_file_perms "$JENKINS_HOME/.ssh/jenkins_id_rsa" "600"; then
      echo "ERROR: Incorrect permissions for private key"
      ((errors++))
    fi
    if ! check_private_key_format "$JENKINS_HOME/.ssh/jenkins_id_rsa"; then
      echo "ERROR: Invalid private key format"
      ((errors++))
    fi
  else
    echo "ERROR: Private key not found at $JENKINS_HOME/.ssh/jenkins_id_rsa"
    ((errors++))
  fi
else
  echo "ERROR: SSH directory not found at $JENKINS_HOME/.ssh"
  ((errors++))
fi

# === check plugins ===
if [ ! -d "$JENKINS_HOME/plugins" ]; then
  echo "ERROR: Plugins directory not found at $JENKINS_HOME/plugins"
  ((errors++))
fi

# === check Groovy init scripts ===
if [ ! -d "$JENKINS_HOME/init.groovy.d" ]; then
  echo "ERROR: Groovy init scripts directory not found at $JENKINS_HOME/init.groovy.d"
  ((errors++))
fi 

# === check setup-wizard state ===
JENKINS_VERSION=$(rpm -qa | grep jenkins | cut -d '-' -f2)
if ! check_last_non_empty_line "$JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion" "$JENKINS_VERSION"; then
  echo "ERROR: Unexpected file contents $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"
  ((errors++))
fi
if ! check_last_non_empty_line "$JENKINS_HOME/jenkins.install.UpgradeWizard.state" "$JENKINS_VERSION"; then
  echo "ERROR: Unexpected file contents $JENKINS_HOME/jenkins.install.UpgradeWizard.state"
  ((errors++))
fi

if [ $errors -gt 0 ]; then
  echo "Found $errors error(s)"
  exit 1
else
  echo "All checks passed"
  exit 0
fi
