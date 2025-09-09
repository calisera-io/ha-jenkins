#!/usr/bin/env bash

dnf update -y
dnf install -y \
    git \
    java-21-amazon-corretto \
    docker
dnf clean all
rm -rf /var/cache/dnf/*
rm -rf /tmp/*
usermod -aG docker ec2-user
systemctl enable docker