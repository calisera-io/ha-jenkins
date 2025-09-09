#!/usr/bin/env bash

yum update -y
yum install -y httpd

echo "<h1>This message is from jenkins: $(hostname -i)</h1>" > /var/www/html/index.html
sudo sed -i 's/^Listen 80$/Listen 8080/' /etc/httpd/conf/httpd.conf

systemctl enable --now httpd
