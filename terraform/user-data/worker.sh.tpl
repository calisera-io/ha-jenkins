#!/usr/bin/env bash

export JENKINS_URL="http://${jenkins_private_ip}:8080"

systemctl start jenkins-worker.service
