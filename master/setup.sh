#!/usr/bin/env bash

curl -s -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
dnf install git -y
dnf install java-21-amazon-corretto -y
dnf install jenkins -y
systemctl daemon-reload

mkdir $JENKINS_HOME/.ssh
touch $JENKINS_HOME/.ssh/known_hosts
chmod 0700 $JENKINS_HOME/.ssh
mv /tmp/id_rsa $JENKINS_HOME/jenkins/.ssh/id_rsa
chmod 0600 $JENKINS_HOME/.ssh/id_rsa
chown -R jenkins:jenkins $JENKINS_HOME/.ssh

mkdir $JENKINS_HOME/init.groovy.d
mv /tmp/scripts/*.groovy $JENKINS_HOME/init.groovy.d/
chown -R jenkins:jenkins $JENKINS_HOME/init.groovy.d

systemctl enable jenkins
