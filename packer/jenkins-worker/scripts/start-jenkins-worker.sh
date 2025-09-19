#!/usr/bin/env bash
set -euo pipefail

COOKIEJAR=$(mktemp)
WORKER_NAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
WORKER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
TOKEN=$(curl -s -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie-jar "$COOKIEJAR" \
  "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

curl -s -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie "$COOKIEJAR" -H "$TOKEN" \
  -d "script=
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
import hudson.plugins.sshslaves.SSHLauncher
import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy

def launcher = new SSHLauncher('$WORKER_IP', 22, 'jenkins')
launcher.setSshHostKeyVerificationStrategy(new NonVerifyingKeyVerificationStrategy())
Jenkins.getInstance().addNode(new DumbSlave('$WORKER_NAME', 'EC2 worker node $WORKER_NAME', '/var/lib/jenkins', '2', Mode.NORMAL, 'ec2-worker', launcher, RetentionStrategy.INSTANCE))
Jenkins.getInstance().save()
" $JENKINS_URL/script

rm "$COOKIEJAR"