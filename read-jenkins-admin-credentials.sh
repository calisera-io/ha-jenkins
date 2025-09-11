#!/usr/bin/env bash
set -e

if ! vault status >/dev/null 2>&1; then
    echo "Error: Vault server is not running."
    exit 1
fi

if ! vault token lookup >/dev/null 2>&1; then
    echo "Error: You are not logged into Vault."
    exit 1
fi

read -s -p "Enter Jenkins admin username: " JENKINS_ADMIN_ID
echo
read -s -p "Enter Jenkins admin password: " JENKINS_ADMIN_PASSWORD
echo
read -s -p "Confirm Jenkins admin password: " JENKINS_ADMIN_PASSWORD_CONFIRMATION
echo

if [ "$JENKINS_ADMIN_PASSWORD" != "$JENKINS_ADMIN_PASSWORD_CONFIRMATION" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

vault kv put secret/jenkins \
    jenkins_admin_id="$JENKINS_ADMIN_ID" \
    jenkins_admin_password="$JENKINS_ADMIN_PASSWORD" > /dev/null 2>&1
