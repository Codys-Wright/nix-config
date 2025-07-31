# Nix-Config: Modern NixOS Configuration

A modern, modular NixOS configuration system built with best practices and cutting-edge tools.

## 🎯 Project Goals

### ✅ Completed
- [x] **Remote Deployment with Nixos-Anywhere + Deploy-RS**
  - Initial installation with nixos-anywhere
  - Safe configuration updates with deploy-rs
  - Automatic rollback protection
  - Multi-node deployment support

### 🚧 In Progress
- [ ] **Declarative VM Machine Setup**
  - Easy testing environment creation
  - Reproducible VM configurations
  - Automated VM provisioning

### 📋 Planned Features

#### **Core Infrastructure**
- [ ] **Multi-Host Multi-User Config**
  - Centralized user management
  - Host-specific configurations
  - Role-based access control

- [ ] **Declarative Disk Formatting with Disko**
  - BTRFS filesystem with subvolumes
  - Impermanence for stateless systems
  - LUKS encryption for security
  - Automated disk partitioning

- [ ] **Sops-Secrets Management**
  - Encrypted secrets storage
  - Age key integration
  - Secure secret distribution

#### **Development & Quality**
- [ ] **Formatting with Alejandro**
  - Consistent code formatting
  - Automated formatting checks
  - Pre-commit hooks

- [ ] **"Phoenix" Flake Manager**
  - Automated flake updates
  - Dependency management
  - Version pinning

- [ ] **Opt-In Unstable Channel**
  - Package-level unstable channel selection
  - Stable defaults with opt-in bleeding edge
  - Granular control over package versions

## 🛠️ Current Features

### **Deployment System**
```bash
# Set target
just target <ip> <password>

# Initial installation
just nixos-anywhere

# Configuration updates
just deploy

# Evaluate configuration
just eval <config>

# Connect to target
just connect
```

### **Configuration Structure**
- **Stylix theming** with custom wallpaper
- **KDE Plasma** desktop environment
- **Backup user** for emergency access
- **SSH key management** for secure access

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone git@github.com:Codys-Wright/dotfiles.git
   cd dotfiles
   git checkout nix-starter
   ```

2. **Set up your target:**
   ```bash
   just target 192.168.1.100 mypassword
   ```

3. **Deploy:**
   ```bash
   just deploy
   ```

## 📁 Repository Structure

```
nix-config/
├── configuration.nix      # Main NixOS configuration
├── flake.nix             # Flake definition with inputs
├── justfile              # Deployment commands
├── disk-config.nix       # Disko disk configuration
└── Windows-11-PRO.png   # Wallpaper for stylix
```

## 🔧 Development Workflow

### **Branches**
- **`nix-minimal`**: Stable deployment configuration
- **`nix-starter`**: Development and experimentation

### **Adding New Features**
1. Create feature branch from `nix-starter`
2. Implement and test changes
3. Merge back to `nix-starter`
4. Deploy and validate
5. Merge to `nix-minimal` when stable

## 🎨 Theming

This configuration uses **Stylix** for consistent theming:
- **Theme**: Gruvbox Dark Medium
- **Cursor**: Bibata Modern Ice
- **Fonts**: JetBrains Mono Nerd Font
- **Wallpaper**: Custom Windows 11 Pro

## 🔐 Security Features

- **SSH key authentication** for all deployments
- **Backup user** for emergency access
- **LUKS encryption** (planned)
- **Sops secrets** (planned)

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/)
- [Deploy-RS Documentation](https://github.com/serokell/deploy-rs)
- [Stylix Documentation](https://github.com/danth/stylix)
- [Disko Documentation](https://github.com/nix-community/disko)

## 🤝 Contributing

This is a personal configuration, but suggestions and improvements are welcome!

## 📄 License

MIT License - see LICENSE file for details.
