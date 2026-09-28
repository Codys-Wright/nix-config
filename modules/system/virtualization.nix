# Virtualization support with libvirt, QEMU/KVM, and virt-manager
{
  fleet,
  den,
  inputs,
  ...
}:
let
  # Soft vars from the private nix-secrets flake (networking topology).
  domain = inputs.nix-secrets.networking.domains.selfhost;
  starcommandIp = inputs.nix-secrets.networking.hosts.starcommand.vpnIp;
in
{
  fleet.system._.virtualization = {
    description = "KVM/QEMU virtualization with virt-manager for running Windows VMs";

    includes = [
      (fleet.user._.groups [ "kvm" ])
      (fleet.user._.admin-groups [
        "libvirtd"
        "docker"
      ])
    ];

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

        # Docker daemon. The CI runner pushes images to the in-cluster
        # OCI registry on the 10G LAN (plain HTTP, LAN-only) — docker
        # refuses HTTP registries unless they're declared insecure.
        virtualisation.docker.enable = true;
        virtualisation.docker.daemon.settings.insecure-registries = [
          "registry.${domain}:30050"
        ];
        # Resolve the registry hostname to starcommand on the 10G LAN.
        networking.extraHosts = "${starcommandIp} registry.${domain}";

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
