#!/usr/bin/env bash
set -euo pipefail

JENKINS_USER=${JENKINS_USER:-jenkins}

# === install dependencies ===
dnf install -y docker
dnf clean all
rm -rf /var/cache/dnf/*

# === add jenkins user ===
JENKINS_HOME="/var/lib/$JENKINS_USER" 
useradd -m -d "$JENKINS_HOME" -s /bin/bash "$JENKINS_USER"
usermod -aG wheel $JENKINS_USER
usermod -aG docker $JENKINS_USER
echo "$JENKINS_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$JENKINS_USER"
chmod 640 "/etc/sudoers.d/$JENKINS_USER"

# === add jenkins worker service ===
cat <<EOF > /etc/systemd/system/jenkins-worker.service
[Unit]
Description=Jenkins Worker
After=network.target docker.service
Wants=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$JENKINS_USER
Group=$JENKINS_USER
WorkingDirectory=$JENKINS_HOME

ExecStart=$JENKINS_HOME/start-jenkins-worker.sh
ExecStop=$JENKINS_HOME/stop-jenkins-worker.sh

StandardOutput=journal
StandardError=journal

Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# === add jenkins worker service override configuration ===
UNIT_CONF_D="/etc/systemd/system/jenkins-worker.service.d"
mkdir -p "$UNIT_CONF_D"
OVERRIDE_CONF="$UNIT_CONF_D/override.conf"
cat <<EOF > "$OVERRIDE_CONF"
[Unit]
After=network-online.target
Wants=network-online.target
[Service]
ExecStartPre=${JENKINS_HOME}/wait-for-jenkins.sh
EOF

# === install scripts ===
mv /tmp/scripts/*.sh $JENKINS_HOME/.
chmod u+x $JENKINS_HOME/*.sh
rmdir /tmp/scripts

# === install authorized keys ===
mkdir -p "$JENKINS_HOME/.ssh"
chmod 700 "$JENKINS_HOME/.ssh"
cat /tmp/credentials/jenkins_id_rsa.pub > $JENKINS_HOME/.ssh/authorized_keys
chmod 600 "$JENKINS_HOME/.ssh/authorized_keys"
rm -rf /tmp/credentials

# === change ownership of jenkins user home directory ===
chown -R "$JENKINS_USER":"$JENKINS_USER" "$JENKINS_HOME"

# === reload systemd and enable services ===
systemctl daemon-reload
systemctl enable docker 2>&1
