#!/bin/bash

set -euo pipefail

####################################################
# SMIT DevOps Assignment
# AWS Multi-Tier Infrastructure Deployment
# Author: Abdullah Sheikh
####################################################

##############################
# AWS Configuration
##############################

REGION="ap-southeast-1"
AMI_ID="ami-0ed6a65b84536f6ce"
INSTANCE_TYPE="t3.micro"
KEY_NAME="DEV-PEM-KP"

##############################
# Network Configuration
##############################

VPC_ID="vpc-0e63acc374dd13e17"

PUB_SUBNET_1="subnet-09bd45133cdb3c880"
PUB_SUBNET_2="subnet-0be2fdb168b0e927a"
PUB_SUBNET_3="subnet-01d849b13473bad6f"

PVT_SUBNET_1="subnet-0da14191b866530e3"
PVT_SUBNET_2="subnet-0ea93051eefce2ed6"
PVT_SUBNET_3="subnet-0a977b8d3f5639a68"

echo "====================================="
echo "AWS Multi-Tier Infrastructure"
echo "====================================="

#############################################
# Check AWS CLI
#############################################

echo ""
echo "[INFO] Checking AWS CLI..."

if ! command -v aws >/dev/null 2>&1; then
    echo "[ERROR] AWS CLI is not installed."
    exit 1
fi

echo "[SUCCESS] AWS CLI Found."

#############################################
# Check AWS Credentials
#############################################

echo ""
echo "[INFO] Checking AWS Credentials..."

aws sts get-caller-identity >/dev/null

echo "[SUCCESS] AWS Credentials Verified."

#############################################
# Check Key Pair
#############################################

echo ""
echo "[INFO] Checking Key Pair..."

aws ec2 describe-key-pairs \
    --region "$REGION" \
    --key-name "$KEY_NAME" >/dev/null

echo "[SUCCESS] Key Pair Found."

#############################################
# Existing Security Groups
#############################################

echo ""
echo "====================================="
echo "Using Existing Security Groups"
echo "====================================="


VPN_SG="sg-014bdbe93a9629ef0"

SQUID_SG="sg-0d709144599735cf9"

REVERSE_PROXY_SG="sg-01140542a0ca71fb3"

FRONTEND_SG="sg-01140542a0ca71fb3"

BACKEND_SG="sg-02913c5642277c0b7"

NAT_SG="sg-0d130dd76fbd70b2c"


echo "VPN SG : $VPN_SG"
echo "SQUID SG : $SQUID_SG"
echo "REVERSE PROXY SG : $REVERSE_PROXY_SG"
echo "FRONTEND SG : $FRONTEND_SG"
echo "BACKEND SG : $BACKEND_SG"
echo "NAT SG : $NAT_SG"


#############################################
# NAT Instance Variables
#############################################

NAT_INSTANCE_ID=""
NAT_PRIVATE_IP=""

#############################################
# Launch NAT Instance
#############################################

echo ""
echo "Launching NAT Instance..."

NAT_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$NAT_SG" \
    --subnet-id "$PUB_SUBNET_1" \
    --associate-public-ip-address \
    --user-data file://userdata/nat-instance.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-NAT}]' \
    --query "Instances[0].InstanceId" \
    --output text)

echo "NAT Instance ID : $NAT_INSTANCE_ID"

echo ""

echo "Waiting for NAT Instance..."

aws ec2 wait instance-running \
    --instance-ids "$NAT_INSTANCE_ID" \
    --region "$REGION"

echo "Running..."

aws ec2 modify-instance-attribute \
    --instance-id "$NAT_INSTANCE_ID" \
    --source-dest-check "{\"Value\": false}" \
    --region "$REGION"

echo "Source/Destination Check Disabled"

NAT_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$NAT_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

echo "NAT Private IP : $NAT_PRIVATE_IP"

#############################################
# Update Private Route Table
#############################################

echo ""
echo "Updating Private Route Table..."

PVT_ROUTE_TABLE_ID="rtb-084f82761f1d4aade"


aws ec2 create-route \
    --route-table-id "$PVT_ROUTE_TABLE_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --instance-id "$NAT_INSTANCE_ID" \
    --region "$REGION"


echo "Private Route Table Updated"

#############################################
# Launch Backend EC2
#############################################

echo ""
echo "====================================="
echo "Launching Backend Server..."
echo "====================================="


BACKEND_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$BACKEND_SG" \
    --subnet-id "$PVT_SUBNET_1" \
    --no-associate-public-ip-address \
    --user-data file://userdata/backend.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-BACKEND}]' \
    --query "Instances[0].InstanceId" \
    --output text)


echo "Backend Instance ID : $BACKEND_INSTANCE_ID"

echo ""
echo "Waiting for Backend Instance..."

aws ec2 wait instance-running \
    --instance-ids "$BACKEND_INSTANCE_ID" \
    --region "$REGION"

echo "Backend Running"

BACKEND_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$BACKEND_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)


echo "Backend Private IP : $BACKEND_PRIVATE_IP"

#############################################
# Launch Frontend EC2
#############################################

echo ""
echo "====================================="
echo "Launching Frontend Server..."
echo "====================================="


FRONTEND_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$FRONTEND_SG" \
    --subnet-id "$PUB_SUBNET_2" \
    --associate-public-ip-address \
    --user-data file://userdata/frontend.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-FRONTEND}]' \
    --query "Instances[0].InstanceId" \
    --output text)


echo "Frontend Instance ID : $FRONTEND_INSTANCE_ID"

echo ""
echo "Waiting for Frontend Instance..."

aws ec2 wait instance-running \
    --instance-ids "$FRONTEND_INSTANCE_ID" \
    --region "$REGION"

echo "Frontend Running"

FRONTEND_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-id "$FRONTEND_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)


echo "Frontend Private IP : $FRONTEND_PRIVATE_IP"

#############################################
# Create Reverse Proxy User Data
#############################################

cat > userdata/reverse-proxy-final.sh <<EOF
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
        proxy_pass http://${BACKEND_PRIVATE_IP}:8000;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        proxy_pass http://${FRONTEND_PRIVATE_IP}:80;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default

ln -sf /etc/nginx/sites-available/reverse-proxy \
/etc/nginx/sites-enabled/reverse-proxy

nginx -t

systemctl restart nginx
systemctl enable nginx
EOF


#############################################
# Launch Reverse Proxy EC2
#############################################

echo ""
echo "====================================="
echo "Launching Reverse Proxy Server..."
echo "====================================="


REVERSE_PROXY_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$REVERSE_PROXY_SG" \
    --subnet-id "$PUB_SUBNET_3" \
    --associate-public-ip-address \
    --user-data file://userdata/reverse-proxy-final.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-REVERSE-PROXY}]' \
    --query "Instances[0].InstanceId" \
    --output text)


echo "Reverse Proxy Instance ID : $REVERSE_PROXY_INSTANCE_ID"

echo ""
echo "Waiting for Reverse Proxy..."

aws ec2 wait instance-running \
    --instance-ids "$REVERSE_PROXY_INSTANCE_ID" \
    --region "$REGION"

echo "Reverse Proxy Running"

REVERSE_PROXY_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$REVERSE_PROXY_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)


echo "Reverse Proxy Private IP : $REVERSE_PROXY_PRIVATE_IP"

#############################################
# Launch VPN EC2
#############################################

echo ""
echo "====================================="
echo "Launching VPN Server..."
echo "====================================="

VPN_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$VPN_SG" \
    --subnet-id "$PUB_SUBNET_1" \
    --associate-public-ip-address \
    --user-data file://userdata/vpn.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-VPN}]' \
    --query "Instances[0].InstanceId" \
    --output text)

echo "VPN Instance ID : $VPN_INSTANCE_ID"

aws ec2 wait instance-running \
    --instance-ids "$VPN_INSTANCE_ID" \
    --region "$REGION"

VPN_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$VPN_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "VPN Public IP : $VPN_PUBLIC_IP"

#############################################
# Launch Squid EC2
#############################################

echo ""
echo "====================================="
echo "Launching Squid Server..."
echo "====================================="

SQUID_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SQUID_SG" \
    --subnet-id "$PUB_SUBNET_2" \
    --associate-public-ip-address \
    --user-data file://userdata/squid.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DEV-SQUID}]' \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Squid Instance ID : $SQUID_INSTANCE_ID"

aws ec2 wait instance-running \
    --instance-ids "$SQUID_INSTANCE_ID" \
    --region "$REGION"

SQUID_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$SQUID_INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "Squid Public IP : $SQUID_PUBLIC_IP"

echo ""
echo "====================================="
echo "Deployment Completed"
echo "====================================="

aws ec2 describe-instances \
    --region "$REGION" \
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name']|[0].Value,State.Name,PublicIpAddress,PrivateIpAddress]" \
    --output table