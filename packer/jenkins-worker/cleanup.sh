#!/usr/bin/env bash

aws ec2 describe-images --owners self --filters "Name=name,Values=jenkins-worker" \
    --query 'Images | sort_by(@, &CreationDate)[].[ImageId]' --output text | \
    xargs -r -n1 aws ec2 deregister-image --image-id