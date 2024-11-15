#!/bin/bash

# Variables
JENKINS_SERVICE_FILE="/etc/systemd/system/jenkins.service"
KEYSTORE_PATH="/etc/ssl/jenkins/keystore.jks"
KEYSTORE_PASSWORD=$(openssl rand -base64 12)  # Automatically generated password
DOMAIN="hireme.com"                   # Replace with your domain or server IP
JENKINS_HOME="/var/lib/jenkins"


# Update System and Install Basic Dependencies
echo "Updating system and installing required packages..."
apt update && apt install -y wget curl gnupg software-properties-common

# Download and Install Oracle JDK 21
echo "Downloading Oracle JDK 21..."
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb

echo "Installing Oracle JDK 21..."
dpkg -i jdk-21_linux-x64_bin.deb

# Verify Java Installation
echo "Verifying Java version..."
java -version

# Set Java 21 as Default
echo "Setting Java 21 as the default Java version..."
update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-21/bin/java 1
update-alternatives --set java /usr/lib/jvm/jdk-21/bin/java
update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-21/bin/javac 1
update-alternatives --set javac /usr/lib/jvm/jdk-21/bin/javac

# Install Fonts to Fix AWT Issues
echo "Installing fonts required by Jenkins..."
apt install -y fontconfig fonts-dejavu

# Rebuild Font Cache
echo "Rebuilding font cache..."
fc-cache -f -v

# Add Jenkins Repository and Install Jenkins
echo "Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Installing Jenkins..."
apt update && apt install -y jenkins

# Install Git
echo "Installing Git..."
apt install -y git

# Add HashiCorp GPG Key and Repository
echo "Adding HashiCorp GPG key and repository for Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update Package List and Install Terraform
echo "Updating package list and installing Terraform..."
apt update && apt install -y terraform

# Verify Terraform Installation
echo "Verifying Terraform version..."
terraform -version

# Generate Keystore
echo "Creating keystore at $KEYSTORE_PATH..."
mkdir -p /etc/ssl/jenkins
keytool -genkeypair -alias jenkins -keyalg RSA -keysize 2048 \
  -validity 365 -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
  -dname "CN=$DOMAIN, OU=IT, O=Company, L=City, ST=State, C=Country"

# Set Permissions
echo "Setting permissions for keystore..."
chown jenkins:jenkins "$KEYSTORE_PATH"
chmod 600 "$KEYSTORE_PATH"


# Create Custom Jenkins Service File
echo "Creating custom Jenkins service file at $JENKINS_SERVICE_FILE..."
cat <<EOF > "$JENKINS_SERVICE_FILE"
[Unit]
Description=Jenkins Continuous Integration Server
Documentation=https://www.jenkins.io/doc/
After=network.target

[Service]
User=jenkins
Group=jenkins
WorkingDirectory=$JENKINS_HOME

ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war \\
  --httpPort=-1 \\
  --httpsPort=443 \\
  --httpsListenAddress=0.0.0.0 \\
  --httpsKeyStore=$KEYSTORE_PATH \\
  --httpsKeyStorePassword=$KEYSTORE_PASSWORD

AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=5s
Environment="JENKINS_HOME=$JENKINS_HOME"

[Install]
WantedBy=multi-user.target
EOF

# Reload Systemd, Enable, and Start Jenkins
echo "Reloading systemd and starting Jenkins..."
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Check Status
echo "Checking Jenkins status..."
systemctl status jenkins --no-pager

# Firewall Configuration (Optional)
echo "Configuring firewall for HTTPS..."
ufw allow 443
ufw reload

# Final Instructions
echo "Jenkins is deployed with HTTPS using the keystore."
echo "Git and Terraform are installed."
echo "Access Jenkins at: https://$DOMAIN or https://<your_server_ip>"
echo "Keystore is stored at: $KEYSTORE_PATH"
echo "Generated Keystore Password: $KEYSTORE_PASSWORD"
