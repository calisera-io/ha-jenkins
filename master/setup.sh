#!/usr/bin/env bash

curl -s -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
dnf install -y \
    unzip \
    git \
    java-21-amazon-corretto \
    jenkins 
systemctl daemon-reload

export JENKINS_HOME=/var/lib/jenkins

#
# install private key
#
mkdir $JENKINS_HOME/.ssh
touch $JENKINS_HOME/.ssh/known_hosts
chmod 700 $JENKINS_HOME/.ssh
mv /tmp/credentials/id_rsa $JENKINS_HOME/.ssh/id_rsa
chmod 600 $JENKINS_HOME/.ssh/id_rsa
chown -R jenkins:jenkins $JENKINS_HOME/.ssh
rm -rf /tmp/credentials

#
# install plugins
#
chmod u+x /tmp/plugins/install-plugins.sh
/tmp/plugins/install-plugins.sh
rm -rf /tmp/plugins

#
# install groovy scripts
#
mkdir $JENKINS_HOME/init.groovy.d
mv /tmp/scripts/*.groovy $JENKINS_HOME/init.groovy.d/
chown -R jenkins:jenkins $JENKINS_HOME/init.groovy.d
rmdir /tmp/scripts

#
# disable setup-wizard
#
jenkins_version=$(rpm -qa | grep jenkins | cut -d '-' -f2)
echo "$jenkins_version" > $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion
echo "$jenkins_version" > $JENKINS_HOME/jenkins.install.UpgradeWizard.state

systemctl enable jenkins
