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
TOKEN=$(get_token)

echo "TOKEN $TOKEN"
echo "WORKER_NAME $WORKER_NAME"

curl -v -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie "$COOKIEJAR" -H "$TOKEN" -d 'script=
#!groovy

import jenkins.model.Jenkins

def jenkins = Jenkins.getInstance()

def node = jenkins.getNode("'$WORKER_NAME'")
if (node) {
    jenkins.removeNode(node)
    jenkins.save()
}
' $JENKINS_URL/script

rm -rf $COOKIEJAR


