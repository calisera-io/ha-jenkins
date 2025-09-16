#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/PackerAMIBuilderPolicy"

echo "Creating/updating PackerAMIBuilderPolicy..."
if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy exists, deleting..."
    aws iam delete-policy --policy-arn $POLICY_ARN
fi

aws iam create-policy --policy-name PackerAMIBuilderPolicy --policy-document file://$SCRIPT_DIR/packer-policy.json

echo "Creating IAM user 'packer'..."
if aws iam get-user --user-name packer >/dev/null 2>&1; then
    echo "User exists, cleaning up..."
    aws iam list-access-keys --user-name packer --query 'AccessKeyMetadata[].AccessKeyId' --output text | xargs -I {} aws iam delete-access-key --user-name packer --access-key-id {}
    aws iam detach-user-policy --user-name packer --policy-arn $POLICY_ARN 2>/dev/null || true
    aws iam delete-user --user-name packer
fi
aws iam create-user --user-name packer

echo "Attaching PackerAMIBuilderPolicy..."
aws iam attach-user-policy --user-name packer --policy-arn $POLICY_ARN

echo "Creating access keys..."
KEYS=$(aws iam create-access-key --user-name packer --output json)
ACCESS_KEY=$(echo $KEYS | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $KEYS | jq -r '.AccessKey.SecretAccessKey')

echo "Configuring AWS profile 'packer'..."
aws configure set aws_access_key_id $ACCESS_KEY --profile packer
aws configure set aws_secret_access_key $SECRET_KEY --profile packer
aws configure set region us-east-1 --profile packer
aws configure set output json --profile packer

echo "Testing profile..."
aws sts get-caller-identity --profile packer

echo "Setup complete! Use 'profile': 'packer' in your Packer templates."
