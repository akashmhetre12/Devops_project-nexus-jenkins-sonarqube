#!/bin/bash
# ============================================================
# SonarQube - Docker Installation (Community Edition)
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

echo "==> Applying required kernel setting (Elasticsearch needs this)..."
sudo sysctl -w vm.max_map_count=262144
# Persist across reboots
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -w fs.file-max=65536

echo "==> Creating volumes for persistence..."
docker volume create sonarqube_data
docker volume create sonarqube_logs
docker volume create sonarqube_extensions

echo "==> Running SonarQube container..."
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  --ulimit nofile=65536:65536 \
  --memory="3g" \
  sonarqube:community

echo "==> Waiting for SonarQube to start (60-120s)..."
sleep 60

echo ""
echo "============================================================"
echo "SonarQube is starting at: http://<server-ip>:9000"
echo "Default login: admin / admin (you'll be forced to change it)"
echo "Check logs if it's not up yet: docker logs -f sonarqube"
echo "IMPORTANT: Open port 9000 in your Security Group / firewall."
echo "NOTE: Community Edition has no built-in DB - it uses embedded"
echo "H2 by default, but for production point it to PostgreSQL via"
echo "SONAR_JDBC_URL / SONAR_JDBC_USERNAME / SONAR_JDBC_PASSWORD env vars."
echo "============================================================"
