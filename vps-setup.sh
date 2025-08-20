##!/bin/bash
#
## PeerLink VPS Setup Script
## This script helps set up PeerLink on a fresh Ubuntu/Debian VPS
#
## Exit on error
#set -e
#
#echo "=== PeerLink VPS Setup Script ==="
#echo "This script will install Java, Node.js, Nginx, and set up PeerLink."
#
## Update system
#echo "Updating system packages..."
#sudo apt update
#sudo apt upgrade -y
#
## Install Java
#echo "Installing Java..."
#sudo apt install -y openjdk-17-jdk
#
## Install Node.js
#echo "Installing Node.js..."
#curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
#sudo apt install -y nodejs
#
## Install Nginx
#echo "Installing Nginx..."
#sudo apt install -y nginx
#
## Install PM2
#echo "Installing PM2..."
#sudo npm install -g pm2
#
## Install Maven
#echo "Installing Maven..."
#sudo apt install -y maven
#
## Clone repository (uncomment and modify if using Git)
## echo "Cloning repository..."
## git clone https://github.com/yourusername/peerlink.git
## cd peerlink
#
## Build backend
#echo "Building Java backend..."
#mvn clean package
#
## Build frontend
#echo "Building frontend..."
#cd ui
#npm install
#npm run build
#cd ..
#
## Set up Nginx
#echo "Setting up Nginx..."
#
## Ensure the default site is removed to avoid conflicts
#if [ -e /etc/nginx/sites-enabled/default ]; then
#    sudo rm /etc/nginx/sites-enabled/default
#    echo "Removed default Nginx site configuration."
#fi
#
## Create the peerlink configuration file with the correct content
#echo "Creating /etc/nginx/sites-available/peerlink..."
#cat <<EOF | sudo tee /etc/nginx/sites-available/peerlink
#server {
#    listen 80;
#    server_name rishav.rishavprojects.live; # Catch-all for HTTP requests
#
#    # Backend API
#    location /api/ {
#        proxy_pass http://localhost:8080/;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade \$http_upgrade;
#        proxy_set_header Connection 'upgrade';
#        proxy_set_header Host \$host;
#        proxy_set_header X-Real-IP \$remote_addr;
#        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto \$scheme;
#        proxy_cache_bypass \$http_upgrade;
#    }
#
#    # Frontend
#    location / {
#        proxy_pass http://localhost:3000;
#        proxy_http_version 1.1;
#        proxy_set_header Upgrade \$http_upgrade;
#        proxy_set_header Connection 'upgrade';
#        proxy_set_header Host \$host;
#        proxy_set_header X-Real-IP \$remote_addr;
#        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto \$scheme;
#        proxy_cache_bypass \$http_upgrade;
#    }
#
#    # Additional security headers (still good to have)
#    add_header X-Content-Type-Options nosniff;
#    add_header X-Frame-Options SAMEORIGIN;
#    add_header X-XSS-Protection "1; mode=block";
#}
#EOF
#
## Create the symbolic link to enable the peerlink site
#sudo ln -sf /etc/nginx/sites-available/peerlink /etc/nginx/sites-enabled/peerlink
#
#sudo nginx -t
#if [ $? -eq 0 ]; then
#    sudo systemctl restart nginx
#    echo "Nginx configured and restarted successfully."
#else
#    echo "Nginx configuration test failed. Please check /etc/nginx/nginx.conf and /etc/nginx/sites-available/peerlink."
#    exit 1
#fi
#
## Set up SSL with Let's Encrypt (uncomment if needed)
## echo "Setting up SSL with Let's Encrypt..."
## sudo apt install -y certbot python3-certbot-nginx
## sudo certbot --nginx -d your-actual-domain.com
#
## Start backend with PM2
#echo "Starting backend with PM2..."
## Ensure all dependencies are in the classpath
#CLASSPATH="target/p2p-1.0-SNAPSHOT.jar:$(mvn dependency:build-classpath -DincludeScope=runtime -Dmdep.outputFile=/dev/stdout -q)"
#pm2 start --name peerlink-backend java -- -cp "$CLASSPATH" p2p.App
#
## Start frontend with PM2
## echo "Starting frontend with PM2..."
## cd ui
## pm2 start npm --name peerlink-frontend -- start
## cd ..
#
## Save PM2 configuration
#pm2 save
#
## Set up PM2 to start on boot
#echo "Setting up PM2 to start on boot..."
#pm2 startup
## Follow the instructions printed by the above command
#
#echo "=== Setup Complete ==="
#echo "PeerLink is now running on your VPS!"
#echo "Backend API: http://localhost:8080 (Internal - accessed via Nginx)"
#echo "Frontend: http://your_lightsail_public_ip (Access via your instance's IP address)"
#echo "You can access your application using your Lightsail instance's public IP address in your browser."
## echo "Visit https://your-actual-domain.com to access your application."


# PeerLink VPS Setup Script
# This script helps set up PeerLink on a fresh Ubuntu/Debian VPS
# Exit on error
set -e

echo "=== PeerLink VPS Setup Script ==="
echo "This script will install Java, Node.js, Nginx, and set up PeerLink."

# --- Variables ---
# Replace with your actual domain and repository URL
DOMAIN="rishav.rishavprojects.live"

# --- System Setup ---
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y openjdk-17-jdk nodejs npm nginx maven git certbot python3-certbot-nginx

# --- Application Setup ---
#echo "Cloning repository..."
#git clone "$REPO_URL" "$PROJECT_DIR"
#cd "$PROJECT_DIR"

echo "Building Java backend..."
# Use Maven wrapper if available, or just 'mvn'
mvn clean package

echo "Building frontend..."
cd ui
npm install
npm run build
cd ..

# --- Nginx Setup ---
echo "Setting up Nginx..."
if [ -e /etc/nginx/sites-enabled/default ]; then
  sudo rm /etc/nginx/sites-enabled/default
  echo "Removed default Nginx site configuration."
fi

echo "Creating Nginx configuration for $DOMAIN..."
cat <<EOF | sudo tee /etc/nginx/sites-available/peerlink
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect to HTTPS
    return 301 https://$DOMAIN\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Frontend Static Files
    location / {
        root `pwd`/ui/build;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/peerlink /etc/nginx/sites-enabled/peerlink
sudo nginx -t

if [ $? -eq 0 ]; then
  echo "Nginx configuration test successful."
else
  echo "Nginx configuration test failed. Please check the config file."
  exit 1
fi

sudo systemctl restart nginx
echo "Nginx configured and restarted."

# --- SSL with Certbot ---
echo "Setting up SSL with Let's Encrypt..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m your_email@example.com

# --- Process Management with PM2 ---
echo "Setting up PM2..."
sudo npm install -g pm2

echo "Starting backend with PM2..."
# The correct command for a Spring Boot/Maven app that produces an executable JAR
JAR_NAME=$(ls target/*.jar | grep -v 'original' | head -n 1)
pm2 start java --name peerlink-backend -- -jar "$JAR_NAME"

echo "Starting frontend with PM2..."
# Use a static file server like 'serve' for the frontend build
npm install -g serve
pm2 start serve --name peerlink-frontend -- -s ui/build -l 3000

# Save PM2 configuration and enable startup
pm2 save
pm2 startup

echo "=== Setup Complete ==="
echo "PeerLink is now running and accessible via https://$DOMAIN"
