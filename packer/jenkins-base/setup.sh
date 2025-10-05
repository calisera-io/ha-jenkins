#!/usr/bin/env bash
set -euo pipefail

# === configure swap ===
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# === upgrade ===
dnf upgrade --releasever=2023.9.20250929 -y

# === install packages ===
dnf install -y \
    git \
    java-21-amazon-corretto

# === cleanup ===
dnf clean all
rm -rf /var/cache/dnf/*