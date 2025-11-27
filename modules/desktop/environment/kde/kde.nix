# KDE Plasma 6 Desktop Environment
# Provides NixOS configuration for KDE Plasma 6
# Note: Display manager should be configured separately (e.g., den.aspects.sddm.wayland)
{
  den,
  ...
}:
{
  # Base KDE Plasma 6 desktop environment
  den.aspects.kde-desktop = {
    description = "KDE Plasma 6 desktop environment";

    nixos = { pkgs, lib, ... }: {
      # Enable KDE Plasma 6 desktop manager
      services.desktopManager.plasma6.enable = true;

      # Install KDE packages and utilities
      environment.systemPackages = with pkgs; [
        # KDE applications
        kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update service
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
        kdePackages.kclock # Clock app
        kdePackages.kcolorchooser # A small utility to select a color
        kdePackages.kolourpaint # Easy-to-use paint program
        kdePackages.ksystemlog # KDE SystemLog Application
        kdePackages.sddm-kcm # Configuration module for SDDM
        kdiff3 # Compares and merges 2 or 3 files or directories
        kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
        kdePackages.partitionmanager # Optional: Manage the disk devices, partitions and file systems on your computer
        # Non-KDE graphical packages
        hardinfo2 # System information and benchmarks for Linux systems
        vlc # Cross-platform media player and streaming server
        wayland-utils # Wayland utilities
        wl-clipboard # Command-line copy/paste utilities for Wayland
      ];
    };
  };

  # KDE with RDP support (X11-based remote desktop)
  # Note: RDP requires X11 instead of Wayland
  # Usage: den.aspects.kde-desktop.rdp
  den.aspects.kde-desktop.rdp = {
    description = "KDE Plasma 6 with RDP remote desktop support (X11)";

    includes = [ den.aspects.kde-desktop ];

    nixos = { pkgs, lib, ... }: {
      # Enable X11 for RDP support
      services.xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      # Configure xrdp for remote desktop access
      services.xrdp = {
        defaultWindowManager = "startplasma-x11";
        enable = true;
        openFirewall = true;
      };

      # Add X11 clipboard support
      environment.systemPackages = with pkgs; [
        xclip # Tool to access the X clipboard from a console application
      ];
    };
  };
}

