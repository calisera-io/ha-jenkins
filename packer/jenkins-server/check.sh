#!/usr/bin/env bash
set -euo pipefail

source /tmp/shared-scripts/functions.sh
rm -rf /tmp/shared-scripts

JENKINS_USER=${JENKINS_USER:-jenkins}

JENKINS_HOME="/var/lib/${JENKINS_USER}" 
OVERRIDE_CONF="/etc/systemd/system/${JENKINS_USER}.service.d/override.conf"

ERRORS=0

# # === check environment configuration provided by override configuration ===
# if ! check_override_conf "${OVERRIDE_CONF}"; then
#   echo "ERROR: Environment configuration missing"
#   ((ERRORS++))
# fi

# === check Jenkins home directory ===
if [ ! -d "${JENKINS_HOME}" ]; then
  echo "ERROR: Jenkins home directory not found at ${JENKINS_HOME}"
  ((ERRORS++))
fi

# === check SSH configuration ===
if [ -d "${JENKINS_HOME}/.ssh" ]; then
  if [ -f "${JENKINS_HOME}/.ssh/jenkins_id_rsa" ]; then
    if ! check_file_perms "${JENKINS_HOME}/.ssh" "700"; then
      echo "ERROR: Incorrect permissions for .ssh directory"
      ((ERRORS++))
    fi
    if ! check_file_perms "${JENKINS_HOME}/.ssh/jenkins_id_rsa" "600"; then
      echo "ERROR: Incorrect permissions for private key"
      ((ERRORS++))
    fi
    if ! check_private_key_format "${JENKINS_HOME}/.ssh/jenkins_id_rsa"; then
      echo "ERROR: Invalid private key format"
      ((ERRORS++))
    fi
  else
    echo "ERROR: Private key not found at ${JENKINS_HOME}/.ssh/jenkins_id_rsa"
    ((ERRORS++))
  fi
else
  echo "ERROR: SSH directory not found at ${JENKINS_HOME}/.ssh"
  ((ERRORS++))
fi

# === check plugins ===
if [ ! -d "${JENKINS_HOME}/plugins" ]; then
  echo "ERROR: Plugins directory not found at ${JENKINS_HOME}/plugins"
  ((ERRORS++))
fi

# === check Groovy init scripts ===
if [ ! -d "${JENKINS_HOME}/init.groovy.d" ]; then
  echo "ERROR: Groovy init scripts directory not found at ${JENKINS_HOME}/init.groovy.d"
  ((ERRORS++))
fi 

# # === check setup-wizard state ===
# JENKINS_VERSION=$(rpm -qa | grep jenkins | cut -d '-' -f2)
# if ! check_last_non_empty_line "${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion" "${JENKINS_VERSION}"; then
#   echo "ERROR: Unexpected file contents ${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion"
#   ((ERRORS++))
# fi
# if ! check_last_non_empty_line "${JENKINS_HOME}/jenkins.install.UpgradeWizard.state" "${JENKINS_VERSION}"; then
#   echo "ERROR: Unexpected file contents ${JENKINS_HOME}/jenkins.install.UpgradeWizard.state"
#   ((ERRORS++))
# fi

if [ $ERRORS -gt 0 ]; then
  echo "Found $ERRORS error(s)"
  exit 1
else
  echo "All checks passed"
  exit 0
fi
