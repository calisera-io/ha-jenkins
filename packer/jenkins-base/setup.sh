#!/usr/bin/env bash
set -euo pipefail

# === configure swap ===
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# === configure /tmp with larger size ===
echo 'tmpfs /tmp tmpfs defaults,size=1024M 0 0' >> /etc/fstab
mount -o remount /tmp

# === upgrade ===
dnf upgrade --releasever=2023.8.20250915 -y

# === install packages ===
dnf install -y \
    git \
    java-21-amazon-corretto

# === cleanup ===
dnf clean all
rm -rf /var/cache/dnf/*