#!/usr/bin/env bash
set -euo pipefail

JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID:-admin}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD:-admin}

JENKINS_USER=jenkins
JENKINS_HOME="/var/lib/${JENKINS_USER}" 

# === install dependencies ===
curl -s -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade -y
dnf install -y jenkins 
dnf clean all
rm -rf /var/cache/dnf/*

# === add override configuration for jenkins service ===
UNIT_CONF=/etc/systemd/system/jenkins.service.d
mkdir -p ${UNIT_CONF}
OVERRIDE_CONF="${UNIT_CONF}/override.conf"
cat <<EOF > ${OVERRIDE_CONF}
[Unit]
After=network-online.target
Wants=network-online.target
[Service]
Environment="JENKINS_ADMIN_ID=${JENKINS_ADMIN_ID}"
Environment="JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}"
Environment="JAVA_OPTS=-Xms512m -Xmx1024m -Djenkins.install.runSetupWizard=false -Djava.net.preferIPv4Stack=true"
ExecStartPre=/bin/bash -c '
max=50
count=0
until curl -s -L https://updates.jenkins.io >/dev/null; do
    count=\$((count+1))
    if [ \$count -ge \$max ]; then
        echo "Network not reachable after retries, continuing anyway"
        break
    fi
    sleep 0.2
done
'
EOF

systemctl daemon-reload

systemctl enable jenkins 2>&1

# === install private key ===
mkdir "${JENKINS_HOME}/.ssh"
touch "${JENKINS_HOME}/.ssh/known_hosts"
chmod 700 "${JENKINS_HOME}/.ssh"
mv /tmp/credentials/jenkins_id_rsa "${JENKINS_HOME}/.ssh/jenkins_id_rsa"
chmod 600 "${JENKINS_HOME}/.ssh/jenkins_id_rsa"
chown -R "${JENKINS_USER}:" "${JENKINS_HOME}/.ssh"
rm -rf /tmp/credentials

# === install plugins ===
pushd /tmp/plugin-manager > /dev/null
chmod u+x install-plugins.sh
./install-plugins.sh
popd > /dev/null

rm -rf /tmp/plugin-manager

# === install groovy scripts ===
mkdir "${JENKINS_HOME}/init.groovy.d"
mv /tmp/scripts/*.groovy "${JENKINS_HOME}/init.groovy.d/"
chown -R "${JENKINS_USER}:" "${JENKINS_HOME}/init.groovy.d"
rmdir /tmp/scripts

# # === disable setup-wizard ===
# JENKINS_VERSION=$(rpm -qa | grep jenkins | cut -d '-' -f2)
# echo "${JENKINS_VERSION}" > "${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion"
# echo "${JENKINS_VERSION}" > "${JENKINS_HOME}/jenkins.install.UpgradeWizard.state"
# chown -R "${JENKINS_USER}:" \
#    "${JENKINS_HOME}/jenkins.install.InstallUtil.lastExecVersion" \
#    "${JENKINS_HOME}/jenkins.install.UpgradeWizard.state"
