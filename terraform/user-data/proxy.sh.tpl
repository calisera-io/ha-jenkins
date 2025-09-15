#!/usr/bin/env bash
set -e

JENKINS_URL="http://${jenkins_private_ip}:8080"

dnf upgrade
dnf -y install nginx

rm -f /etc/nginx/conf.d/default.conf

cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
server {
    listen 80;

    location / {
        proxy_pass $JENKINS_URL;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo systemctl enable --now nginx

