#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit
fi

echo "Welcome to the WebDev website deployment script!"

# Ask user for domain
read -p "Enter your domain name (example.com): " DOMAIN
read -p "Enter your email for SSL certificate: " EMAIL

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install necessary packages: Nginx, Git, Certbot
echo "Installing Nginx, Git, and Certbot..."
apt install nginx git certbot python3-certbot-nginx -y

# Create website directory
WEB_DIR="/var/www/$DOMAIN"
if [ -d "$WEB_DIR" ]; then
    echo "Directory $WEB_DIR already exists. Pulling latest changes from GitHub..."
    cd "$WEB_DIR" || exit
    git pull
else
    echo "Cloning GitHub repository into $WEB_DIR..."
    git clone https://github.com/Emil7YT/WebDev.git "$WEB_DIR"
fi

# Set permissions
chown -R www-data:www-data "$WEB_DIR"
chmod -R 755 "$WEB_DIR"

# Create Nginx server block if it doesn't exist
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
if [ ! -f "$NGINX_CONF" ]; then
    echo "Creating Nginx configuration for $DOMAIN..."
    cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $WEB_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL
    # Enable site
    ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
fi

# Test and reload Nginx
nginx -t && systemctl restart nginx

# Request SSL certificate if not already done
if ! certbot certificates | grep -q "$DOMAIN"; then
    echo "Requesting SSL certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
fi

# Ensure automatic renewal
systemctl enable certbot.timer

echo "----------------------------------------"
echo "Deployment complete!"
echo "You can now access your website at: https://$DOMAIN"
echo "Website files are located at $WEB_DIR"
echo "To update the site later, run:"
echo "  cd $WEB_DIR && git pull && sudo systemctl reload nginx"
echo "----------------------------------------"
