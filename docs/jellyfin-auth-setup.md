# Jellyfin Authentication Setup

## Current Status

SelfHostBlocks has **automatically configured** LDAP and SSO authentication for Jellyfin, but the **plugins must be manually installed** through the Jellyfin web UI.

Configuration files are already created:
- ✅ `/var/lib/jellyfin/plugins/configurations/LDAP-Auth.xml` - LDAP config
- ✅ `/var/lib/jellyfin/plugins/configurations/SSO-Auth.xml` - SSO/OIDC config
- ✅ Authelia OIDC client configured for Jellyfin

## Plugin Installation Steps

### 1. Access Jellyfin (Initial Setup)

First time accessing Jellyfin at `https://media.starcommand.live`:
- You'll go through the initial setup wizard
- Create a local admin account temporarily (you can disable it later)
- Complete the wizard

### 2. Install LDAP Authentication Plugin

1. **Go to Dashboard** (Admin → Dashboard)
2. **Plugins** → **Catalog**
3. **Find**: "LDAP Authentication"
   - Repository: Official Jellyfin Plugin Repository
4. **Click Install**
5. **Restart Jellyfin** when prompted
   ```bash
   ssh root@192.168.0.102 "systemctl restart jellyfin"
   ```

### 3. Install SSO Authentication Plugin

1. **Dashboard** → **Plugins** → **Repositories**
2. **Add Repository**:
   - Repository Name: `SSO Plugin`
   - Repository URL: `https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json`
3. **Save**
4. **Go to Catalog**
5. **Find**: "SSO Authentication"
6. **Click Install**
7. **Restart Jellyfin**
   ```bash
   ssh root@192.168.0.102 "systemctl restart jellyfin"
   ```

### 4. Verify Configuration

After installing both plugins and restarting:

1. **Dashboard** → **Plugins** → **My Plugins**
2. Verify both are installed:
   - LDAP Authentication
   - SSO Authentication
3. Click each plugin to check settings (should be auto-populated from config files)

### 5. Test LDAP Login

1. **Log out** of Jellyfin
2. **Login with LDAP credentials**:
   - Username: Your LLDAP username (e.g., `codywright`)
   - Password: Your LLDAP password
3. Should work if you're in the `jellyfin_user` group in LLDAP

### 6. Test SSO Login

1. **Log out**
2. Look for "Sign in with Authelia" button
3. Click it → redirects to Authelia
4. Login with Authelia → redirects back to Jellyfin

## User Groups (LLDAP)

To grant users access to Jellyfin:

**Regular Users:**
- Add to group: `jellyfin_user` in LLDAP
- Access: Can view and play media

**Administrators:**
- Add to groups: `jellyfin_user` AND `jellyfin_admin` in LLDAP
- Access: Full admin dashboard access

Access LLDAP at: `https://ldap.starcommand.live`

## Troubleshooting

### LDAP Not Working
- Check user is in `jellyfin_user` group in LLDAP
- Verify LLDAP is running: `systemctl status lldap`
- Check Jellyfin logs: `journalctl -u jellyfin -n 50`

### SSO Not Working
- Verify SSO plugin is installed and enabled
- Check Authelia is running: `systemctl status authelia-auth_starcommand_live`
- Verify OIDC client exists in Authelia for `jellyfin`

### Plugin Not Appearing
- Clear browser cache
- Try incognito/private window
- Verify plugin repository was added correctly
- Check Jellyfin version compatibility

## Security Notes

- SSO provides the best security (2FA via Authelia)
- LDAP is simpler but no 2FA unless configured in LLDAP
- You can disable the initial local admin account after setting up LDAP/SSO
- Regular Jellyfin logins bypass LDAP/SSO (keep disabled for security)

## Configuration Persistence

All plugin configurations are stored in `/var/lib/jellyfin/plugins/configurations/` which is:
- On persistent btrfs storage
- Survives reboots and rebuilds
- Backed up regularly

**You only need to install plugins once!** The configuration is already done by selfhostblocks.
