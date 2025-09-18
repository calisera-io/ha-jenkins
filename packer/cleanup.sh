#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <AMI_NAME>"
    echo "Example: $0 jenkins-worker"
    exit 1
fi

AMI=$1

ami_data=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$AMI" \
    --query 'Images | sort_by(@, &CreationDate)[].[ImageId, BlockDeviceMappings[0].Ebs.SnapshotId]' --output text)

echo "$ami_data" | while read ami_id snapshot_id; do
    if [ -n "$ami_id" ] && [ -n "$snapshot_id" ]; then
        echo "Deregistering AMI: $ami_id"
        aws ec2 deregister-image --image-id "$ami_id"
        
        echo "Deleting snapshot: $snapshot_id"
        aws ec2 delete-snapshot --snapshot-id "$snapshot_id"
    fi
done