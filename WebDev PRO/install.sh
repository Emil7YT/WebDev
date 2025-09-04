#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit
fi

echo "Welcome to the WebDev PRO website deployment script!"

# Ask user for domain and email
read -p "Enter your domain name (example.com or sub.example.com): " DOMAIN
read -p "Enter your email for SSL certificate: " EMAIL

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Install necessary packages
echo "Installing Nginx, Git, and Certbot..."
apt install nginx git certbot python3-certbot-nginx -y

# Create website directory
WEB_DIR="/var/www/$DOMAIN"
if [ -d "$WEB_DIR" ]; then
    echo "Directory $WEB_DIR already exists. Pulling latest changes from GitHub..."
else
    echo "Creating website directory at $WEB_DIR..."
    mkdir -p "$WEB_DIR"
fi

# Download WebDev PRO files
echo "Downloading WebDev PRO files..."
curl -fsSL "https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/index.html" -o "$WEB_DIR/index.html"
curl -fsSL "https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/style.css" -o "$WEB_DIR/style.css"

# Set permissions
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"

# Create Nginx server block
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

# Test and reload Nginx
nginx -t && systemctl restart nginx

# Request SSL certificate if not already done
if ! certbot certificates | grep -q "$DOMAIN"; then
    echo "Requesting SSL certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
fi

# Enable automatic renewal
systemctl enable certbot.timer

echo "----------------------------------------"
echo "WebDev PRO deployment complete!"
echo "You can now access your website at: https://$DOMAIN"
echo "Website files are located at $WEB_DIR"
echo "To update the site later, run:"
echo "  curl -fsSL https://raw.githubusercontent.com/Emil7YT/WebDev-PRO/main/install.sh | sudo bash"
echo "----------------------------------------"
