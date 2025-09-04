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
cat <<EOF > /var/lib/jenkins/init.groovy.d/skip-initial-setup.groovy
#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()

instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
EOF
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

systemctl enable --now jenkins
