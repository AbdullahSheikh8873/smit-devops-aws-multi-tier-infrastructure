#!/bin/bash
set -eux

# Update packages
apt update -y
apt upgrade -y

# Install Python
apt install -y python3 python3-pip python3-venv

# Create application directory
mkdir -p /opt/backend
cd /opt/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install FastAPI & Uvicorn
pip install --upgrade pip
pip install fastapi uvicorn

# Create FastAPI application
cat > app.py <<EOF
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Backend is running"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/api")
def api():
    return {"message": "Hello from FastAPI Backend"}
EOF

# Create systemd service
cat > /etc/systemd/system/backend.service <<EOF
[Unit]
Description=FastAPI Backend
After=network.target

[Service]
User=root
WorkingDirectory=/opt/backend
ExecStart=/opt/backend/venv/bin/uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable backend
systemctl start backend

echo "Backend setup completed."