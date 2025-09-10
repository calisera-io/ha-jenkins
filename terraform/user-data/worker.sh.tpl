#!/usr/bin/env bash

dnf update -y
dnf install -y \
    git \
    java-21-amazon-corretto \
    docker
dnf clean all
rm -rf /var/cache/dnf/*
rm -rf /tmp/*
usermod -aG docker ec2-user
systemctl enable --now docker

JENKINS_USERNAME=admin
JENKINS_PASSWORD=password

JENKINS_URL="http://${jenkins_private_ip}:8080"

echo "Waiting for $JENKINS_URL to return HTTP 200..."

while true; do
  STATUS=$(curl -o /dev/null -s -w "%%{http_code}" "$JENKINS_URL/login")
  if [ "$STATUS" -eq 200 ]; then
    echo "Success: $JENKINS_URL/login is up (HTTP 200)"
    break
  else
    echo "Current status: $STATUS. Retrying in 5 seconds..."
    sleep 5
  fi
done

COOKIEJAR="$(mktemp)"
TOKEN=$(curl -u $JENKINS_USERNAME:$JENKINS_PASSWORD --cookie-jar "$COOKIEJAR" ''$JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
INSTANCE_NAME=$(curl -s 169.254.169.254/latest/meta-data/local-hostname)
INSTANCE_IP=$(curl -s 169.254.169.254/latest/meta-data/local-ipv4)
JENKINS_CREDENTIALS_ID="${worker_credentials_id}"

echo "TOKEN $TOKEN"
echo "INSTANCE_NAME $INSTANCE_NAME"
echo "INSTANCE_IP $INSTANCE_IP"
echo "JENKINS_CREDENTIALS_ID $JENKINS_CREDENTIALS_ID"

curl -v -u $JENKINS_USERNAME:$JENKINS_PASSWORD --cookie "$COOKIEJAR" -H "$TOKEN" -d 'script=
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
import hudson.plugins.sshslaves.SSHLauncher
import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy

SSHLauncher launcher = new SSHLauncher("'$INSTANCE_IP'", 22, "'$JENKINS_CREDENTIALS_ID'")
launcher.setSshHostKeyVerificationStrategy(new NonVerifyingKeyVerificationStrategy())

DumbSlave dumb = new DumbSlave(
  "'$INSTANCE_NAME'",
  "Worker node '$INSTANCE_NAME'",
  "/home/ec2-user",
  "2",
  Mode.NORMAL,
  "workers",
  launcher,
  RetentionStrategy.INSTANCE
)
Jenkins.instance.addNode(dumb)
' $JENKINS_URL/script

rm -rf $COOKIEJAR