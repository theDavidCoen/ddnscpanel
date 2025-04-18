#!/bin/bash

# Dynamic DNS & Secure Access Automatic Configurator for cPanel Users
# Improved Version with colors, checks, and options

# ---- COLORS ----
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---- FUNCTIONS ----
function ok() { echo -e "${GREEN}✅ $1${NC}"; }
function info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
function error() { echo -e "${RED}❌ $1${NC}"; }

# ---- ROOT CHECK ----
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root (use sudo)"
    exit 1
fi

# ---- DEPENDENCY CHECK ----
info "Checking required commands..."

for cmd in curl cron nginx certbot; do
    if ! command -v $cmd &> /dev/null; then
        if [ "$cmd" == "cron" ]; then
            apt install cron -y
            systemctl enable cron
            systemctl start cron
        else
            info "Installing missing package: $cmd"
            apt update
            apt install -y $cmd
        fi
    else
        ok "$cmd is installed."
    fi
done

# ---- ASK USER INPUT ----
echo
info "Configure your Dynamic DNS and Reverse Proxy Setup:"
read -p "Enter Service Name: " serviceName
read -p "Enter Local IP (e.g., 192.168.1.100): " localIP
read -p "Enter Port (e.g., 8080): " port
read -p "Enter Domain (e.g., home.yourdomain.com): " domain
read -p "Enter DDNS Update URL: " ddnsURL
read -p "Enter DDNS update interval in minutes (e.g., 5): " interval

# Validate interval
if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    error "Interval must be a number."
    exit 1
fi

# ---- DDNS SCRIPT CREATION ----
info "Setting up Dynamic DNS update script..."

mkdir -p ~/scripts
cat <<EOF > ~/scripts/update_ddns.sh
#!/bin/bash
curl -s "$ddnsURL"
EOF

chmod +x ~/scripts/update_ddns.sh
ok "DDNS update script created at ~/scripts/update_ddns.sh"

# ---- ADD TO CRONTAB ----
info "Scheduling DDNS script every $interval minute(s) with crontab..."

# Clean old entry if exists
crontab -l 2>/dev/null | grep -v 'update_ddns.sh' | crontab -

# Add new entry
(crontab -l 2>/dev/null; echo "*/$interval * * * * ~/scripts/update_ddns.sh >/dev/null 2>&1") | crontab -

ok "DDNS script scheduled."

# ---- INSTALL AND CONFIGURE NGINX ----
info "Setting up Nginx reverse proxy for $domain..."

# Create Nginx configuration
cat <<EOF > /etc/nginx/sites-available/$serviceName
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://$localIP:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        add_header X-Robots-Tag "noindex, nofollow" always;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/$serviceName /etc/nginx/sites-enabled/

# Test Nginx config
if nginx -t; then
    systemctl reload nginx
    ok "Nginx configuration successful and reloaded."
else
    error "Nginx config test failed. Aborting."
    exit 1
fi

# ---- CERTBOT SSL SETUP ----
info "Requesting SSL Certificate via Certbot..."

if certbot --nginx -d "$domain" --non-interactive --agree-tos -m admin@$domain --redirect; then
    ok "SSL certificate installed and HTTPS redirect enabled."
else
    error "Certbot failed. You may need to check DNS records or firewall."
fi

# ---- UFW FIREWALL SETTINGS ----
info "Configuring UFW firewall (allowing ports 80 and 443)..."

ufw allow 80/tcp
ufw allow 443/tcp
ufw reload
ok "Firewall rules updated."

# ---- FINAL MESSAGE ----
echo
ok "🎉 Setup Complete!"
info "Your $serviceName service should now be accessible securely at: https://$domain"
echo
