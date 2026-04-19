{
  inputs,
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
      users.joshua = { };
      users.guest = { };
      users.bri = { };
      users.carter = { };
      aspect = "THEBATTLESHIP";
    };
  };

  den.aspects = {
    THEBATTLESHIP = {
      provides.to-users.includes = [ <fleet.desktop/home> ];

      includes = [
        <fleet/unfree>
        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet.system/agent-user>

        (fleet.desktop { default = "niri"; })
        (fleet.grub { uefi = true; })

        (fleet.hardware {
          nvidia = true;
          tailscale = true;
        })

        <fleet/gaming>
        <fleet/apps>
        # controller-split bundles polkit + sudoers + InputPlumber config +
        # the launch-as / steam-as equivalents. Replaces the three modules
        # that used to live here (launch-as, inputplumber, coop-launcher).
        <fleet.gaming/controller-split>

        (<fleet.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <fleet/kernel>
        <fleet.music/production>
        (fleet.selfhost._.samba-client { })
        <fleet.system/avahi>
        <fleet.system/virtualization>
        (fleet.deploy { ip = "100.74.250.99"; })

        # 10G network tuning for starcommand link
        # Static 10.10.10.10/24 — outside starcommand dnsmasq DHCP range (.100-.200),
        # gives Hermes/agent a stable address to SSH to from starcommand.
        (fleet.system._.network-10g {
          interface = "enp12s0";
          staticIp = "10.10.10.10/24";
        })
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          time.timeZone = "America/Los_Angeles";
          boot.loader.grub.configurationLimit = 15;

          # Prevent Intel I226-V (igc/enp11s0) PCIe link loss after extended uptime.
          # The I226-V has a hardware errata where the NIC self-initiates PCIe L1
          # substates independently of host ASPM, causing "PCIe link lost, device
          # now detached" after hours of uptime. pci=nommconf forces I/O port access
          # for PCI config space instead of MMIO, working around the link-drop bug.
          boot.kernelParams = [
            "pcie_aspm=off"
            "pci=nommconf"
          ];

          # Disable Energy Efficient Ethernet on the I226-V — EEE interaction with
          # the PCIe L1 substates errata is a common trigger for spontaneous link loss.
          systemd.services."igc-disable-eee" = {
            description = "Disable EEE on Intel I226-V (enp11s0) to prevent PCIe link drops";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            script = "${pkgs.ethtool}/sbin/ethtool --set-eee enp11s0 eee off || true";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
          };

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          programs.nh.enable = true;

          # NTFS games partition
          fileSystems."/run/media/GAMES" = {
            device = "/dev/nvme2n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
            ];
          };

          # NTFS audio production partition
          fileSystems."/run/media/AudioHaven" = {
            device = "/dev/nvme1n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
              "nofail"
            ];
          };

          # Mount starcommand storage over 10G NFS
          fileSystems."/mnt/starcommand" = {
            device = "10.10.10.1:/";
            fsType = "nfs";
            options = [
              "nfsvers=4.2"
              "rsize=1048576"
              "wsize=1048576"
              "_netdev"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.mount-timeout=30"
              "nofail"
              "soft"
              "timeo=150"
              "retrans=3"
            ];
          };

          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # SOPS secrets
          imports = [ inputs.sops-nix.nixosModules.default ];
          sops = {
            defaultSopsFile = ../../users/cody/secrets.yaml;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."cody/proton/privatekey" = {
              owner = "root";
              group = "root";
              mode = "0400";
            };
          };
        };
    };
  };
}
