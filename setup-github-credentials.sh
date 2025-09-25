#!/usr/bin/env bash
set -e

read -p "Enter Github username: " GITHUB_USERNAME
echo
read -s -p "Enter Github token: " GITHUB_TOKEN
echo
read -s -p "Confirm Github token: " GITHUB_TOKEN_CONFIRMATION
echo

if [ "$GITHUB_TOKEN" != "$GITHUB_TOKEN_CONFIRMATION" ]; then
    echo "Error: Tokens do not match."
    exit 1
fi

aws ssm put-parameter \
  --name "/jenkins/dev/github_username" \
  --value "$GITHUB_USERNAME" \
  --type "SecureString" \
  --overwrite

aws ssm put-parameter \
  --name "/jenkins/dev/github_token" \
  --value "$GITHUB_TOKEN" \
  --type "SecureString" \
  --overwrite
