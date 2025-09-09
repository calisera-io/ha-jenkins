#!/usr/bin/env bash

set -euo pipefail

check_environment() {
  local file="$1"
  if ! grep -q "JENKINS_USERNAME" "$file"; then
    return 1
  fi
  if ! grep -q "JENKINS_PASSWORD" "$file"; then
    return 1
  fi
  return 0
}

errors=0

# Check environment configuration
if ! check_environment "/etc/environment"; then
  echo "ERROR: Environment configuration missing"
  ((errors++))
fi

if [ $errors -gt 0 ]; then
  echo "Found $errors error(s)"
  exit 1
else
  echo "All checks passed"
  exit 0
fi