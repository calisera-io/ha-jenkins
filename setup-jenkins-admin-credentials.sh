#!/usr/bin/env bash
set -e

read -p "Enter Jenkins admin username: " JENKINS_ADMIN_ID
echo
read -s -p "Enter Jenkins admin password: " JENKINS_ADMIN_PASSWORD
echo
read -s -p "Confirm Jenkins admin password: " JENKINS_ADMIN_PASSWORD_CONFIRMATION
echo

if [ "$JENKINS_ADMIN_PASSWORD" != "$JENKINS_ADMIN_PASSWORD_CONFIRMATION" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

aws ssm put-parameter \
  --name "/jenkins/dev/jenkins_admin_id" \
  --value "$JENKINS_ADMIN_ID" \
  --type "SecureString" \
  --overwrite

aws ssm put-parameter \
  --name "/jenkins/dev/jenkins_admin_password" \
  --value "$JENKINS_ADMIN_PASSWORD" \
  --type "SecureString" \
  --overwrite
