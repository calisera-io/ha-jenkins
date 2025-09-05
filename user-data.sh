#!/usr/bin/env bash

curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
# Add required dependencies for the jenkins package
dnf install java-21-amazon-corretto -y
dnf install jenkins -y
systemctl daemon-reload

mkdir -p /var/lib/jenkins/init.groovy.d
cat <<EOF > /var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*

// Get env vars or use defaults
def env = System.getenv()
def adminUsername = env['JENKINS_ADMIN_ID'] ?: 'admin'
def adminPassword = env['JENKINS_ADMIN_PASSWORD'] ?: 'admin'

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUsername, adminPassword)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF
cat <<EOF > /var/lib/jenkins/init.groovy.d/set-url.groovy
#!groovy

import jenkins.model.*
import jenkins.model.JenkinsLocationConfiguration

def command = "curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
def process = command.execute()
process.waitFor()

def publicIpv4 = process.text
def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

def newUrl = "http://\${publicIpv4}:8080/"
jenkinsLocationConfiguration.setUrl(newUrl)

jenkinsLocationConfiguration.save()
EOF
cat <<EOF > /var/lib/jenkins/init.groovy.d/skip-initial-setup.groovy
#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()
def state = InstallState.INITIAL_SETUP_COMPLETED
InstallStateProceededListener.completed(instance, state)
instance.setInstallState(state)
EOF
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

mkdir -p /tmp/config
cat <<EOF > /tmp/config/plugins
ant
antisamy-markup-formatter
apache-httpcomponents-client-4-api
asm-api
bootstrap5-api
bouncycastle-api
branch-api
build-timeout
caffeine-api
checks-api
cloudbees-folder
commons-lang3-api
commons-text-api
credentials
credentials-binding
dark-theme
display-url-api
durable-task
echarts-api
eddsa-api
email-ext
font-awesome-api
git
git-client
github
github-api
github-branch-source
gradle
gson-api
instance-identity
ionicons-api
jackson2-api
jakarta-activation-api
jakarta-mail-api
javax-activation-api
jaxb
jjwt-api
joda-time-api
jquery3-api
json-api
json-path-api
jsoup
junit
ldap
mailer
matrix-auth
matrix-project
metrics
mina-sshd-api-common
mina-sshd-api-core
okhttp-api
pipeline-build-step
pipeline-github-lib
pipeline-graph-view
pipeline-groovy-lib
pipeline-input-step
pipeline-milestone-step
pipeline-model-api
pipeline-model-definition
pipeline-model-extensions
pipeline-stage-step
pipeline-stage-tags-metadata
plain-credentials
plugin-util-api
resource-disposer
scm-api
script-security
snakeyaml-api
ssh-credentials
ssh-slaves
structs
theme-manager
timestamper
token-macro
trilead-api
variant
workflow-aggregator
workflow-api
workflow-basic-steps
workflow-cps
workflow-durable-task-step
workflow-job
workflow-multibranch
workflow-scm-step
workflow-step-api
workflow-support
ws-cleanup
EOF
cat <<EOF > /tmp/config/install-plugins.sh
#!/bin/bash

set -e

plugin_dir=/var/lib/jenkins/plugins
file_owner=jenkins.jenkins

mkdir -p /var/lib/jenkins/plugins

installPlugin() {
  if [ -f \${plugin_dir}/\${1}.hpi -o -f \${plugin_dir}/\${1}.jpi ]; then
    if [ "\$2" == "1" ]; then
      return 1
    fi
    echo "Skipped: \$1 (already installed)"
    return 0
  else
    echo "Installing: \$1"
    curl -L --silent --output \${plugin_dir}/\${1}.hpi  https://updates.jenkins-ci.org/latest/\${1}.hpi
    return 0
  fi
}

while read -r plugin
do
    installPlugin "\$plugin"
done < "/tmp/config/plugins"

changed=1
maxloops=100

while [ "\$changed"  == "1" ]; do
  echo "Check for missing dependecies ..."
  if  [ \$maxloops -lt 1 ] ; then
    echo "Max loop count reached - probably a bug in this script: \$0"
    exit 1
  fi
  ((maxloops--))
  changed=0
  for f in \${plugin_dir}/*.hpi ; do
    # without optionals
    #deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | grep -v "resolution:=optional" | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    # with optionals
    deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    for plugin in \$deps; do
      installPlugin "\$plugin" 1 && changed=1
    done
  done
done

echo "fixing permissions"

chown \${file_owner} \${plugin_dir} -R

echo "all done"
EOF
chmod u+x /tmp/config/install-plugins.sh
/tmp/config/install-plugins.sh

systemctl enable --now jenkins
