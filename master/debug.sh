#!/usr/bin/env bash

export JENKINS_HOME=/var/lib/jenkins

if [ ! -d "$JENKINS_HOME" ]; then
  echo "Jenkins home directory not found. Creating..."
  exit 1
fi

ls -l $JENKINS_HOME/.ssh/
cat $JENKINS_HOME/.ssh/id_rsa

ls -l /etc/environment
cat /etc/environment

ls -l $JENKINS_HOME/init.groovy.d/
ls -l $JENKINS_HOME/plugins

