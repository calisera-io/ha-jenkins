#!/usr/bin/env bash

set -euo pipefail

check_first_line_starts_with() {
    local file="$1"
    local string="$2"

    local first_line
    first_line=$(head -n 1 "$file")

    if [[ "$first_line" == $string* ]]; then
        return 0 
    else
        return 1   
    fi
}

check_authorized_keys_format() {
    local file="$1"
    local string="ssh-rsa"

    if check_first_line_starts_with "$file" "$string"; then
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
OVERRIDE_CONF="/etc/systemd/system/jenkins-worker.service.d/override.conf"

errors=0

# === check environment configuration ===
if ! check_environment "$OVERRIDE_CONF"; then
  echo "ERROR: Environment configuration missing"
  ((errors++))
fi

# Check SSH configuration
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