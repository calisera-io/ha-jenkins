#!/usr/bin/env bash

set -euo pipefail

dnf upgrade
dnf install -y \
    git \
    java-21-amazon-corretto \
    docker
dnf clean all
rm -rf /var/cache/dnf/*

systemctl daemon-reload
systemctl enable docker

WORKDIR="/var/lib/$JENKINS_USER" 

#
# create jenkins user
#
useradd -m -d "$WORKDIR" -s /bin/bash "$JENKINS_USER"
usermod -aG wheel $JENKINS_USER
usermod -aG docker $JENKINS_USER
echo "$JENKINS_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$JENKINS_USER"
chmod 640 "/etc/sudoers.d/$JENKINS_USER"

#
# install authorized keys
#
mkdir -p "$WORKDIR/.ssh"
chmod 700 "$WORKDIR/.ssh"
cat /tmp/credentials/jenkins_id_rsa.pub > $WORKDIR/.ssh/authorized_keys
chmod 600 "$WORKDIR/.ssh/authorized_keys"
rm -rf /tmp/credentials

#
# set ownership of jenkins home
#
chown -R "$JENKINS_USER":"$JENKINS_USER" "$WORKDIR"
