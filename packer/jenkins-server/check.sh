#!/usr/bin/env bash
set -euo pipefail

JENKINS_USER=${JENKINS_USER:-jenkins}

check_first_line() {
    local file="$1"
    local string="$2"

    local firstline
    firstline=$(head -n 1 "$file")

    if [[ "$firstline" == "$string" ]]; then
        return 0 
    else
        return 1   
    fi
}

check_last_non_empty_line() {
    local file="$1"
    local string="$2"

    local lastline
    lastline=$(awk 'NF {line=$0} END {print line}' "$file")

    if [[ "$lastline" == "$string" ]]; then
        return 0   
    else
        return 1  
    fi
}

check_private_key_format() {
    local file="$1"
    local first_line="-----BEGIN OPENSSH PRIVATE KEY-----"
    local last_line="-----END OPENSSH PRIVATE KEY-----"

    if check_first_line "$file" "$first_line" && check_last_non_empty_line "$file" "$last_line"; then
        return 0 
    else
        return 1  
    fi
}

check_file_perms() {
    local file="$1"
    local expected="$2"
    local perms

    perms=$(stat -c '%a' "$file" 2>/dev/null) || return 1

    if [[ "$perms" == "$expected" ]]; then
        return 0  
    else
        return 1 
    fi
}

check_environment() {
  local file="$1"
  if ! grep -qE '^Environment="JENKINS_ADMIN_ID=' "$file"; then
    return 1
  fi
  if ! grep -qE '^Environment="JENKINS_ADMIN_PASSWORD=' "$file"; then
    return 1
  fi
  return 0
}

JENKINS_HOME="/var/lib/$JENKINS_USER" 
JENKINS_OVERRIDE_CONF="/etc/systemd/system/${JENKINS_USER}.service.d/override.conf"

errors=0

#
# Check environment configuration
#
if ! check_environment "$JENKINS_OVERRIDE_CONF"; then
  echo "ERROR: Environment configuration missing"
  ((errors++))
fi

#
# Check Jenkins home directory
#
if [ ! -d "$JENKINS_HOME" ]; then
  echo "ERROR: Jenkins home directory not found at $JENKINS_HOME"
  ((errors++))
fi

#
# Check SSH configuration
#
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

#
# Check plugins
#
if [ ! -d "$JENKINS_HOME/plugins" ]; then
  echo "ERROR: Plugins directory not found at $JENKINS_HOME/plugins"
  ((errors++))
fi

#
# Check Groovy init scripts
#
if [ ! -d "$JENKINS_HOME/init.groovy.d" ]; then
  echo "ERROR: Groovy init scripts directory not found at $JENKINS_HOME/init.groovy.d"
  ((errors++))
fi 

#
# Check setup-wizard state
#
jenkins_version=$(rpm -qa | grep jenkins | cut -d '-' -f2)
if ! check_last_non_empty_line "$JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion" "$jenkins_version"; then
  echo "ERROR: Unexpected file contents $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"
  ((errors++))
fi
if ! check_last_non_empty_line "$JENKINS_HOME/jenkins.install.UpgradeWizard.state" "$jenkins_version"; then
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
