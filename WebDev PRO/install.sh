#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit
fi

echo "Welcome to the WebDev PRO installer/uninstaller!"
echo "1) Install WebDev PRO"
echo "2) Uninstall WebDev PRO"
read -p "Choose an option [1-2]: " OPTION

if [ "$OPTION" == "2" ]; then
  read -p "Enter your domain name to uninstall (example.com): " DOMAIN
  WEB_DIR="/var/www/$DOMAIN"
  NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

  echo "Stopping and cleaning up WebDev PRO for $DOMAIN..."

  # Remove website directory
  if [ -d "$WEB_DIR" ]; then
    rm -rf "$WEB_DIR"
    echo "Removed $WEB_DIR"
  fi

  # Remove Nginx config
  if [ -f "$NGINX_CONF" ]; then
    rm -f "$NGINX_CONF"
    rm -f "/etc/nginx/sites-enabled/$DOMAIN"
    echo "Removed Nginx config for $DOMAIN"
  fi

  # Reload Nginx
  systemctl reload nginx

  # Delete SSL certificates
  certbot delete --cert-name "$DOMAIN" -n 2>/dev/null

  echo "Uninstallation complete!"
  exit 0
fi

# ------------------- INSTALL MODE -------------------

echo "Proceeding with WebDev PRO installation..."

# Ask for domain and email
read -p "Enter your domain name (example.com or sub.example.com): " DOMAIN
read -p "Enter your email for SSL certificate: " EMAIL

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install necessary packages
echo "Installing Nginx, Git, and Certbot..."
apt install nginx git certbot python3-certbot-nginx -y

# Create website directory
WEB_DIR="/var/www/$DOMAIN"
mkdir -p "$WEB_DIR"

# Download WebDev PRO files
echo "Downloading WebDev PRO files..."
curl -fsSL "https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/index.html" -o "$WEB_DIR/index.html"
curl -fsSL "https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/style.css" -o "$WEB_DIR/style.css"

# Set permissions
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"

# Create Nginx config if missing
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
if [ ! -f "$NGINX_CONF" ]; then
    echo "Creating Nginx configuration for $DOMAIN..."
    cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    root $WEB_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL
    ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
fi

# Reload Nginx
nginx -t && systemctl restart nginx

# Request SSL cert
if ! certbot certificates | grep -q "$DOMAIN"; then
    echo "Requesting SSL certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
fi

# Enable auto-renew
systemctl enable certbot.timer

echo "----------------------------------------"
echo "WebDev PRO deployment complete!"
echo "Access your site at: https://$DOMAIN"
echo "Website files: $WEB_DIR"
echo "To update later: curl -fsSL https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/install.sh | sudo bash"
echo "----------------------------------------"
