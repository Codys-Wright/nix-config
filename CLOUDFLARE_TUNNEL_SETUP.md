# 🌐 Cloudflare Tunnel Setup Guide

## 🎯 **Why Cloudflare Tunnels Are Better:**
- ✅ **No port forwarding** required
- ✅ **More secure** (no open ports on your router)
- ✅ **DDoS protection** from Cloudflare
- ✅ **Hides your real IP** address
- ✅ **Works behind CGNAT** or restrictive networks
- ✅ **Built-in analytics** and monitoring

## 🚀 **Step 1: Create Tunnel in Cloudflare Dashboard**

### 1.1 Access Zero Trust Dashboard
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **"Zero Trust"** in the left sidebar
3. Go to **Networks** → **Tunnels**

### 1.2 Create New Tunnel
1. Click **"Create a tunnel"**
2. Choose **"Cloudflared"** connector
3. Name: `starcommand-homelab`
4. Click **"Save tunnel"**

### 1.3 Get Tunnel Credentials
1. **Copy the tunnel token** (long string starting with `eyJ...`)
2. **Copy the tunnel ID** (shorter UUID like `12345678-1234-1234-1234-123456789abc`)

## 🔑 **Step 2: Create Credentials File**

### 2.1 Create Tunnel Credentials File
The tunnel token contains JSON credentials. Extract them:

```bash
# Method 1: Use the token directly (easier)
sudo mkdir -p /etc/nixos/secrets

# Decode the tunnel token to get credentials JSON
echo "YOUR_TUNNEL_TOKEN_HERE" | base64 -d | sudo tee /etc/nixos/secrets/cloudflare-tunnel.json

# Set proper permissions
sudo chmod 600 /etc/nixos/secrets/cloudflare-tunnel.json
```

### 2.2 Alternative: Manual Credentials File
If the above doesn't work, create manually:
```bash
sudo tee /etc/nixos/secrets/cloudflare-tunnel.json << 'EOF'
{
  "AccountTag": "your-account-id",
  "TunnelSecret": "your-tunnel-secret", 
  "TunnelID": "your-tunnel-id"
}
EOF
sudo chmod 600 /etc/nixos/secrets/cloudflare-tunnel.json
```

## ⚙️ **Step 3: Update NixOS Configuration**

Your configuration is already updated! But here's what it does:

```nix
services.cloudflared = {
    enable = true;
    tunnels = {
        "starcommand-homelab" = {
            credentialsFile = "/etc/nixos/secrets/cloudflare-tunnel.json";
            default = "http_status:404";  # Default response for unmapped domains
            
            ingress = {
                # Route domains to local services
                "starcommand.live" = "http://127.0.0.1:3000";              # Homepage
                "jellyfin.starcommand.live" = "http://127.0.0.1:8096";     # Jellyfin
                "syncthing.starcommand.live" = "http://127.0.0.1:8384";    # Syncthing
            };
        };
    };
};
```

## 🌐 **Step 4: Configure DNS in Cloudflare**

### 4.1 Add CNAME Records
In your Cloudflare DNS settings for `starcommand.live`, add:

```
Type: CNAME
Name: @
Target: your-tunnel-id.cfargotunnel.com
Proxy: Enabled (orange cloud)

Type: CNAME  
Name: *
Target: your-tunnel-id.cfargotunnel.com
Proxy: Enabled (orange cloud)
```

**Note:** Replace `your-tunnel-id` with the actual tunnel ID from step 1.3

### 4.2 Remove Old A Records
- Delete any existing A records pointing to your public IP
- The CNAME records will handle all traffic through the tunnel

## 🚀 **Step 5: Deploy and Test**

### 5.1 Deploy Configuration
```bash
sudo nixos-rebuild switch
```

### 5.2 Check Tunnel Status
```bash
# Check if cloudflared service is running
sudo systemctl status cloudflared-tunnel-starcommand-homelab.service

# Check tunnel logs
sudo journalctl -u cloudflared-tunnel-starcommand-homelab.service -f
```

### 5.3 Test Your Services
After deployment, these should work:
- **🏠 Homepage**: `https://starcommand.live`
- **📺 Jellyfin**: `https://jellyfin.starcommand.live`
- **🔄 Syncthing**: `https://syncthing.starcommand.live`

## 🔧 **Step 6: Add More Services**

When you enable more services, just add them to the ingress rules:

```nix
ingress = {
    "starcommand.live" = "http://127.0.0.1:3000";
    "jellyfin.starcommand.live" = "http://127.0.0.1:8096";
    "syncthing.starcommand.live" = "http://127.0.0.1:8384";
    
    # Add new services here
    "photos.starcommand.live" = "http://127.0.0.1:3001";     # Immich
    "music.starcommand.live" = "http://127.0.0.1:4533";      # Navidrome
    "grafana.starcommand.live" = "http://127.0.0.1:3030";    # Grafana
    "pass.starcommand.live" = "http://127.0.0.1:8222";       # Vaultwarden
};
```

## 🛡️ **Security Benefits**

### What You Get:
- **🚫 No open ports** on your router/firewall
- **🌍 DDoS protection** from Cloudflare's global network
- **🕵️ IP masking** - your real IP is hidden
- **📊 Traffic analytics** in Cloudflare dashboard
- **🔒 Automatic SSL** termination at Cloudflare edge

### Network Architecture:
```
Internet → Cloudflare → Encrypted Tunnel → Your NixOS Machine
         (DDoS Protection)  (No open ports)   (Local services)
```

## 🔍 **Troubleshooting**

### Tunnel Not Connecting:
```bash
# Check credentials file
sudo cat /etc/nixos/secrets/cloudflare-tunnel.json

# Check service status
sudo systemctl status cloudflared-tunnel-starcommand-homelab.service

# Check logs for errors
sudo journalctl -u cloudflared-tunnel-starcommand-homelab.service --since "10 minutes ago"
```

### Services Not Accessible:
1. **Check DNS propagation**: `nslookup starcommand.live`
2. **Verify tunnel status** in Cloudflare dashboard
3. **Check local services** are running: `sudo systemctl status jellyfin`
4. **Test local access**: `curl http://127.0.0.1:8096`

### Common Issues:
- **Wrong tunnel ID** in DNS records
- **Incorrect credentials file** format
- **Services not listening** on specified ports
- **Firewall blocking** local connections

## 🎉 **Success!**

Once everything is working, you'll have:
- ✅ **Professional homelab** accessible from anywhere
- ✅ **Enterprise-grade security** via Cloudflare
- ✅ **No router configuration** needed
- ✅ **Automatic SSL certificates**
- ✅ **DDoS protection** included
- ✅ **Hidden IP address** for privacy

Your friends will think you work for a cloud company! 🚀

## 📝 **Next Steps**

1. **Create the tunnel** in Cloudflare dashboard
2. **Extract credentials** to `/etc/nixos/secrets/cloudflare-tunnel.json`
3. **Update DNS records** to point to tunnel
4. **Deploy with** `sudo nixos-rebuild switch`
5. **Test your services** at `https://starcommand.live`

The tunnel will automatically start on boot and reconnect if disconnected. Your homelab is now enterprise-grade! 💪 