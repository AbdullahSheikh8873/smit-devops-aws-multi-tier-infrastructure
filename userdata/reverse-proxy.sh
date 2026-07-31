#!/bin/bash
set -eux

echo "Installing NGINX..."

apt update -y
apt install -y nginx

systemctl enable nginx


cat > /etc/nginx/sites-available/reverse-proxy <<EOF

server {

    listen 80;

    server_name _;


    location /api/ {

        proxy_pass http://${BACKEND_PRIVATE_IP}:8000/;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

    }


    location / {

        proxy_pass http://${FRONTEND_PRIVATE_IP}:80/;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

    }

}

EOF


rm -f /etc/nginx/sites-enabled/default


ln -s /etc/nginx/sites-available/reverse-proxy \
/etc/nginx/sites-enabled/reverse-proxy


nginx -t

systemctl restart nginx


echo "Reverse Proxy Setup Completed"
