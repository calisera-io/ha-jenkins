#!/usr/bin/env bash
set -e

GITHUB_WEBHOOK_SECRET=$(openssl rand -base64 32)

aws ssm put-parameter \
  --name "/jenkins/dev/github_webhook_secret" \
  --value "$GITHUB_WEBHOOK_SECRET" \
  --type "SecureString" \
  --overwrite

echo "$GITHUB_WEBHOOK_SECRET"