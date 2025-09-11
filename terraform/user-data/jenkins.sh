#!/usr/bin/env bash

dnf upgrade
dnf install -y httpd

sed -i 's/^Listen 80$/Listen 8080/' /etc/httpd/conf/httpd.conf

cat <<EOF > /etc/httpd/conf.d/login.conf
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^login$ /login/ [L]
</IfModule>

Alias /login /var/www/html/login
<Directory "/var/www/html/login">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
    DirectoryIndex index.html
</Directory>
EOF

mkdir -p /var/www/html/login
echo "<h1>Login Page</h1><p>You have reached the /login endpoint</p>" > /var/www/html/login/index.html

systemctl enable --now httpd
