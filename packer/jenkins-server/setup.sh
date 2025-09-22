#!/usr/bin/env bash
set -euo pipefail

JENKINS_USER=jenkins
JENKINS_HOME="/var/lib/${JENKINS_USER}" 
JENKINS_VPN_IP="10.202.148.222"

# === install dependencies ===
curl -s -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade -y
dnf install -y \
    jenkins \
    wireguard-tools \
    nginx
dnf clean all
rm -rf /var/cache/dnf/*

rm -f /etc/nginx/conf.d/default.conf

cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
server {
    listen ${JENKINS_VPN_IP}:80;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# === add override configuration for jenkins service ===
UNIT_CONF=/etc/systemd/system/jenkins.service.d
mkdir -p ${UNIT_CONF}
OVERRIDE_CONF="${UNIT_CONF}/override.conf"
cat <<EOF > ${OVERRIDE_CONF}
[Unit]
After=network-online.target
Wants=network-online.target
[Service]
Environment="JAVA_OPTS=-Xms512m -Xmx1024m -Djenkins.install.runSetupWizard=false"
EOF

systemctl daemon-reload

# === install private key ===
mkdir ${JENKINS_HOME}/.ssh
touch ${JENKINS_HOME}/.ssh/known_hosts
chmod 700 ${JENKINS_HOME}/.ssh
mv /tmp/credentials/jenkins_id_rsa ${JENKINS_HOME}/.ssh/jenkins_id_rsa
chmod 600 ${JENKINS_HOME}/.ssh/jenkins_id_rsa
chown -R "${JENKINS_USER}:" ${JENKINS_HOME}/.ssh
rm -rf /tmp/credentials

# === install plugins ===
pushd /tmp/plugin-manager > /dev/null
chmod u+x install-plugins.sh
./install-plugins.sh
popd > /dev/null
rm -rf /tmp/plugin-manager

# === install scripts ===
mv /tmp/scripts/*.sh ${JENKINS_HOME}/
chmod u+x ${JENKINS_HOME}/*.sh
chown -R "${JENKINS_USER}:" ${JENKINS_HOME}/*.sh
rmdir /tmp/scripts

# === install groovy scripts ===
mkdir ${JENKINS_HOME}/init.groovy.d
mv /tmp/groovy/*.groovy ${JENKINS_HOME}/init.groovy.d/
chown -R "${JENKINS_USER}:" ${JENKINS_HOME}/init.groovy.d
rmdir /tmp/groovy