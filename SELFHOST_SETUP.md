# 🏠 Selfhost Domain Setup Guide

## 📋 Prerequisites
- ✅ Domain purchased (e.g., `mydomain.com`)
- ✅ Cloudflare account (free tier works fine)
- ✅ Domain added to Cloudflare DNS
- ✅ NixOS system with our selfhost modules

## 🔧 Step 1: Cloudflare Setup

### 1.1 Add Domain to Cloudflare
1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click "Add a Site" 
3. Enter your domain (e.g., `mydomain.com`)
4. Choose Free plan
5. Follow instructions to update nameservers at your domain registrar

### 1.2 Create API Credentials

#### For DNS Challenge (ACME SSL):
1. Go to Cloudflare Dashboard → My Profile → API Tokens
2. Click "Create Token"
3. Use "Custom token" template:
   - **Token name**: `nixos-acme-dns`
   - **Permissions**: 
     - `Zone:DNS:Edit`
     - `Zone:Zone:Read`
   - **Zone Resources**: `Include → Specific zone → yourdomain.com`
4. Create and copy the token

#### For Fail2Ban (Firewall Rules):
1. Create another custom token:
   - **Token name**: `nixos-fail2ban`
   - **Permissions**: `Account:Cloudflare Tunnel:Edit`
   - **Account Resources**: Include → All accounts
5. Create and copy this token too

### 1.3 Get Zone ID
1. Go to Cloudflare Dashboard → Your Domain → Overview
2. Copy the "Zone ID" from the right sidebar

## 🔑 Step 2: Create Credential Files

### 2.1 DNS Credentials (for SSL certificates)
```bash
sudo mkdir -p /etc/nixos/secrets
sudo tee /etc/nixos/secrets/cloudflare-dns.env << EOF
CLOUDFLARE_DNS_API_TOKEN=your_dns_token_here
EOF
sudo chmod 600 /etc/nixos/secrets/cloudflare-dns.env
```

### 2.2 Firewall Credentials (for Fail2Ban)
```bash
sudo tee /etc/nixos/secrets/cloudflare-firewall.key << EOF
Authorization: Bearer your_firewall_token_here
EOF
sudo chmod 600 /etc/nixos/secrets/cloudflare-firewall.key
```

## ⚙️ Step 3: Update NixOS Configuration

Edit your system configuration (`systems/x86_64-linux/THEBATTLESHIP/default.nix`):

```nix
services.selfhost = {
    enable = true;
    baseDomain = "mydomain.com";  # ← YOUR ACTUAL DOMAIN
    acme.email = "admin@mydomain.com";  # ← YOUR EMAIL
    cloudflare.dnsCredentialsFile = "/etc/nixos/secrets/cloudflare-dns.env";
    
    # Storage paths (adjust to your system)
    mounts = {
        fast = "/mnt/cache";     # Fast storage (SSD)
        slow = "/mnt/storage";   # Slow storage (HDD) 
        config = "/persist/opt/services";
        merged = "/mnt/user";
    };
    
    # 🚀 Minimal initial services
    networking.enable = true;     # Tailscale, Syncthing
    dashboard.enable = true;      # Homepage at mydomain.com
    media.jellyfin.enable = true; # Media server at jellyfin.mydomain.com
    
    # 🛡️ Security (optional but recommended)
    utility.fail2ban-cloudflare = {
        enable = true;
        apiKeyFile = "/etc/nixos/secrets/cloudflare-firewall.key";
        zoneId = "your_zone_id_here";  # From Cloudflare dashboard
    };
};
```

## 🌐 Step 4: Router/Firewall Configuration

### 4.1 Port Forwarding
Forward these ports from your router to your NixOS machine:
- **Port 80** (HTTP) → Auto-redirects to HTTPS
- **Port 443** (HTTPS) → All your services

### 4.2 Dynamic DNS (if needed)
If you don't have a static IP, set up DDNS:
```bash
# Example with ddclient for Cloudflare
sudo tee /etc/nixos/secrets/ddclient.conf << EOF
protocol=cloudflare
zone=mydomain.com
ttl=300
login=your_cloudflare_email@example.com
password=your_dns_token
mydomain.com,*.mydomain.com
EOF
```

## 🚀 Step 5: Deploy and Test

### 5.1 Build and Deploy
```bash
sudo nixos-rebuild switch
```

### 5.2 Test Services
After deployment, these should work:
- **🏠 Homepage**: `https://mydomain.com`
- **📺 Jellyfin**: `https://jellyfin.mydomain.com`
- **🔄 Syncthing**: `https://syncthing.mydomain.com`

### 5.3 Check SSL Certificates
```bash
# Check if certificates are working
curl -I https://mydomain.com
curl -I https://jellyfin.mydomain.com

# Check ACME logs if issues
sudo journalctl -u acme-mydomain.com.service
```

## 📊 Step 6: Add More Services

Once the basics work, enable more services by editing your config:

```nix
services.selfhost = {
    # ... existing config ...
    
    # 🎬 Media Stack
    arr.enable = true;              # Sonarr, Radarr, etc.
    media.navidrome.enable = true;  # Music streaming
    
    # ☁️ Cloud Services  
    cloud.immich.enable = true;     # Photo management
    productivity.vaultwarden.enable = true;  # Password manager
    
    # 🔧 Utility Services
    utility.grafana.enable = true;  # Monitoring
    utility.stirling-pdf.enable = true;  # PDF tools
    
    # 📋 Productivity
    productivity.mealie.enable = true;     # Recipe manager
    productivity.paperless-ngx.enable = true;  # Document manager
};
```

## 🛠️ Advanced: Service Categories

You can enable entire categories at once:
```nix
services.selfhost = {
    enable = true;
    baseDomain = "mydomain.com";
    # ... other config ...
    
    # Enable full categories (all services in category)
    media.enable = true;         # All media services
    arr.enable = true;           # All arr services  
    productivity.enable = true;  # All productivity services
    
    # Disable specific services if needed
    productivity.firefly-iii.enable = false;  # Don't want finance app
    arr.lidarr.enable = false;                # Don't want music management
};
```

## 🔍 Troubleshooting

### SSL Certificate Issues
```bash
# Check ACME status
sudo systemctl status acme-mydomain.com.service
sudo journalctl -u acme-mydomain.com.service

# Force certificate renewal
sudo systemctl start acme-mydomain.com.service
```

### Service Not Accessible
1. Check if service is running: `sudo systemctl status servicename`
2. Check Caddy config: `sudo systemctl status caddy`
3. Check DNS propagation: `nslookup servicename.mydomain.com`
4. Check firewall: `sudo iptables -L`

### Port Conflicts
```bash
# Check what's using ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443
```

## 📱 Example Service URLs

With domain `mydomain.com`, you'll get:
- **🏠 Homepage**: `mydomain.com`
- **📺 Jellyfin**: `jellyfin.mydomain.com`
- **🎵 Navidrome**: `music.mydomain.com`
- **📸 Immich**: `photos.mydomain.com`
- **🔐 Vaultwarden**: `pass.mydomain.com`
- **📊 Grafana**: `grafana.mydomain.com`
- **📚 Calibre**: `books.mydomain.com`
- **🍳 Mealie**: `mealie.mydomain.com`
- **📄 Stirling PDF**: `pdf.mydomain.com`

## 🎉 Success!

Once everything is working, you'll have:
- ✅ **Professional homelab** with custom domain
- ✅ **Automatic SSL certificates** (no more browser warnings!)
- ✅ **Beautiful dashboard** showing all services
- ✅ **Security hardening** with Fail2Ban + Cloudflare
- ✅ **Easy service management** via Nix configuration

Your friends will be impressed! 🚀 