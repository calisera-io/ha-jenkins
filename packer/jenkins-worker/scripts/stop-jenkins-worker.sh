#!/usr/bin/env bash
set -euo pipefail

COOKIEJAR=$(mktemp)
WORKER_NAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
TOKEN=$(curl -s -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie-jar "$COOKIEJAR" \
  "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

curl -s -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD --cookie "$COOKIEJAR" -H "$TOKEN" \
  -d "script=
import jenkins.model.Jenkins
def node = Jenkins.getInstance().getNode('$WORKER_NAME')
if (node) { Jenkins.getInstance().removeNode(node); Jenkins.getInstance().save() }
" $JENKINS_URL/script

rm "$COOKIEJAR"