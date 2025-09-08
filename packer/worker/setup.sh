#!/usr/bin/env bash

dnf update -y
dnf install java-21-amazon-corretto-headless -y
dnf install git -y
dnf install docker -y
dnf clean all
rm -rf /var/cache/dnf/*
rm -rf /tmp/*
journalctl --vacuum-time=1d
usermod -aG docker ec2-user
systemctl enable docker