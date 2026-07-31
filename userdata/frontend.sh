#!/bin/bash
set -eux

# Update packages
apt update -y
apt upgrade -y

# Install NGINX
apt install -y nginx

# Enable NGINX
systemctl enable nginx

# Create Website
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>SMIT DevOps Assignment</title>
    <style>
        body{
            font-family: Arial, sans-serif;
            background:#f4f4f4;
            text-align:center;
            padding-top:80px;
        }
        .container{
            background:white;
            width:600px;
            margin:auto;
            padding:30px;
            border-radius:10px;
            box-shadow:0 0 15px rgba(0,0,0,.2);
        }
        h1{
            color:#2c3e50;
        }
        p{
            font-size:18px;
            color:#555;
        }
    </style>
</head>
<body>

<div class="container">

<h1>SMIT DevOps Assignment</h1>

<p>Frontend Server is Running Successfully</p>

<p>Served by NGINX</p>

</div>

</body>
</html>
EOF

# Restart NGINX
systemctl restart nginx

echo "Frontend setup completed."