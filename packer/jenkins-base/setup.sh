#!/usr/bin/env bash
set -euo pipefail

# === upgrade ===
dnf upgrade --releasever=2023.8.20250915 -y

# === install packages ===
dnf install -y \
    git \
    java-21-amazon-corretto

# === cleanup ===
dnf clean all
rm -rf /var/cache/dnf/*