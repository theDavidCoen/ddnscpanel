#!/bin/bash

# ================================
# Dynamic DNS cPanel Remover Script (Safe Mode)
# Author: theDavidCoen
# Repo: https://github.com/theDavidCoen/ddnscpanel
# ================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Dynamic DNS & Secure Access Remover (Safe Mode) ---${NC}"

read -p "Enter Service Name you want to remove (e.g., jellyfin): " serviceName

if [ -z "$serviceName" ]; then
  echo -e "${RED}Service Name is required. Exiting.${NC}"
  exit 1
fi

# Step 1: Remove DDNS update script
if [ -f ~/scripts/update_ddns.sh ]; then
  read -p "$(echo -e ${YELLOW}"Delete DDNS update script ~/scripts/update_ddns.sh? [y/N] "${NC})" confirm
  if [[ $confirm == [yY] ]]; then
    echo -e "${GREEN}Removing DDNS update script...${NC}"
    rm -f ~/scripts/update_ddns.sh
  else
    echo -e "${YELLOW}Skipped removing DDNS update script.${NC}"
  fi
else
  echo -e "${RED}No DDNS update script found.${NC}"
fi

# Step 2: Remove cron job
read -p "$(echo -e ${YELLOW}"Remove cron job for DDNS updates? [y/N] "${NC})" confirm
if [[ $confirm == [yY] ]]; then
  echo -e "${GREEN}Removing cron job...${NC}"
  ( crontab -l | grep -v "update_ddns.sh" ) | crontab -
else
  echo -e "${YELLOW}Skipped removing cron job.${NC}"
fi

# Step 3: Remove Nginx configuration
if [ -f /etc/nginx/sites-available/$serviceName ]; then
  read -p "$(echo -e ${YELLOW}"Delete Nginx config for $serviceName? [y/N] "${NC})" confirm
  if [[ $confirm == [yY] ]]; then
    echo -e "${GREEN}Removing Nginx config...${NC}"
    sudo rm -f /etc/nginx/sites-available/$serviceName
    sudo rm -f /etc/nginx/sites-enabled/$serviceName
    sudo nginx -t && sudo systemctl reload nginx
  else
    echo -e "${YELLOW}Skipped removing Nginx config.${NC}"
  fi
else
  echo -e "${RED}No Nginx config found for $serviceName.${NC}"
fi

# Step 4: Remove SSL certificate with Certbot
read -p "$(echo -e ${YELLOW}"Delete SSL certificate (Let's Encrypt) for $serviceName? [y/N] "${NC})" confirm
if [[ $confirm == [yY] ]]; then
  echo -e "${GREEN}Removing SSL certificate...${NC}"
  sudo certbot delete --cert-name $serviceName.$(hostname -d) || echo -e "${RED}SSL certificate not found or already deleted.${NC}"
else
  echo -e "${YELLOW}Skipped removing SSL certificate.${NC}"
fi

# Step 5: Skip UFW rules (Firewall)
echo -e "${GREEN}Skipping firewall (UFW) changes as requested.${NC}"

# Step 6: Cleanup empty script folder (optional)
if [ -d ~/scripts ]; then
  rmdir --ignore-fail-on-non-empty ~/scripts
fi

echo -e "${GREEN}--- Safe Removal Complete! ---${NC}"
