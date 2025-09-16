#!/usr/bin/env bash
set -euo pipefail

COOKIEJAR="$(mktemp)"

# === get token ===
get_token() {
  curl -s -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD \
    --cookie-jar "$COOKIEJAR" \
    ''$JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
}

WORKER_NAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
WORKER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
TOKEN=$(get_token)
JENKINS_CREDENTIALS_ID=jenkins

echo "TOKEN $TOKEN"
echo "WORKER_NAME $WORKER_NAME"
echo "WORKER_IP $WORKER_IP"
echo "JENKINS_CREDENTIALS_ID $JENKINS_CREDENTIALS_ID"

curl -v -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie "$COOKIEJAR" -H "$TOKEN" -d 'script=
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
import hudson.plugins.sshslaves.SSHLauncher
import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy

def jenkins = Jenkins.getInstance()

SSHLauncher launcher = new SSHLauncher("'$WORKER_IP'", 22, "'$JENKINS_CREDENTIALS_ID'")

launcher.setSshHostKeyVerificationStrategy(new NonVerifyingKeyVerificationStrategy())

DumbSlave dumb = new DumbSlave(
  "'$WORKER_NAME'",
  "Worker node '$WORKER_NAME'",
  "'$JENKINS_HOME'",
  "2",
  Mode.NORMAL,
  "worker",
  launcher,
  RetentionStrategy.INSTANCE
)
jenkins.addNode(dumb)
jenkins.save()
' $JENKINS_URL/script

rm -rf $COOKIEJAR