#!/usr/bin/env bash

dnf upgrade
dnf install java-21-amazon-corretto -y
dnf install git -y
dnf install docker -y
usermod -aG docker ec2-user
systemctl enable --now docker