# Dynamic DNS & Secure Access Configurator for cPanel Users

[![License](https://img.shields.io/github/license/theDavidCoen/ddnscpanel)](https://github.com/theDavidCoen/ddnscpanel/blob/main/README.md#license)
[![Stars](https://img.shields.io/github/stars/theDavidCoen/ddnscpanel?style=social)](https://github.com/theDavidCoen/ddnscpanel)
[![Issues](https://img.shields.io/github/issues/theDavidCoen/ddnscpanel)](https://github.com/theDavidCoen/ddnscpanel/issues)

---

Automatically configure **Dynamic DNS (DDNS)**, **reverse proxy (Nginx)**, **port forwarding**, and **Let's Encrypt SSL certificates** for services hosted behind a dynamic IP address.

The setup script is designed for users who:
- Have a **dynamic public IP** (ISP changes your IP frequently)
- Manage domains via **cPanel Dynamic DNS**
- Want to access **home services remotely** (e.g., Jellyfin, Home Assistant, etc.)
- Want **secure HTTPS access** with free SSL (Let's Encrypt)

If you need to undo everything, just run the cleanup script https://github.com/theDavidCoen/ddnscpanel/edit/main/README.md#-cleanup--removal-safe-mode

---

## Features

- ✅ Automatic Dynamic DNS script creation
- ✅ Cron job setup for periodic updates
- ✅ Nginx reverse proxy configuration
- ✅ SSL Certificate installation (Let's Encrypt)
- ✅ Firewall (UFW) configuration
- ✅ Dependency checks and auto-installations
- ✅ Interactive prompts and colored terminal output

---

## Requirements

- Ubuntu / Debian-based Linux server
- Root privileges (`sudo`)
- A domain managed through **cPanel Dynamic DNS**
- Access to your **DDNS Update URL** (from cPanel)

---

## Installation

```bash
# Clone the repository
git clone https://github.com/theDavidCoen/ddnscpanel.git

# Move into the project directory
cd ddnscpanel

# Make the script executable
chmod +x ddns_auto_setup.sh

# Run the script
sudo ./ddns_auto_setup.sh
```

---

## Usage

When you execute the script, it will ask you for the following details:

1. **Service Name** (e.g., `jellyfin`)
2. **Local IP Address** (e.g., `192.168.1.100`)
3. **Local Port** (e.g., `8096`)
4. **Domain Name** (e.g., `home.example.com`)
5. **DDNS Update URL** (provided by cPanel)
6. **DDNS Update Interval** (e.g., `5` minutes)

The script will then:

- Create a DDNS update script
- Set up a `cron` job for IP updates
- Configure Nginx as a reverse proxy
- Request a free SSL certificate from Let's Encrypt
- Open necessary firewall ports

---

## Example

```text
Enter Service Name: jellyfin
Enter Local IP (e.g., 192.168.1.100): 192.168.1.100
Enter Port (e.g., 8080): 8096
Enter Domain (e.g., home.yourdomain.com): home.example.com
Enter DDNS Update URL: https://cpanel.example.com/update?user=abc123&pass=xyz
Enter DDNS update interval in minutes (e.g., 5): 5
```

After completing, you will be able to access your service securely via:

```
https://home.example.com
```

with automatic IP updates and HTTPS enabled!

---

## 🧹 Cleanup / Removal (Safe Mode)

If you want to **safely remove** the setup:

```bash
cd ../cleanup
chmod +x ddns_remove.sh
sudo ./ddns_remove.sh
```

The script will:
- Ask for confirmation before each removal step
- Remove crontab jobs, scripts, Nginx configuration, SSL certificates
- **Does NOT touch your firewall rules (UFW)**

---

## Notes

- Ensure your router has **port forwarding** enabled for the service (forward the external port to your server’s internal IP and port).
- If SSL certificate request fails, check that your domain points to your current public IP (use tools like [whatsmydns.net](https://www.whatsmydns.net/)).
- The script assumes **UFW** (Uncomplicated Firewall) is installed; it will automatically open ports `80` and `443`.

---

## Troubleshooting

### Public IP not updating?

Check the cron jobs:

```bash
cat /var/log/syslog | grep CRON
```

Or manually test the DDNS update URL:

```bash
curl -s "YOUR_DDNS_UPDATE_URL"
```

### SSL certificate issues?

- Ensure port **80** is open and accessible externally.
- Confirm your domain is properly resolving to your public IP.
- Rerun the script or manually run Certbot:

```bash
sudo certbot --nginx -d your.domain.com
```

---
## Contributions

Pull requests are welcome! 🚀

For major changes, please open an issue first to discuss what you would like to change.

If you like this project, consider starring the repository ⭐

---

### ✨
*Made with 💻 by [theDavidCoen](https://github.com/theDavidCoen) — Automating the boring stuff, one script at a time.*
