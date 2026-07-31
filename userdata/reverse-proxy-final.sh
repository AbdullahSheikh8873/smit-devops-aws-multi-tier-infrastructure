#!/bin/bash
set -eux

apt update -y
apt install -y nginx

systemctl enable nginx

cat >/etc/nginx/sites-available/reverse-proxy <<NGINX
server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://10.1.6.115:8000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://10.1.2.215:80;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default

ln -sf /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy

nginx -t

systemctl restart nginx
systemctl enable nginx
