# Virtualization support with libvirt, QEMU/KVM, and virt-manager
{
  FTS,
  ...
}:
{
  FTS.system._.virtualization = {
    description = "KVM/QEMU virtualization with virt-manager for running Windows VMs";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # Enable libvirtd
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
            swtpm.enable = true; # TPM emulation for Windows 11
            # OVMF/UEFI is now available by default in NixOS
          };
        };

        # Enable spice USB redirection for passthrough
        virtualisation.spiceUSBRedirection.enable = true;

        # virt-manager and tools
        programs.virt-manager.enable = true;

        environment.systemPackages = with pkgs; [
          virt-viewer # SPICE/VNC viewer
          spice-gtk # SPICE client
          virtio-win # VirtIO drivers ISO for Windows
          swtpm # TPM emulator
        ];

        # dconf settings for virt-manager to work properly
        programs.dconf.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        # Set default connection for virt-manager
        dconf.settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = [ "qemu:///system" ];
            uris = [ "qemu:///system" ];
          };
        };
      };
  };
}
