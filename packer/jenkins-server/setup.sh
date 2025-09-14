#!/usr/bin/env bash
set -euo pipefail

JENKINS_USER=${JENKINS_USER:-jenkins}
JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID:-admin}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD:-admin}

export JENKINS_USER

curl -s -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
dnf install -y \
    unzip \
    git \
    jq \
    java-21-amazon-corretto \
    jenkins
dnf clean all
rm -rf /var/cache/dnf/*

JENKINS_UNIT_CONF="/etc/systemd/system/${JENKINS_USER}.service.d"
mkdir -p "$JENKINS_UNIT_CONF"
JENKINS_OVERRIDE_CONF="$JENKINS_UNIT_CONF/override.conf"
cat <<EOF > "$JENKINS_OVERRIDE_CONF"
[Service]
Environment="JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}"
Environment="JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}"
EOF

systemctl daemon-reload
systemctl enable jenkins 2>&1

JENKINS_HOME="/var/lib/$JENKINS_USER" 

#
# install private key
#
mkdir $JENKINS_HOME/.ssh
touch $JENKINS_HOME/.ssh/known_hosts
chmod 700 $JENKINS_HOME/.ssh
mv /tmp/credentials/jenkins_id_rsa $JENKINS_HOME/.ssh/jenkins_id_rsa
chmod 600 $JENKINS_HOME/.ssh/jenkins_id_rsa
chown -R "$JENKINS_USER":"$JENKINS_USER" $JENKINS_HOME/.ssh
rm -rf /tmp/credentials

#
# install plugins
#
pushd /tmp/plugin-manager > /dev/null
chmod u+x install-plugins.sh
./install-plugins.sh
popd > /dev/null

rm -rf /tmp/plugin-manager

#
# install groovy scripts
#
mkdir $JENKINS_HOME/init.groovy.d
mv /tmp/scripts/*.groovy $JENKINS_HOME/init.groovy.d/
chown -R "$JENKINS_USER":"$JENKINS_USER" $JENKINS_HOME/init.groovy.d
rmdir /tmp/scripts

#
# disable setup-wizard
#
jenkins_version=$(rpm -qa | grep jenkins | cut -d '-' -f2)
echo "$jenkins_version" > $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion
echo "$jenkins_version" > $JENKINS_HOME/jenkins.install.UpgradeWizard.state
