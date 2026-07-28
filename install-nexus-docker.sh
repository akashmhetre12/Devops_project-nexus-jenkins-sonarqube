#!/bin/bash
# ============================================================
# Nexus Repository Manager 3 - Docker Installation
# Tested on: Ubuntu 20.04/22.04, Amazon Linux 2/2023
# ============================================================
set -e

echo "==> Installing Docker (skip if already installed)..."
if ! command -v docker &> /dev/null; then
    if [ -f /etc/debian_version ]; then
        sudo apt-get update -y
        sudo apt-get install -y docker.io
    else
        sudo yum update -y
        sudo yum install -y docker
    fi
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
fi

echo "==> Creating persistent volume for Nexus data..."
docker volume create nexus-data

echo "==> Running Nexus container..."
docker run -d \
  --name nexus \
  --restart unless-stopped \
  -p 8081:8081 \
  -v nexus-data:/nexus-data \
  --memory="2g" \
  sonatype/nexus3

echo "==> Waiting for Nexus to initialize (this can take 60-90s)..."
sleep 60

echo "==> Fetching initial admin password..."
docker exec nexus cat /nexus-data/admin.password 2>/dev/null || \
  echo "Password file not ready yet - run: docker exec nexus cat /nexus-data/admin.password"

echo ""
echo "============================================================"
echo "Nexus is starting at: http://<server-ip>:8081"
echo "Default username: admin"
echo "Initial password: see above (or /nexus-data/admin.password inside container)"
echo "IMPORTANT: Open port 8081 in your Security Group / firewall."
echo "============================================================"
