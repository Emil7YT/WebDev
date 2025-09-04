#!/bin/bash

# List available website directories
echo "Detecting websites in /var/www/..."
SITES=()
i=1
for dir in /var/www/*/ ; do
    [ -d "$dir" ] || continue
    dir_name=$(basename "$dir")
    SITES+=("$dir_name")
    echo "[$i] $dir_name"
    i=$((i+1))
done

# Ask user to choose which site to apply the addon to
read -p "Enter the number of the site you want to edit: " SITE_NUM
WEB_DIR="/var/www/${SITES[$((SITE_NUM-1))]}"
INDEX_FILE="$WEB_DIR/index.html"

# Ask for new heading texts
read -p "Enter new <h1> text: " NEW_H1
read -p "Enter new <h3> text: " NEW_H3

# Download the addon HTML from GitHub
ADDON_URL="https://raw.githubusercontent.com/Emil7YT/WebDev/main/Addons/Editable%20Text/index.html"
TMP_FILE="/tmp/addon_index.html"

echo "Downloading addon template..."
curl -fsSL "$ADDON_URL" -o "$TMP_FILE"

# Replace <h1> and <h3> text in the downloaded file
sed -i "s|<h1>.*</h1>|<h1>$NEW_H1</h1>|" "$TMP_FILE"
sed -i "s|<h3>.*</h3>|<h3>$NEW_H3</h3>|" "$TMP_FILE"

# Backup existing index.html
cp "$INDEX_FILE" "$INDEX_FILE.bak"

# Replace the current index.html with the new addon HTML
cp "$TMP_FILE" "$INDEX_FILE"

# Set permissions
chown -R www-data:www-data "$WEB_DIR"
chmod 644 "$INDEX_FILE"

echo "Addon applied successfully to $WEB_DIR!"
echo "Backup of the original file saved as $INDEX_FILE.bak"
