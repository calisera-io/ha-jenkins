#!/usr/bin/env bash
set -e

read -s -p "Enter Github token: " GITHUB_WEBHOOK_SECRET
echo
read -s -p "Confirm Github token: " GITHUB_WEBHOOK_SECRET_CONFIRMATION
echo

if [ "$GITHUB_WEBHOOK_SECRET" != "$GITHUB_WEBHOOK_SECRET_CONFIRMATION" ]; then
    echo "Error: Tokens do not match."
    exit 1
fi

aws ssm put-parameter \
  --name "/jenkins/dev/github_webhook_secret" \
  --value "$GITHUB_WEBHOOK_SECRET" \
  --type "SecureString" \
  --overwrite
